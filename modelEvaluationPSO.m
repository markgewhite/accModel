% ************************************************************************
% Function: modelEvaluationPSO
% Purpose:  Model evaluation at a given point in feature space
%           for Particle Swarm Optimisation.
%           This routine is necessary to ensure only the first
%           argument from predict is returned. This is useful for
%           optimisations.
%
% Parameters:
%       model: GP fit
%       Xnumeric: from particle swarm
%
% Output:
%       obj: model prediction
%
% ************************************************************************

function obj = modelEvaluationPSO( model, Xnumeric )

X = round( Xnumeric );

obj = predict( model, X );

end
