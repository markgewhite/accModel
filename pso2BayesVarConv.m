% ************************************************************************
% Function: pso2BayesVarConv
% Purpose:  Convert Particle Swarm numeric variables to
%           Bayesian model variables
%
% Parameters:
%       Xnumeric: from particle swarm
%       varConv: variable conversion details for table
%
% Output:
%       X: correct table format for X
%
% ************************************************************************

function X = pso2BayesVarConv( Xnumeric, varConv )

for i = 1:length( Xnumeric )
    
    if strcmp( varConv.varDef{i}.Type, 'categorical' )
        X.(varConv.varDef{i}.Name) = categorical( varConv.fcn{i}( Xnumeric(i) ) );
    else
        X.(varConv.varDef{i}.Name) = Xnumeric(i);
    end
end

X = struct2table( X );

end
