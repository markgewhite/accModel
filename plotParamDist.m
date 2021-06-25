% ************************************************************************
% Function: plotParamDist
% Purpose:  Plot parameter distributions for publication
%
%
% ************************************************************************

function figObj = plotParamDist( XTrace, options, activeVar, pos )

setup = options.optimize;

% switch to the requested optimizable variables
varDef = switchActiveVarDef( setup.varDef, activeVar );

% select the appropriate XTrace fields to match
XTrace = retainActiveVar( XTrace, varDef );

% setup positioning
if nargin == 4
    setup.layout = 'vertical-adaptive';
    setup.position = pos;
else
    setup.layout = 'vertical';
end
setup.transform = true;
setup.compact = true;

% replace old terms
setup.descr(7) = 'log_{10}\sigma';
setup.descr(9) = 'log_{10}BC';
setup.descr(10) = 'log_{10}KS';
setup.descr(11) = 'log_{10}\epsilon';
setup.descr(12) = 'log_{10}\lambda_{LR}';
if setup.compact
    setup.descr(5) = 'GPR Basis';
    setup.descr(6) = 'GPR Kernel';
    setup.descr(8) = 'SVM Kernel';
    setup.descr(13) = 'Regularisation';
    setup.descr(21) = 'Func Density (fn\cdots^{-1})';
    setup.descr(22) = 'Func & Pen Order';
    setup.descr(27) = 'Retained FPCs';
end

% do the plot
[ ~, ~, figObj ] = plotOptDist( XTrace, varDef, setup, [] );

end

