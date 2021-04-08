% ************************************************************************
% Function: augCaseSMOTER
% Purpose:  Augment a given case using the SMOTER algorithm
%
% Parameters:
%       x: predictors of case in question for re-sampling
%       y: outcome of case in question
%       xPool: pool of available predictors
%       yPool: pool of available outcomes
%       opt: SMOTER options
%
% Output:
%       xAug: augmented predictors
%       yAug: augmented outcome
%
% ************************************************************************

function [ xa, ya ] = augCaseSMOTER( x, y, xPool, yPool, opt )

% find the nearest neighbours
nnID = knnsearch(   xPool( :, opt.nFPC ), ...
                    x( :, opt.nFPC ), ...
                    'k', opt.knn+1, ...
                    'Distance', opt.distanceMetric, ...
                    'NSMethod', 'kdtree' );

% ignore the neighbour that is the same as the case in question
nnID = nnID( 2:end );

% select random neighbour from the oID list
k = nnID( randperm(length(nnID), 1) ); 

% nearest neighbour in question + its outcome
xk = [ xPool( k, : ) yPool(k) ];

% append the outcome as an extra dimension
x( end+1 ) = y;

% generate new feature vectors randomly interpolated between
% case in question and its nearest neighbours
switch opt.interpolation
    case 'Uniform'
        q = rand();
    case 'Normal'
        q = normrnd( 0.5, 0.5 );
end

%  interpolate using linear algebra
xa = x + (xk-x)*q;

switch opt.estimation
    case 'Linear'
        % extract the interpolated outcome
        ya = xa( end );
        % remove it
        xa = xa( 1:end-1 );
    case 'Gaussian Process'
        % train a small model
        mdl = fitrgp( xPool(nnID,:), yPool(nnID) );
        ya = predict( mdl, xa(1:end-1) );
        xa = xa( 1:end-1 );
end       

end
