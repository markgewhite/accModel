% ************************************************************************
% Function: plotSurrogateModel
% Purpose:  Plot parameter distributions for publication
%
%
% ************************************************************************

function figObj = plotSurrogateModel( output, options, modelType, subgroup )

switch modelType
    case 1 % LR model parameters
        activeVar = [ 12 13 14 15 16 17 21 22 23 27];
    case 2 % SVM model parameters
        activeVar = [ 8 9 10 11 15 16 17 21 22 23 27];
    case 3 % GPR model parameters
        activeVar = [ 5 6 7 15 16 17 21 22 23 27 ];
    otherwise
        error('Unrecognised model type.');
end

switch subgroup
    case 'data'
        plotVar = (1:6)+length(activeVar)-6;
    case 'model'
        plotVar = 1:5; % standard length, not 1:length(activeVar)-6;
    otherwise
        error('Unrecognised parameter subgroup.');
end

setup = options.optimize;

% do the plot
setup.layout = 'vertical';
setup.transform = true;
figObj = plotObjFn( output.optima.Final, ...
                    output.models.smModel, ...
                    setup, activeVar, plotVar, [] );

end

