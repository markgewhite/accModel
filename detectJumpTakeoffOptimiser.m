% ************************************************************************
% Function: detectJumpTakeoffOptimiser
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


function detectJumpTakeoffOptimiser( signal, takeoff, landing, opt )


% ------------------------------------------------------------
%   Setup and run the optimisation
% ------------------------------------------------------------

testFcn = @(param) detectJumpTakeoffTestHarness(  signal, ...
                                        takeoff, ...
                                        landing, ...
                                        opt, ...
                                        param );
                                   
%varDef(1) = optimizableVariable( ...
%                'idxMaxDiv', [50 100], 'Type', 'integer' );  
varDef(1) = optimizableVariable( ...
                'offset', [-3 3], 'Type', 'integer' );            
%varDef(3) = optimizableVariable( ...
%                'smoothing', [0 20], 'Type', 'integer' );   
%varDef(1) = optimizableVariable( ...
%                'reorientate', [0 1], 'Type', 'integer' );  
            
% ------------------------------------------------------------
%   Make a first pass at the optimisation - wide search
% ------------------------------------------------------------

bayesopt( testFcn, varDef, ...
          'MaxObjectiveEvaluations', 100, ...
          'ExplorationRatio', 0.5, ...
          'NumCoupledConstraints', 1 );

pause;

end