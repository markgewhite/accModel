% ************************************************************************
% Function: filterPredictors
% Purpose:  Filter the full list of predictors according to a
%           specified method, returning the logical array.
%
% Parameters:

%
% Output:
%       pSelect: logical array of selected predictors
%
% ************************************************************************

function [ p, pOrder, r ] = filterPredictors( x, y, options )

np = size( x, 2 ); % number of predictors

switch options.filter.method

    case 'All'
        p = true( np, 1 );
        pOrder = 1:np;
        r = zeros( np, 1 );
        
    case 'Univariate'
        [ p, pOrder, r ] = selectPredictorsUnivariate( ...
                            x, ...
                            y, ...
                            options.filter );
                        
    case 'LengthScale'
        [ p, pOrder ] = selectPredictorsLS( ...
                            x, ...
                            y, ...
                            options.gpr, ...
                            options.filter, ...
                            options.plot.doShowLengthScaling );
                        
    case 'Annealing'
        p = logical( table2array( struct2table(options.filter.predictor) ) );
        pOrder = 1:np;
        r = zeros( np, 1 );

end
            
if options.filter.doReorder
    p = p( pOrder );
end


end

