load('C:\Subjects\TEST\Matlab\StimParam2AFC-10.mat')

%%
figure
% subplot(2,1,1)
plot(Sing.data(:,1))

% subplot(2,1,2)
% plot(Stim.data(:,1))

%%
delta(1) = cursor_info(7).DataIndex - cursor_info(8).DataIndex;
delta(2) = cursor_info(5).DataIndex - cursor_info(6).DataIndex;
delta(3) = cursor_info(3).DataIndex - cursor_info(4).DataIndex;
delta(4) = cursor_info(1).DataIndex - cursor_info(2).DataIndex;

t(1) = delta(1)/Sing.info.SamplingRateHz;
t(2) = delta(2)/Sing.info.SamplingRateHz;
t(3) = delta(3)/Sing.info.SamplingRateHz;
t(4) = delta(4)/Sing.info.SamplingRateHz;

%%
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
for i=6:9
IPI(i-5) = (paramsTest_actual(i,4)/paramsTest_actual(i,5)*1000-2*paramsTest_actual(i,2))*1e-6*Sing.info.SamplingRateHz;
end

delta-IPI
range(delta-IPI)

