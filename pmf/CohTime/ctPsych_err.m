function err_ = ctPsych_err(fits, fun, data, pcor, varargin)% function err_ = ctPsych_err(fits, fun, data, pcor, varargin)%% Computes the error of the given function, %   for the given fits, to the data.% Used by fmincon.%% Arguments:%   fits  ... the vector of n parameters. %   fun   ... handle to function to generate prediction from fits and data%   data  ... rows are trials, columns are fun specific, typically:%       data(1) = coh  (0 .. 99.9%)%       data(2) = time (fraction of total)%       data(3) = dot dir: left (-1) / right (1)%   pcor  ... rows are trials, columns are:%       pcor(1) = pct or correct (1) / error (0)%       pcor(2) = (optional) n%% Returns:%	err_ ... the negative of the log likelihood of obtaining the data %					using the given parameters.%ps = feval(fun, fits, data, varargin{:});% Avoid log 0ps(ps==0) = 0.0001;ps(ps==1) = 1 - 0.0001;if size(pcor, 2) == 1    % Now calculate the joint probability of obtaining the data set conceived as    %   a list of Bernoulli trials.  This is just ps for trials = 1 (correct) and    %   1-ps for trials of 0 (error).    % Note that fmincon searches for minimum, which    %   is why we send the negatve of logL    err_ = -sum(log([ps(pcor==1); 1-ps(pcor==0)]));else    % use 'n' values    % see appendix of Watson's "Probability summation over time" (1978)    % paper for derivation    err_ = -sum(pcor(:,2).*(pcor(:,1).*log(ps) + (1-pcor(:,1)).*log(1-ps)));        if isnan(err_)        fits    endend