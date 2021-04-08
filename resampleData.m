% ************************************************************************
% Function: resampleData
% Purpose:  Re-sampling the dataset and response variable
%           according to a specified method
%
% Parameters:
%       x: predictors
%       y: response variable
%       opt: sampling options
%
% Output:
%       xs: augmented predictors
%       ys: augmented outcome variable
%       parent: array specifying oversampling parent case
%       removal: array specifying cases to be removed
%
% ************************************************************************


function [ xs, ys, parent, removal ] = resampleData( x, y, method, opt )

nCases = size( x, 1 ); % number of cases
nPred = size( x, 2 ); % number of predictors
nOver = fix( nCases*opt.over ); % number of cases to add
nUnder = fix( nCases*opt.under ); % number of cases to remove

if size( x, 3 ) == 3
    xs = zeros( nOver, nPred, 3 );
else
    xs = zeros( nOver, nPred ); % new synthetic cases
end
ys = zeros( nOver, 1 ); % new synthetic responses

parent = zeros( nOver, 1 ); % case IDs of cases selected for augmentation

% ------------------------------------------------------------------------
%  Determine weights for each of the real cases
% ------------------------------------------------------------------------

if opt.doControlRandomisation
    rng('default'); % reset seed for random number generator
end

w = ones( nCases, 1 ); % setup weightings for each case

for k = 0:opt.nWeightings

    if k == 0
        % use response variable
        z = y;
    else
        % select a predictor variable
        z = x(:,k);
    end
    switch opt.distFunction
        case 'Normal'
            % use a simple normal distribution
            w = w./exp( -abs(z) );
        case 'Kernel'
            % obtain the probability density function
            yPDF = fitdist( z , 'Kernel', 'Kernel', 'Normal' );
            w = w./pdf( yPDF, z );
    end

end

% re-scale weightings to 0..1
w = (w-min(w))/(max(w)-min(w));

if opt.topend
    w = w.*( y>median(y) );
end

% ------------------------------------------------------------------------
%  Shortlist cases for augmentation
% ------------------------------------------------------------------------

switch opt.caseSelection
    
    case 'Threshold'
        % select cases at extremes where weight > threshold
        shortlist = find( w > opt.threshold );
        
    case 'Probability'
        % select cases weighted by the probability distribution
        p = cumsum( w ); % cummulative distribution (can be lumpy)
        shortlist = zeros( nOver, 1 );
        for i = 1:nOver
            % find random case 
            shortlist(i) = find( p > rand()*p(end), 1 );
        end
        
end

% ------------------------------------------------------------------------
%  Generate new synthetic cases
% ------------------------------------------------------------------------

for i = 1:nOver

    % pick a random case from the shortlist
    j = shortlist(randperm( length(shortlist), 1 ));

    switch method
        case 'SMOTER'
            [ xs( i,: ), ys( i ) ] = augCaseSMOTER( x(j,:), y(j), ...
                                                        x, y, opt );
        case 'Rotation'
            signal = squeeze( x(j, :, : ) );
            xs( i, :, : ) = augCaseRotation( signal, opt );
            ys( i ) = y( j );
    end
    
    parent( i ) = j;
    
end

% ------------------------------------------------------------------------
%  Remove some existing real cases
% ------------------------------------------------------------------------

switch opt.caseSelection
    
    case 'Threshold'
        % select cases at extremes where weight <= threshold
        removal = randsample( find( w <= opt.threshold ), nUnder );
        
    case 'Probability'
        % select cases weighted by the probability distribution
        w( w==0 ) = min( w(w>0) ); % make the zero, non-zero
        p = cumsum( 1./w ); % cumulative distribution of inverse
        removal = zeros( nUnder, 1 );
        for i = 1:nUnder
            % find random case 
            removal(i) = find( p > rand()*p(end), 1 );
            % update the distribution to prevent it being selected again
            if removal(i) > 1 && removal(i) < nCases
                p(removal(i)+1:end) = ...
                    p(removal(i)+1:end)-p(removal(i))+p(removal(i)-1);
                p(removal(i)) = p(removal(i)-1);
            elseif removal(i) == 1
                p(removal(i)+1:end) = p(removal(i)+1:end)-p(removal(i));
                p(removal(i)) = 0;
            else
                p(removal(i)) = p(removal(i)-1);
            end
        end
        
end
   
end


