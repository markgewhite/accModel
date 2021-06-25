% ************************************************************************
% Function: readAccData
% Purpose:  Read and process the accelerometer data
%
%
% Parameters:
%       datapath:       file path
%       opt:            data options
%
% Output:
%       data: processed data
%
% ************************************************************************

function data = readAccData( datapath, opt )

load( fullfile(datapath, 'AccelerometerSignals') ); %#ok<LOAD>
load( fullfile(datapath, 'GRFFeatures') ); %#ok<LOAD>

data.sensors = sensorNames;
data.curves = curveNames;

for j = 1:size( signal.raw, 2 )
    
    curveType = data.curves{j};
    data.(curveType).takeoffVGRF = signal.takeoff{ j };
    data.(curveType).landingTime = curveFTSet{ j }; %#ok<USENS>
    data.(curveType).landingVGRF = fix( 0.25*data.(curveType).landingTime ) ...
                            + data.(curveType).takeoffVGRF;

    for i = 1:size( signal.raw, 1 )
        data.(curveType).signal.(data.sensors{i}) = ...
                                            signal.raw{ i, j };
    end
    
    switch opt.measure
        case 'PeakPower'
            data.(curveType).outcome = ...
                            outcomes.(curveType).peakPower;
        case 'JumpHeight'
            data.(curveType).outcome = ...
                            outcomes.(curveType).jumpHeight;
    end
    
    if opt.doBySubject
        % perform calculations (truncation, partitioning) by subject
        data.(curveType).subject = attributes.(curveType).subject;
    else
        % perform by trial by creating a new subject ID by trial
        data.(curveType).subject = 1:length( data.outcome );
    end
    
    data.(curveType).sex = categorical( attributes.(curveType).sex, ...
                        [1 2], {'Male', 'Female'} );
    
    switch curveType
        case 'all'
            data.(curveType).withArms = withArms;
        case 'noarms'
            data.(curveType).withArms = ...
                        false( length(data.(curveType).outcome), 1 );
        case 'arms'
            data.(curveType).withArms = ...
                        true( length(data.(curveType).outcome), 1 );
    end
    
    data.(curveType).perfLevel = performanceLevel( ...
                               data.(curveType).outcome, ...
                               data.(curveType).subject, ...
                               opt.nPerfLevels );
                           
    data.(curveType).isHoldout = (attributes.(curveType).dataset==2);
    
end


end