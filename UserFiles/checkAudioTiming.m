figure
tb = (0:length(Butt.data(:,1))-1)/Butt.info.SamplingRateHz;
plot(tb, Butt.data(:,4))
hold on
plot(tb, Butt.data(:,1))
ts = (0:length(Sing.data(:,1))-1)/Sing.info.SamplingRateHz;
plot(ts, Sing.data(:,1)/10000)
legend('Tone', 'stim button', 'stimulation')

%%
startInd = 2.2e5; %start of two stim trains
midInd = 2.8e5; % between the 2 trains
endInd = 3.3e5; % after the 2 trains

tone = Butt.data(:,4);
toneInd(1) = find(diff(tone(startInd:endInd))==-1,1);
toneInd(2) = find(diff(tone(startInd:endInd))==1,1);
toneLength = (toneInd(2)-toneInd(1))/Butt.info.SamplingRateHz; % in seconds

clearvars toneInd
toneInds = find(diff(tone(startInd:endInd))==1)+startInd;
stimInd(1) = find(diff(Sing.data(startInd:midInd,1))>1,1)+startInd;
stimInd(2) = find(diff(Sing.data(midInd:endInd,1))>1,1)+midInd;

stimInd(1)-toneInds(2)
stimInd(2)-toneInds(4)
