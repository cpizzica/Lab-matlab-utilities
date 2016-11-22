function [tax_, haz_] = hazard(pdf, bin_size)% function [tax_, haz_] = hazard(pdf, bin_size)%if nargin < 2  bin_size = max(pdf)+1-min(pdf)/20;endtax_  = min(pdf)-bin_size:bin_size:max(pdf)+bin_size;tbins = histc(pdf, tax_);tbins = tbins/sum(tbins);den   = 1 - cumsum(tbins);den(den==0) = 0.00001;haz_  = tbins./den;N       = 1000;HAZARD  = 2;MAXWAIT = 5; %maximum possible wait time before a new sound playsMUTE    = 1; %time ensured to be silent after sound playing% generate listwaitlist = min(MAXWAIT, MUTE + exprnd(1./HAZARD, N, 1));% show ithist(waitlist,20)% mean interval should be inverse of hazard, ignoring timeoutdisp(sprintf('objective hazard = %.2f, empirical hazard = %.2f', HAZARD, 1./(mean(waitlist)-MUTE)))% GENERATING LIST OF WAIT TIMES    sz= 0.01; % Setting how fine-grained the analytic exponential distribution is    trials = 100000;   %how many random picks I take        maxwait = 3; %maximum possible wait time before a new sound plays    mute = 1; %time ensured to be silent after sound playing        hazard = 0.1;        range = sz:sz:100;        %creating analytic epd and cdf    epd = exppdf(range,1./hazard);    cdf = cumtrapz(range, epd);        % multiply picks from epd by a factor to give a reasonable number of wait    % seconds    factor = (maxwait-mute)/max(epd);    %Generating the list of wait times.    waitlist = mute + factor*epd(randi(length(epd), [1, trials]));    % CHECKING HAZARD RATES    %Creating histogram of wait times ('d')    bins = 1000;    smallest = min(waitlist); biggest = max(waitlist);    binsz = (biggest-smallest)/bins;    edges = smallest:binsz:biggest;    d = histc(waitlist, edges); %distribution of picked wait times    C = cumtrapz(1:length(d), d); %integral of d    C = C*binsz; %correcting for bin-size of our distribution    h = epd./(cdf(end)-cdf); %plot of hazard for our analytical distributions    H = d./(C(end)-C); %plot of hazard from our random choice distributions        resize = length(H)/length(h);    h = imresize(h, resize);    plot(H); hold on; plot(h, 'g');    xlabel('Trial');    ylabel('Hazard Rate');    legend('Random Picked Distribution', 'Analytic Distribution');