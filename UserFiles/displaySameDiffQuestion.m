function [ vbl ] = displaySameDiffQuestion(window, white, screenXpixels, screenYpixels, answer)
%This will display a question asking whether two stim trains felt the same
%or different
% The answer variable allows you to color code one answer. Use 'left' to
% color code (in yellow) the left-sde answer and 'right' to color code the
% right-side answer

yellow  = [1 0.75 0];

if ~exist('answer', 'var')
    % Add text and yes/no buttons to the window
    Screen('TextSize', window, 40);
    DrawFormattedText(window, 'Did the stimulation feel the same or different?', 'center', 'center', white);
    Screen('TextSize', window, 56);
    DrawFormattedText(window, 'Same', screenXpixels*.25-55, screenYpixels*.75, white);
    DrawFormattedText(window, 'Different', screenXpixels*.75-85, screenYpixels*.75, white);
    Screen('TextSize', window, 30);
    DrawFormattedText(window, 'press left arrow key', screenXpixels*.25-125, screenYpixels*.75+50, white);
    DrawFormattedText(window, 'press right arrow key', screenXpixels*.75-125, screenYpixels*.75+50, white);
    
else % then we're color-coding the yes or no response text based on the answer given
    if strcmp(answer, 'left') % color the yes answer yellow
        Screen('TextSize', window, 40);
        DrawFormattedText(window, 'Did the stimulation feel the same or different?', 'center', 'center', white);
        Screen('TextSize', window, 56);
        DrawFormattedText(window, 'Same', screenXpixels*.25-55, screenYpixels*.75, yellow);
        DrawFormattedText(window, 'Different', screenXpixels*.75-85, screenYpixels*.75, white);
        Screen('TextSize', window, 30);
        DrawFormattedText(window, 'press left arrow key', screenXpixels*.25-125, screenYpixels*.75+50, yellow);
        DrawFormattedText(window, 'press right arrow key', screenXpixels*.75-125, screenYpixels*.75+50, white);
    elseif strcmp(answer, 'right') % color the no answer yellow
        Screen('TextSize', window, 40);
        DrawFormattedText(window, 'Did the stimulation feel the same or different?', 'center', 'center', white);
        Screen('TextSize', window, 56);
        DrawFormattedText(window, 'Same', screenXpixels*.25-55, screenYpixels*.75, white);
        DrawFormattedText(window, 'Different', screenXpixels*.75-85, screenYpixels*.75, yellow);
        Screen('TextSize', window, 30);
        DrawFormattedText(window, 'press left arrow key', screenXpixels*.25-125, screenYpixels*.75+50, white);
        DrawFormattedText(window, 'press right arrow key', screenXpixels*.75-125, screenYpixels*.75+50, yellow);
    else
        warning('answer variable in displaySameDiffQuestion must be a string of Same or Different')
    end
end

% draw left arrow
% create a triangle
head   = [screenXpixels*.25+25,  screenYpixels*.75+100]; % coordinates of head
width  = 25;           % width of arrow head
points = [ head-[0,width]         % left corner
    head-[width*1.5,0]         % right corner
    head+[0,width] ];      % vertex
Screen('FillPoly', window, white, points);
% create line for arrow
lineCoords = [head', head'+[width*2,0]'];
lineWidthPix = 4;
Screen('DrawLines', window, lineCoords, lineWidthPix, white);

% draw a right arrow
% create a triangle
head   = [screenXpixels*.75+35,  screenYpixels*.75+100]; % coordinates of head
points = [ head-[0,width]         % left corner
    head+[width*1.5,0]         % right corner
    head+[0,width] ];      % vertex
Screen('FillPoly', window, white, points);
% create line for arrow
lineCoords = [head', head'-[width*2,0]'];
lineWidthPix = 4;
Screen('DrawLines', window, lineCoords, lineWidthPix, white);

vbl = Screen('Flip', window);
end

