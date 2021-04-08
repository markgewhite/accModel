% ************************************************************************
% Function: modelSelectionFileOutput
% Purpose:  Generate a model selection plot from file
%
%
% Parameters:
%       data
%       options
%       hyperparameters
%
% Output:
%       bestHP: optimal hyperparameter values
%
% ************************************************************************

function modelSelectionFileOutput( traces, options )

opt = options.optimize;
optPlot = options.plot.sub;

v = opt.activeVar;
nVar = length( v );

result.grp = strings( nVar, 1 );
result.var = strings( nVar, 1 );
result.range = cell( nVar, 1 );
result.descr = strings( nVar, 1 );
result.lim = cell( nVar, 1 );
result.isLog = false( nVar, 1 );
result.nLevels = zeros( nVar, 1 );
for i = 1:nVar
    result.grp(i) = opt.grp( v(i) );
    result.var(i) = opt.var( v(i) );
    result.descr(i) = opt.descr( v(i) );
    result.lim(i) = opt.lim( v(i) );
    result.isLog(i) = opt.isLog( v(i) );
    result.varDef(i) = {opt.varDef( v(i) )};
    switch opt.varDef( v(i) ).Type
        case 'categorical'
            result.range{i} = opt.varDef( v(i) ).Range;
        case {'real', 'integer'}
            result.range{i} = opt.varDef( v(i) ).Range(1): ...
                        opt.varDef( v(i) ).Range(2);
    end
    result.nLevels(i) = length( result.range{i} );
end

result.bestHP = traces(:, 1:end-1);
result.loss = traces(:, end);

modelSelectionPlot( result, 'initial' );
for i = 1:size(traces,1)
    modelSelectionPlot( result, 'iteration', opt, optPlot );
end
modelSelectionPlot( result, 'done', opt, optPlot );
    
end


