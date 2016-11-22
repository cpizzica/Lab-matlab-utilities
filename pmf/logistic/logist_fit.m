function [fits_,sems_,stats_,preds_,resids_] = logist_fit(data, lumode, varargin)%% LOGIST_FIT fits a logistic function to data using maximum likelihood%   maximization under binomial assumptions.  It uses logist_err for%   error calculation. The logistic assumes a linear (on the coefficients)%   model of log-odds-ratio (ln(p/(1-p))) = SUM(B_i*x_i) = f(X), where B_i are%   the coefficients to fit and x_i is the data. Also incorporates a lower%   and upper asymptote:%         p = lower + (1 - lower - upper) * 1/(1 + exp(-f(x))% % Usage: [fits_,sems_,stats_,preds_,resids_] = logist_fit(data, lumode, varargin)% Input values are:%	  data,   Must be organized as rows of observations.%  	  		   The 1st column should be a 1 if you want to estimate a %				   'bias' term, columns 2 thru n-1 are the values for the %				   independent variables, and the last column contains 1 or %				   0 for the choice.%              JIG ADDED 1/26 ... can be a special case of a cell array:%                   {'expr', choices, bias, var1, var2 ...}%                   see logist_data for details%     lumode, Specifies how the lower and upper asymptotes are dealt with:%               'n'             ... lower=0,   upper=1%               'nk'            ... lower=0.01,upper=0.99%               'l'             ... lower=fit, upper=1%               'u'             ... lower=0,   upper=fit%               'lu1' (default) ... lower=upper=fit%               'lu2'           ... lower=fit, upper=fit%     varargin, Passed to val function%%	Returns values are:%	  fits,   [betas, lower, upper]%               betas are linear coefficients for columns 1:end-1 of data.%               lower and/or upper are returned ONLY if fit (see lumode,%               above)%     sems,    Standard errors of the fits. [gamma_sem lasem betas_sems]%     stats_  ... [fitLLR Deviance Average_deviance p]%                   fitLLR is the log likelihood of obtaining the %                       data given the fit (returned by quick_err)%                   Deviance is 2(dataLLR - fitLLR) = -2*fitLLR%                   Average_deviance is Deviance./n. duh.%                   p is probability from chi^2 pdf with df = #blocks-3%     preds_  ... A vector of the probability of making a correct choice given%                   the fit%     resids_ ... [deviance_residuals direct_residuals] per trial%   1/16/2007 jig updated based on ctPsych_fit% 	 9/5/2001 jig spawned from logistfit%   4/6/2001 standard errors added (JD)%   3/22/2001 update for new matlab (replace fmins)%   9/17/94  M Shadlenif nargin < 1 || isempty(data)    fits_   = nan;    sems_   = nan;    stats_  = nan;    preds_  = nan;    resids_ = nan;  returnendif nargin < 2    lumode = [];end% logist_setup does all the work[fun, data, inits] = logist_setup(data, lumode);% Do the fit[fits_,f,e,o,l,g,H]=fmincon('logist_err',...    inits(:,1),[],[],[],[],inits(:,2),inits(:,3),[], ...    optimset('LargeScale', 'off', 'Algorithm', 'active-set', ...    'Display', 'off', 'Diagnostics', 'off'), ...    fun, data, varargin{:});if nargout > 1    % Standard errors    %   The covariance matrix is the negative of the inverse of the    %   hessian of the natural logarithm of the probability of observing    %   the data set given the optimal parameters.    %   For now, use the numerically estimated HESSIAN returned by fmincon    %   (which remember is computed from -log likelihood)    % -H because we used -logL in quick_err    sems_ = sqrt(diag(-((-H)^(-1))));end% return statsif nargout > 2        % log likelihood of the fits ("M1" in Watson)    % is just the negative of the error function    M1 = -logist_err(fits_, fun, data, varargin{:});        % deviance is 2(M0 - M1), where    % M0 is the log likelihood of the data ("saturated model") --    %   which in this case is, of course, ZERO    dev = -2*M1;        % average deviance    adev = dev./size(data, 1);        % probability is from cdf    p = 1 - chi2cdf(dev, size(data, 1) - size(fits_, 1));        stats_ = [M1 dev adev p];end% return the predicted probabilities for each observation% again using only first fitif nargout > 3        preds_ = feval(fun, fits_, data(:,1:end-1), varargin{:});end% return the deviance residuals ... these are the square roots%   of each deviance computed individually, signed according to%   the direction of the arithmatic residual y_i - p_i.% See Wichmann & Hill, 2001, "The psychometric function: I. Fitting,%   sampling, and goodness of fit", eqs. 11 and 12.if nargout > 4    % useful selection arrays    L1 = data(:,end) == 1;    L0 = data(:,end) == 0;            % avoid p=0,1    TINY = 0.0001;    pds  = preds_;    pds(pds==0) = TINY;    pds(pds==1) = 1 - TINY;        % first column is residual deviance for outcome    %  outcome = 1 trials ...  sqrt(-2 * log(p))    %  outcome = 0 trials ... -sqrt(-2 * log(1-p))        rdo       = pds;    rdo(L0) = 1 - rdo(L0);    rdo       = (data(:,end)*2-1).*sqrt(-2*log(rdo));        % second column is direct residual for outcome    %  outcome = 1 trials ... 1 - p;    %  outcome = 0 trials ... -p;    rro     = pds;    rro(L1) = 1 - rro(L1);    rro(L0) = -rro(L0);        resids_ = [rdo rro];endreturn    % standard errors% The covariance matrix is the negative of the inverse of the % hessian of the natural logarithm of the probability of observing % the data set given the optimal parameters.if nargout > 3  % the hessian is a mess. A couple of facts to keep in mind:  %  - "the probability of observing the data set" means the product  %     of the predicted probabilities of observing the result on each  %     trial, which is just logist_val for correct trials but 1 -   %     logist_val for incorrect trials.  %  - We take the natural logarithm of this product, which means that we  %     can instead compute the sum of the individual logs... which is  %     just P = SUM(ln(p(Xs, Data, correct))) + SUM(ln(1-p(Xs, Data, incorrect)))  %  - We compute the matrix of second derivatives of P with respect to each pair  %     of parameters (i.e., gamma (g), lambda (l), and each beta (bs))  %  - it is mirror-symmetric, since d^2P/dxdy = d^P/dydx  %  - the diagonal is, of course, d^2P/dx^2  %  - We will build it in three sections:  %     1) a vector of [d^2P/(dg)(dbs_i) d^2P/(dg)^2   d^2P/(dg)(dl)]  %     2) a vector of [d^2P/(dl)(dbs_i) d^2P/(dl)(dg) d^2P/(dl)^2  ]  %     3) a matrix of d^2P/(dbs_i)(dbs_j)  % compute correct/incorrect differently (p vs. 1-p)  Lc = Data(:,end) == 1;  Li = Data(:,end) == 0;  % some useful variables to make the computations easier  ga = fits_(1);  la = fits_(2);  bs = fits_(3:end);  zc = exp(-1*(Data(Lc,1:end-1) * bs));  zi = exp(-1*(Data(Li,1:end-1) * bs));  kc = (ga * zc + 1 - la).^2;  ki = (-zi + ga*zi - la).^2;    % first build matrix #3, above, which is wrt the betas  Hbs = zeros(nbetas, nbetas);  Ac  = -((ga*zc.^2+la-1).*(-1+ga+la).*zc)./(kc.*(1+zc).^2);  Ai  = -((-zi.^2+ga.*zi.^2+la).*(-1+ga+la).*zi)./(ki.*(1+zi).^2);  for i = 1:nbetas	 for j = 1:i		Hbs(i,j) = sum(Ac.*Data(Lc,i).*Data(Lc,j)) + ...			 sum(Ai.*Data(Li,i).* Data(Li,j));		Hbs(j,i) = Hbs(i,j); 	 end  end	  % build the Hessian, whose size depends on whether we are considering  % gamma and/or lambda  if gamma_fit == 1 & lambda_fit == 1	 H = zeros(nbetas+2,nbetas+2);	 H(3:end,3:end) = Hbs;  elseif gamma_fit == 1 | lambda_fit == 1	 H = zeros(nbetas+1,nbetas+1);	 H(2:end,2:end) = Hbs;  else	 H = Hbs;  end    % now fill in H for #1 (second derivatives wrt gamma)  % if we've fit gamma, this is always the first row & col  % of the matrix  if gamma_fit == 1	 H(1,1) = -sum(zc.^2./kc) - sum(zi.^2./ki);	 	 if lambda_fit == 1		H(1,2) = sum(zc./kc) + sum(zi./ki);		H(2,1) = H(1,2);	 end	 	 bind = lambda_fit + 1;	 for i = 1:nbetas		H(bind+i, 1) = (la - 1)*sum(Data(Lc,i).*zc./kc) + ...			 la*sum(Data(Li,i).*zi./ki);		H(1, bind+i) = H(bind+i, 1);	 end  end    lind = gamma_fit + 1;  if lambda_fit == 1	 H(lind,lind) = -sum(1./kc) - sum(1./ki);	 for i = 1:nbetas		H(lind+i,lind) = -ga*sum(zc.*Data(Lc,i)./kc) + ...					 (1-ga)*sum(zi.* Data(Li,i)./ki);		H(lind,lind+i) = H(lind+i,lind);	 end  end  % now get the diagonal of the negative of the inverse  se=sqrt(diag(-H^-1));    % put it into the output array  if gamma_fit == 1 & lambda_fit == 1	 sems_ = se;  elseif gamma_fit == 1	 sems_ = [se(1); 0; se(2:end)];  elseif lambda_fit == 1	 sems_ = [0; se];  else	 sems_ = [0; 0; se];  endend