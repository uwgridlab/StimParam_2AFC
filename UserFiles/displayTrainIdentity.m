function [ vbl ] = displayTrainIdentity(window, white, xCenter, yCenter, identity)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

Screen('TextSize', window, 200);
DrawFormattedText(window, identity, 'center', 'center', white);

% Flip to the screen
vbl = Screen('Flip', window);
end

