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


%% Enter what you want to test here and below
vbl = displayIntensityQuestion(window, white, screenXpixels, screenYpixels);



%%
exitKeyboardLoop = 0;
while exitKeyboardLoop == 0
    % Check the keyboard
    % waiting for a yes/no button (i.e., left/right arrow) to be
    % pressed, and also checking that the system is still in record
    % mode. If the TDT has been taken out of record mode, then we'll end
    % the experiment early and save the variables:
    [keyIsDown, secs, keyCode] = KbCheck;
    if keyCode(escapeKey)
        % do something to save the trial as is, or double-check that you want
        % to stop
        exitKeyboardLoop = 1;
        sca;
        return
    elseif keyCode(leftKey) % subject indicated 'yes'
        keyboardResp = 1;
        exitKeyboardLoop = 1;
        vbl = displayIntensityQuestion(window, white, screenXpixels, screenYpixels, 'left'); % 'left' will color code the left-side answer
        pause(0.5)
        sca;
        return
    elseif keyCode(rightKey) % subject indicated 'no'
        keyboardResp = 0;
        exitKeyboardLoop = 1;
        vbl = displayIntensityQuestion(window, white, screenXpixels, screenYpixels, 'right'); % 'right' will color code the right-side answer
        pause(0.5)
        sca;
        return
    end
    
end