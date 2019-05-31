%% StimParam_2AFC_run
% Written: 5/7/18
% J Cronin

%% This script should be used with the TDT Project: StimParam_2AFC
%% This code allows the user to read from a set of stimulation parameters and deliver pairs in 2AFC trials
% This code controls most of the TDT functioning and allows the user to
% respond with their 2AFC answer via the keyboard and psychtoolbox

% This MATLAB script will also save the stim parameters and the responses
% from the TDT and print figures right afterwards of the staircase results
% and the psychometric curve using Geoff Boynton's code.

clc; clearvars; close all
% dbstop if error

%% Set experimental parameters
numSets = 5; % number of sets of the unique stim parameter trials that you want to do
% Note that this number of sets will actually be multiplied by two because
% you'll present each 2AFC pair in both orders (e.g., Train A then Train B
% and then Train B then Train A)

ISI = 2000; % ms; this is the time between the end of the first stim train and the start of the second stim train
showFixationTime = 500; % ms; this is the time after the end of the first stim train to wait to show the fixation cross again

% Read in from the file that you want to use for stimulation parameters
% columns are:
% Train a ------
% 1: amp
% 2: PW
% 3: PF
% 4: TD
% 5: number of pulses
% Train b ------
% 6: amp
% 7: PW
% 8: PF
% 9: TD
% 10: number of pulses

paramsReadIn = xlsread('StimParameters_for2AFC.xlsx', 1, 'B3:I11');
% paramsReadIn = xlsread('StimParameters_for2AFC.xlsx', 3, 'B3:I11');
labels = repelem([1 2 3]',3); % Need to change this if I update the number of trials
% Labels are: 1-Amp, 2-PW, 3-PF base change
whichQuestion = 'Intensity'; % This can equal Intensity or SameDiff and controls which question is displayed
% whichQuestion = 'SameDiff';

%% Set up all of the 2AFC trial parameters
params = [paramsReadIn; paramsReadIn(:,5:8), paramsReadIn(:,1:4)]; % this doubles the number of trials so that each stim pair is presented in both orders
labels = [labels; labels];

paramsTest = [];
labelsTest = [];
for i=1:numSets % randomize the params and concatenate to the paramsTest matrix
    % Randomize the order that we present these in
    temp = randperm(size(paramsReadIn,1)*2);
    params = params(temp,:);
    labels = labels(temp);
    paramsTest = [paramsTest; params];
    labelsTest = [labelsTest; labels];
end

% Add an empty column to the paramsTest matrix to add in the number of
% pulses in the train for each train
numTrials = size(paramsTest,1); % this is the total number of trials
paramsTest = [paramsTest(:,1:4), NaN(numTrials,1), paramsTest(:,5:8), NaN(numTrials,1)];


% % REMOVE THIS AFTER TESTING
% paramsTest = paramsTest(1:2,:);
% numTrials = size(paramsTest,1); % this is the total number of trials

%% Open connection with TDT and begin program
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local'); %initiates a connection with an OpenWorkbench server. The connection adds a client to the server
pause(1)

while DA.CheckServerConnection ~= 1
    disp('OpenWorkbench is not connected to server. Trying again...')
    close all
    DA = actxcontrol('TDevAcc.X');
    DA.ConnectServer('Local');
    pause(1) % seconds
end
clc
disp('Connected to server')
disp('Remember: if you want to end recording early, end TDT recording and Matlab will automatically save param sweep vars')

% If OpenWorkbench is not in Record mode, then this will set it to record
if DA.GetSysMode ~= 3
    DA.SetSysMode(3);
    while DA.GetSysMode ~= 3
        pause(.1)
    end
end

tank = DA.GetTankName;
% Read the loaded circuit's name so that we can save this
circuitLoaded = DA.GetDeviceRCO('RZ5D');

%% Initizlize values
DA.SetTargetVal('RZ5D.numTrials', numTrials);
DA.SetTargetVal('RZ5D.ISI', ISI);
pause(0.1)
ISI_samps = DA.GetTargetVal('RZ5D.ISI(samp)'); % get the number of samples for the ISI from Matlab and the converted number of seconds
ISI_actual = DA.GetTargetVal('RZ5D.cISI(ms)');

% Charge delivered
trainA_chargeSet = zeros(numTrials,1);
trainB_chargeSet = zeros(numTrials,1);
trainA_chargeDelivered = zeros(numTrials,1);
trainB_chargeDelivered = zeros(numTrials,1);
percentChangeCharge = zeros(numTrials,1);
paramsTest_actual = zeros(size(paramsTest));

% Responses are stored as 0: right arrow press (B and different), and 1:
% left arrow press (A and same)
response = zeros(numTrials, 1);

% If you're using the Intensity question then you also need to save whether
% or not each response is correct in a results vector
if strcmp(whichQuestion, 'Intensity')
    results = zeros(numTrials, 1);
end

%% Initialize psychtoolbox
sca; % close any open psychtoolbox screens

PsychDefaultSetup(2);
screenNumber = max(Screen('Screens'));

% Define colors
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);

% % Probably need to remove this line!!!!!!!!!!!!!!!!!
% Screen('Preference', 'SkipSyncTests', 0);

% Open window screen and get size/coordinates
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
[xCenter, yCenter] = RectCenter(windowRect);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Setup the text type for the window
Screen('TextFont', window, 'Ariel');

% The avaliable keys to press
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');

%% Before proceeding make sure that the system is armed:
if DA.GetTargetVal('RZ5D.IsArmed') == 0
    disp('System is not armed');
end

while DA.GetTargetVal('RZ5D.IsArmed')~=1
    % waiting until the system is armed
end
disp('System armed');

%% Loop through all of the trials
% Turn the ready indicator on and wait for the start button to be pressed
% for the first time
DA.SetTargetVal('RZ5D.readyIndicator', 1); % set ready indicator to 0 for computation
while DA.GetTargetVal('RZ5D.StartButton')~=1
    % waiting...
end
disp('Starting experiment using PsychToolbox...')

for i=1:numTrials
    % Start the psychtoolbox screen
    vbl = displayFixationCross(window, white, xCenter, yCenter);
    
    % Retreive the maximum priority number
    topPriorityLevel = MaxPriority(window);
    
    % Set the variables that change on each loop
    % 1: amp
    % 2: PW
    % 3: PF
    % 4: TD
    % 5: number of pulses
    % 6: amp
    % 7: PW
    % 8: PF
    % 9: TD
    % 10: number of pulses
    DA.SetTargetVal('RZ5D.AMPa', paramsTest(i,1));
    DA.SetTargetVal('RZ5D.PWa', paramsTest(i,2));
    DA.SetTargetVal('RZ5D.PFa', paramsTest(i,3));
    DA.SetTargetVal('RZ5D.PTDa', paramsTest(i,4));
    DA.SetTargetVal('RZ5D.AMPb', paramsTest(i,6));
    DA.SetTargetVal('RZ5D.PWb', paramsTest(i,7));
    DA.SetTargetVal('RZ5D.PFb', paramsTest(i,8));
    DA.SetTargetVal('RZ5D.PTDb', paramsTest(i,9));
    
    % Pause to allow TDT to set the above train variables and compute the
    % actual variables, and give the subject a total of a 2 sec break
    % between trials (1.5s here and 0.5s below when the response is
    % displayed on the screen)
    pause(1.5); 
    
    % Get the TDT set variables which will actually be used
    paramsTest_actual(i,[1 6]) = paramsTest(i,[1 6]); % Amps set and used by TDT are the same
    paramsTest_actual(i,2) = DA.GetTargetVal('RZ5D.cPWa(us)');
    paramsTest_actual(i,3) = DA.GetTargetVal('RZ5D.cPFa');
    paramsTest_actual(i,4) = DA.GetTargetVal('RZ5D.cPTDa(ms)');
    paramsTest_actual(i,5) = DA.GetTargetVal('RZ5D.numPulses_a');
    
    paramsTest_actual(i,7) = DA.GetTargetVal('RZ5D.cPWb(us)');
    paramsTest_actual(i,8) = DA.GetTargetVal('RZ5D.cPFb');
    paramsTest_actual(i,9) = DA.GetTargetVal('RZ5D.cPTDb(ms)');
    paramsTest_actual(i,10) = DA.GetTargetVal('RZ5D.numPulses_b');
    
    % Set the number of pulses in paramsTest to the actual number of pulses
    % above (TDT sampling rate doesn't change this)
    paramsTest(i,5) = paramsTest_actual(i,5);
    paramsTest(i,10) = paramsTest_actual(i,10);
    
    % Compute the total charge delivered for the two trains (based on input
    % values)
    trainA_chargeSet(i) = paramsTest(i,1)/1000*paramsTest(i,2)*paramsTest(i,5); % in Amp*us
    trainB_chargeSet(i) = paramsTest(i,6)/1000*paramsTest(i,7)*paramsTest(i,10);
    
    % Compute the total charge delivered for the two trains (based on TDT
    % converted values - the values that are based on the TDT's sampling rate)
    trainA_chargeDelivered(i) = paramsTest_actual(i,1)/1000000*paramsTest_actual(i,2)*paramsTest_actual(i,5);
    trainB_chargeDelivered(i) = paramsTest_actual(i,6)/1000000*paramsTest_actual(i,7)*paramsTest_actual(i,10);
    percentChangeCharge(i) = abs(trainA_chargeDelivered(i)-trainB_chargeDelivered(i))/trainA_chargeDelivered(i)*100;
    DA.SetTargetVal('RZ5D.trainA_chargeDelivered', trainA_chargeDelivered(i));
    DA.SetTargetVal('RZ5D.trainB_chargeDelivered', trainB_chargeDelivered(i));
    
    vbl = displayTrainIdentity(window, white, xCenter, yCenter, 'A');
    % start a stimulation train
    DA.SetTargetVal('RZ5D.StimButton', 1);
    pause(0.01) % pausing to make sure the stim is triggered in the TDT
    DA.SetTargetVal('RZ5D.StimButton', 0);
    
    DA.SetTargetVal('RZ5D.readyIndicator', 0); % set ready indicator to 0 for computation
    
    % Pause while stim is delivered before asking for a subject response
    % In total, while delivering the two stim trains and showing the A/B
    % visual and playing the audio we will pause for a total of: % Pause
    % length should equal the sum of the 2 PTDs + the time between the
    % trains (ISI) + the 1 second delay between the stim button activation
    % and the start of the first train (which allows the initial audio to
    % play before the fist stim train) + another delay equal to the
    % showFixationTime to keep 'B' on the screen before asking the question
    pause((1000 + paramsTest_actual(i,4) + showFixationTime)/1000)
    vbl = displayFixationCross(window, white, xCenter, yCenter);
    pause((ISI - 1000 - showFixationTime)/1000)
    vbl = displayTrainIdentity(window, white, xCenter, yCenter, 'B');
    pause((1000+paramsTest_actual(i,9)+showFixationTime)/1000) 
    DA.SetTargetVal('RZ5D.readyForAnswerIndicator', 1); % set the indicator for answering to on, so experimenter knows that stim (or catch) has been delivered and system is waiting for response
    
    % Check that the TDT system is still in record mode, if not
    % then end the experiment early and save the variables - will do
    % this before any while loops
    if DA.GetSysMode ~= 3
        disp('TDT Recording was ended early, ending and saving Matlab script now')
        Save_Param2AFCVariables
        sca; % close the psych toolbox screen if it was open
        return
    end
    
    % Get answer from subject
    if strcmp(whichQuestion, 'Intensity')
        vbl = displayIntensityQuestion(window, white, screenXpixels, screenYpixels);
    elseif strcmp(whichQuestion, 'SameDiff')
        vbl = displaySameDiffQuestion(window, white, screenXpixels, screenYpixels);
    else
        error('whichQuestion variable is not equal to Intensity or SameDiff')
    end
    
    exitKeyboardLoop = 0;
    while exitKeyboardLoop == 0
        % Check the keyboard
        % waiting for left/right arrow to be
        % pressed, and also checking that the system is still in record
        % mode. If the TDT has been taken out of record mode, then we'll end
        % the experiment early and save the variables:
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
            % do something to save the trial as is, or double-check that you want
            % to stop
            exitKeyboardLoop = 1;
            sca;
            Save_Param2AFCVariables
            return
        elseif keyCode(leftKey) % subject indicated left-side answer
            keyboardResp = 1;
            exitKeyboardLoop = 1;
            if strcmp(whichQuestion, 'Intensity')
                vbl = displayIntensityQuestion(window, white, screenXpixels, screenYpixels, 'left'); % 'left' will color code the left-side answer
            elseif strcmp(whichQuestion, 'SameDiff')
                vbl = displaySameDiffQuestion(window, white, screenXpixels, screenYpixels, 'left');
            else
                error('whichQuestion variable is not equal to Intensity or SameDiff')
            end
            
        elseif keyCode(rightKey) % subject indicated right-side answer
            keyboardResp = 0;
            exitKeyboardLoop = 1;
            if strcmp(whichQuestion, 'Intensity')
                vbl = displayIntensityQuestion(window, white, screenXpixels, screenYpixels, 'right'); % 'right' will color code the right-side answer
            elseif strcmp(whichQuestion, 'SameDiff')
                vbl = displaySameDiffQuestion(window, white, screenXpixels, screenYpixels, 'right');
            else
                error('whichQuestion variable is not equal to Intensity or SameDiff')
            end

        end
        clear keyCode keyIsDown secs
        if DA.GetSysMode ~= 3
            disp('TDT Recording was ended early, ending and saving Matlab script now')
            Save_Param2AFCVariables
            sca; % close the psych toolbox screen if it was open
            return
        end
    end
    
    if isequal(keyboardResp,1)
        resp = 'left';
        DA.SetTargetVal('RZ5D.leftIndicator', 1); % set the indicator to 1
    elseif isequal(keyboardResp,0)
        resp = 'right';
        DA.SetTargetVal('RZ5D.rightIndicator', 1); % set the indicator to 1
    else
        warning('Do not know whether subject indicated left or right arrow')
    end
    
    % Turn off the ready to answer indicator, since an answer was just
    % given:
    DA.SetTargetVal('RZ5D.readyForAnswerIndicator', 0);
    
    % Compare the answer given to the correct answer, to determine if
    % correct or incorrect
    if strcmp(resp,'left') % Left response is either Same (SameDiff question) or A (Intensity question)
        response(i) = 1;
        if strcmp(whichQuestion, 'Intensity')
            displayTrial = ['Trial #', num2str(i), ': A'];
        elseif strcmp(whichQuestion, 'Intensity')
            displayTrial = ['Trial #', num2str(i), ': Same'];
        else
            displayTrial = ['Trial #', num2str(i), ': '];
        end
    elseif strcmp(resp,'right') % Right response is either Diff (SameDiff question) or B (Intensity question)
        response(i) = 0;
        if strcmp(whichQuestion, 'Intensity')
            displayTrial = ['Trial #', num2str(i), ': B'];
        elseif strcmp(whichQuestion, 'Intensity')
            displayTrial = ['Trial #', num2str(i), ': Different'];
        else
            displayTrial = ['Trial #', num2str(i), ': '];
        end
    else
        warning('Something went wrong in going thru yes/no steps')
        return
    end
    if strcmp(whichQuestion, 'SameDiff')
        if response(i)==1
            displayTrial = [displayTrial, 'Same'];
        elseif response(i)==0
            displayTrial = [displayTrial, 'Different'];
        end
    end
        
    if strcmp(whichQuestion, 'Intensity') % then we also need to compare the responses to what should be the correct answer
        if response(i)==1 && trainA_chargeDelivered(i)>=trainB_chargeDelivered(i)
            results(i)=1;
            displayTrial = [displayTrial, ', Correct'];
        elseif response(i)==0 && trainB_chargeDelivered(i)>trainA_chargeDelivered(i)
            results(i)=1;
            displayTrial = [displayTrial, ', Correct'];
        else 
            results(i)=0;
            displayTrial = [displayTrial, ', Incorrect'];
        end
    end
    
    % Turn the ready indicator back on and the response indicators off
    DA.SetTargetVal('RZ5D.readyIndicator', 1); % set the indicator to 1 (LED on) so experimenter knows that the Stim button can be pressed again

    % Display response in command window
    disp([displayTrial, sprintf(', Charge = %.0f vs. %.0f A*us', trainA_chargeDelivered(i), trainB_chargeDelivered(i))])
    clearvars displayTrial
    
    % Now that subject has indicated yes/no with a keyboard press,
    % pause for a moment to leave the color-coding of the yes/no answer
    % and then switch back to the fixation cross and turn indicator LEDs on
    % the TDT controller off
    pause(0.5)
    DA.SetTargetVal('RZ5D.leftIndicator', 0); % set the indicator back to 0
    DA.SetTargetVal('RZ5D.rightIndicator', 0); % set the indicator back to 0
end

%% Turn all indicators off after trials are over
DA.SetTargetVal('RZ5D.noIndicator', 0);
DA.SetTargetVal('RZ5D.yesIndicator', 0);
DA.SetTargetVal('RZ5D.readyForAnswerIndicator', 0);
DA.SetTargetVal('RZ5D.readyIndicator', 0);

sca; % close any open psychtoolbox screens

%% When run is ended, close the connection
% Disarm stim:
DA.SetTargetVal('RZ5D.ArmSystem', 0);

% Close ActiveX connection:
DA.CloseConnection
if DA.CheckServerConnection == 0
    disp('Server was disconnected');
end

%% Plot results if we ran a intensity question
% For percent charge change, convert anything that's very close to 0 to 0,
% so that unique function works below
percentChangeCharge(abs(percentChangeCharge)<1e-5)=0;
% Also round percent change charge to the nearest integer, to bin close
% values together for the sake of the plotting below
percentChangeCharge_rounded = round(percentChangeCharge);

if strcmp(whichQuestion, 'Intensity')
    percentChangeCharge_Labeled = cell(1,3);
    results_Labeled = cell(1,3);
    percentChanges = cell(1,3);
    pCorrect = cell(1,3);
    sd = cell(1,3);
    
    for i=1:3 % loop through the three different parameters that were changed
        percentChangeCharge_Labeled{i} = percentChangeCharge_rounded(labelsTest==i);
        results_Labeled{i} = results(labelsTest==i);
        percentChanges{i} = unique(percentChangeCharge_Labeled{i});
        nCorrect = zeros(1,length(percentChanges{i}));
        nTrials = zeros(1,length(percentChanges{i}));
        
        for ii=1:length(percentChanges{i})
            id = percentChangeCharge_Labeled{i} == percentChanges{i}(ii);
            nTrials(ii) = sum(id);
            nCorrect(ii) = sum(results_Labeled{i}(id)==1);
        end
        pCorrect{i} = nCorrect./nTrials;
        sd{i} = pCorrect{i}.*(1-pCorrect{i})./sqrt(nTrials);  %pq/sqrt(n)
    end
    
    min_percentChange = min(percentChangeCharge_rounded);
    max_percentChange = max(percentChangeCharge_rounded);
    
    figure
    for i=1:3
        subplot(1,3,i)
        errorbar((percentChanges{i}),100*pCorrect{i},100*sd{i},'bo','MarkerFaceColor','b');
        ylim([0 100]);
        xlim([min_percentChange-5, max_percentChange+5]);
    end
    subplot(1,3,1)
    ylabel('Proportion correct')
    title('Amp')
    subplot(1,3,2)
    title('PW')
    xlabel('Percent change in charge')
    subplot(1,3,3)
    title('PF')
end

%% Plot results - Same/Diff
if strcmp(whichQuestion, 'SameDiff')
    percentChangeCharge_Labeled = cell(1,3);
    percentChanges = cell(1,3);
    responseSameDiff_Labeled = cell(1,3);
    pSame = cell(1,3);
    
    for i=1:3 % loop through the three different parameters that were changed
        percentChangeCharge_Labeled{i} = percentChangeCharge_rounded(labelsTest==i);
        responseSameDiff_Labeled{i} = response(labelsTest==i);
        percentChanges{i} = unique(percentChangeCharge_Labeled{i});
        nSame = zeros(1,length(percentChanges{i}));
        nTrials = zeros(1,length(percentChanges{i}));
        
        for ii=1:length(percentChanges{i})
            id = percentChangeCharge_Labeled{i} == percentChanges{i}(ii);
            nTrials(ii) = sum(id);
            nSame(ii) = sum(responseSameDiff_Labeled{i}(id)==1);
        end
        pSame{i} = nSame./nTrials;
    end

    figure
    for i=1:3
        subplot(1,3,i)
        bar(pSame{i})
        set(gca,'XTick',1:length(pSame{i}),'XTickLabel',num2str(percentChanges{i}))
    end
    subplot(1,3,1)
    ylabel('Proportion that felt the Same')
    title('Amp')
    subplot(1,3,2)
    title('PW')
    xlabel('Percent change in charge')
    subplot(1,3,3)
    title('PF')
end

%% Save
Save_Param2AFCVariables
figure(1), close(gcf)

