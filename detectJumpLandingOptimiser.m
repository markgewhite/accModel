% ************************************************************************
% Function: detectJumpLandingOptimiser
% Purpose:  Optimise parameter settings for jump detections
%
% Parameters:
%        signal: accelerometer signal
%        takeoff: takeoff index
%        landing: landing time 
%        opt: detection options
%
% Output:
%       obj: mean detection error 
%
% ************************************************************************


function detectJumpLandingOptimiser( signal, takeoff, landing, opt )


% ------------------------------------------------------------
%   Setup and run the optimisation
% ------------------------------------------------------------

testFcn = @(param) detectJumpLandingTestHarness(  signal, ...
                                        takeoff, ...
                                        landing, ...
                                        opt, ...
                                        param );
                                                                       
varDef(1) = optimizableVariable( ...
                'maxSpikeWidth', [10 50], 'Type', 'integer' );
%varDef(1) = optimizableVariable( ...
%                'freefallLim', [0.5 1.5], 'Type', 'real' );
%varDef(2) = optimizableVariable( ...
%                'freefallRng', [1 150], 'Type', 'integer' );  
%varDef(1) = optimizableVariable( ...
%                'offset', [-20 10], 'Type', 'integer' );            
%varDef(1) = optimizableVariable( ...
%                'smoothing', [1 10], 'Type', 'integer' );   

% ------------------------------------------------------------
%   Make a first pass at the optimisation - wide search
% ------------------------------------------------------------

bayesopt( testFcn, varDef, ...
          'MaxObjectiveEvaluations', 100, ...
          'ExplorationRatio', 0.5, ...
          'NumCoupledConstraints', 1, ...
          'Verbose', 2 );

pause;

end