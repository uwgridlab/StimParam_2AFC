function plotPsycho(results,intensityName,p,functionName)
% plotPsycho(results,intensityName,p,functionName)

if ~exist('intensityName','var')
    intensityName= 'Intensity';
end

intensities = unique(results.intensity);

% Then we'll loop through these intensities calculating the proportion of
% times that 'response' is equal to 1:

nCorrect = zeros(1,length(intensities));
nTrials = zeros(1,length(intensities));

for i=1:length(intensities)
    id = results.intensity == intensities(i) & isreal(results.response);
    nTrials(i) = sum(id);
    nCorrect(i) = sum(results.response(id));
end

pCorrect = nCorrect./nTrials;

% clf
hold on
 
 sd = pCorrect.*(1-pCorrect)./sqrt(nTrials);  %pq/sqrt(n)
 errorbar((intensities),100*pCorrect,100*sd,'bo','MarkerFaceColor','b');


if exist('p','var')
    %plot the parametric psychometric function 
    x = linspace(min(results.intensity),max(results.intensity),101);
    evalStr = sprintf('y=%s(p,x);',functionName);
    eval(evalStr)
    plot((x),100*y,'r-','LineWidth',2);

end

ylim  = get(gca,'YLim');
xlim = get(gca,'XLim');

pThresh = 100*(1/2)^(1/3);  


if exist('p','var')
    plot([xlim(1),(p.t),(p.t)],[pThresh,pThresh,ylim(1)],'k-');
    title(sprintf('Threshold: %5.4g',p.t)); 
end

set(gca,'XTick',(intensities));

%set(gca,'YLim',[0,100]);
xlabel(intensityName);
ylabel('Percent Correct');










