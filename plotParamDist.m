% ************************************************************************
% Function: plotParamDist
% Purpose:  Plot parameter distributions for publication
%
%
% ************************************************************************

function figObj = plotParamDist( XTrace, options, activeVar )

setup = options.optimize;

% switch to the requested optimizable variables
varDef = switchActiveVarDef( setup.varDef, activeVar );

% select the appropriate XTrace fields to match
XTrace = retainActiveVar( XTrace, varDef );

% do the plot
setup.layout = 'vertical';
setup.transform = true;
[ ~, ~, figObj ] = plotOptDist( XTrace, varDef, setup, [] );

end

