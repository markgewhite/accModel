% ************************************************************************
% Function: detectJumpTakeoffTestHarness
% Purpose:  Test parameter settings from multiple data sub-samples
%
% Parameters:
%        signal: accelerometer signal
%        takeoff: takeoff index
%        landing: landing time 
%        opt: detection options
%        params: detection algorithm parameters
%
% Output:
%       obj: mean detection error 
%
% ************************************************************************


function [ obj, constraint ] = detectJumpTakeoffTestHarness( ...
                                        signal, ...
                                        takeoff, ...
                                        landing, ...
                                        opt, ...
                                        param )


% ------------------------------------------------------------
%   Unpack the hyperparmeters
% ------------------------------------------------------------

if ~isempty( param )
    param = table2array( param );
    %opt.idxMaxDivergence = param( 1 );
    opt.idxOffset = param( 1 );
    %opt.nSmooth = param( 3 );
    %opt.doReorientation = param( 1 );
end


% ------------------------------------------------------------
%  subsample data
% ------------------------------------------------------------

% generate bootstrap samples
boot.method = 'Bootstrap';
boot.iterations = 10;
boot.doControlRandomisation = false;
sampleID = partitionData( signal, [], boot );


% ------------------------------------------------------------
%  Test the algorithm multiple times
% ------------------------------------------------------------

nPartitions = size( sampleID, 2 );
kLoss = zeros( nPartitions, 1 );

for k = 1:nPartitions

    subSignal = signal( sampleID(:,k) );
    subTakeoff = takeoff( sampleID(:,k) );
    subLanding = landing( sampleID(:,k) );
    
    [ ~, kLoss(k), constraint ] = detectJumpTakeoff(  ...
                                  subSignal, ...
                                  subTakeoff, ...
                                  subLanding, ...
                                  opt );
    if constraint == 1
        obj = 0;
        return;
    end

end

obj = mean( kLoss );
constraint = -1;

end



