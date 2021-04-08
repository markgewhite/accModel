% ************************************************************************
% Function: selectPredictorsUnivariate
% Purpose:  Produce a logical matrix specifying the predictors
%           selected on the basis of a univariate statistical test
%
% Parameters:
%       x: predictors
%       y: response
%       opt: options
%
% Output:
%       p: logical matrix of selected predictors
%       orderID: sorted predictors based on length scaling
%       r: correlations
%
% ************************************************************************


function [ p, orderID, r ] = selectPredictorsUnivariate( x, y, opt )

x = table2array( x );
np = size( x, 2 ); % number of predictors

% find the simple univariate correlation between
% each predictor and the response
r = zeros( np, 1 ); % correlation statistic
for i = 1:np
    r( i ) = corr( x(:,i), y );
end

w = exp(r); % predictor weights
w = w/sum(w); % normalised predictor weights

[ ~, orderID ] = sort( abs(r), 'Descend' );
   
p = false( 1, np ); % logical selection array
switch opt.criterion
    
    case 'Threshold'      
        threshold = opt.rThreshold;
        p = ( abs(r) > threshold )';
    
    case 'MaxPredictors'
       if opt.maxPredictors <= length(p)
           p( orderID(1:opt.maxPredictors) ) = true;
       end
       
end


end
 