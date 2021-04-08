% ************************************************************************
% Function: detectJumpLandingTestHarness
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


function [ obj, constraint ] = detectJumpLandingTestHarness( ...
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
    opt.maxSpikeWidth = param( 1 );
    %opt.freefallThreshold = param( 1 );
    %opt.freefallRange = param( 2 );
    %opt.idxOffset = param( 1 );
    %opt.nSmooth = param( 1 );
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
    
    [ ~, ~, kLoss(k), constraint ] = detectJumpLanding(  subSignal, ...
                                  subTakeoff, ...
                                  subLanding, ...
                                  opt );
    if constraint == 1
        obj = 100;
        return;
    end
    
end

obj = mean( kLoss );
constraint = -1;

end



