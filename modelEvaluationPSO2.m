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
%       isCat: identifies whether X element is categorical
%
% Output:
%       obj: model prediction
%
% ************************************************************************

function obj = modelEvaluationPSO2( model, Xnumeric, isCat )

X( isCat ) = round( Xnumeric( isCat ) );
X( ~isCat ) = Xnumeric( ~isCat );

obj = predict( model, X );

end
