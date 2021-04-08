% ************************************************************************
% Function: selectPredictorsLS
% Purpose:  Produce a logical matrix specifying the predictors
%           selected for each run of a model
%           Based on the length scales in a GPR model
%
% Parameters:
%       x: predictors
%       y: response
%       opt: options for GPR model
%       showPlot: flag
%
% Output:
%       p: logical matrix of selected predictors
%       orderID: sorted predictors based on length scaling
%       w: weighting if selection not desired
%
% ************************************************************************


function [ p, orderID, w ] = selectPredictorsLS( x, y, opt, selection, showPlot )

%sF0 = opt.sigmaF0;
d = size( x, 2 );
%sM0 = ones( d, 1 )*opt.sigmaM0;

if strcmp( opt.kernel(1:3), 'ard' )
    kernel = opt.kernel;
else
    kernel = strcat( 'ard', opt.kernel );
end

if selection.doControlRandomisation
    rng('default'); % reset seed for random number generator
end
                
model = fitrgp( x, y, ...
                'BasisFunction', opt.basis, ...
                'KernelFunction', kernel, ...
                'Sigma', opt.sigmaN0, ...
                'ConstantSigma', opt.constSigma, ...
                'SigmaLowerBound', opt.sigmaMin, ...
                'Standardize', opt.standardize );

sM = model.KernelInformation.KernelParameters(1:end-1,1);
sF = model.KernelInformation.KernelParameters(end);

w = exp(-sM); % predictor weights
w = w/sum(w); % normalised predictor weights

[ ~, orderID ] = sort( sM );
   
p = false( 1, length(sM));
switch selection.criterion
    
    case 'Threshold'      
        threshold = selection.lengthScaleThreshold;
        while sum(p) == 0
            p = ( sM < threshold )';
            threshold = threshold*10;
        end
    
    case 'MaxPredictors'
       p( orderID(1:selection.nPredsSearch) ) = true;

end

if showPlot
    figure(3);
    if selection.doReorder
        bar( (1:d)', log10( sM( orderID ) ) );
    else
        bar( (1:d)', log10( sM ) );
    end
    xlabel('Predictor');
    ylabel('Log 10 length scale');
    drawnow;
    disp(['Ascending order (ID): ' num2str(orderID') ]);
end

end
 