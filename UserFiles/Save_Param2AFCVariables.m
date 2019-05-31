% Clear variables we don't want to save
% clearvars i ind startingPulseAmp 
clearvars black escapeKey exitKeyboardLoop keyCode keyIsDown leftKey...
    rightKey screenNumber screenXpixels screenYpixels secs topPriorityLevel...
    vbl white window windowRect xCenter yCenter DA i resp displayTrial ans

blockName = getLatestFile(tank);
save([tank, '\', blockName, '_Matlab']);





