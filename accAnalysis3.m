% ************************************************************************
% Script: accAnalysis2
% Purpose:  Machine learning analysis of accelerometer data
%           based on functional principal components
%
%
% ************************************************************************

clear;

% ************************************************************************
%     Setup file paths
% ************************************************************************

dataset = 'Training';

if ismac
    rootpath = '/Users/markgewhite/Google Drive/PhD/Studies/Jumps';
else
    rootpath = 'C:\Users\markg\Google Drive\PhD\Studies\Jumps';
end

switch dataset 
    case 'Training'
        setup.datapath = [ rootpath '\Data\Processed\Training' ];
    case 'Testing'
        setup.datapath = [ rootpath '\Data\Processed\Testing' ];
    case 'All'
        setup.datapath = [ rootpath '\Data\Processed\All' ];
end

if ismac
    setup.datapath = strrep( setup.datapath, '\', '/') ;
end


% ************************************************************************
%   Setup and options
% ************************************************************************

% ********** Method **********
% GridSearch - perform a grid search of 1 or 2 parameters
% smOptimiser - perform a random search with optimisation
% Fixed - evaluate a fixed model on training/validation data
% Holdout - evaluate a fixed model on holdout data
setup.method = 'GridSearch';
setup.tFreq = 0.25; % sampling frequency per unit time
setup.tNorm = 1000; % points per second
setup.tLength = 2000; % max duration in milliseconds

% fixed parameter settings
setup.sensors = 'lb';
setup.curveType = 'noarms';

setup.useResultant = true;

setup.preLength = 2900;
setup.postLength = 2900;
setup.idxLength = setup.tFreq*(setup.preLength+setup.postLength);

setup.standardize = false;
setup.basisDensity = 8/1000;
setup.basisOrderAndPenalty = '6-4';
setup.lambda = 10^(8.76);
setup.nRetainedComp = 17;


% search settings
setup.nInnerLoop = 2; % 20
setup.kInnerFolds = 2;
setup.nOuterLoop = 20; % 10
setup.kOuterFolds = 10; % 10

setup.nRepeats = 1;
setup.nFit = 20; 
setup.nSearch = 20;
setup.nInterTrace = 0.5*setup.nFit;
setup.porousness = 0.5; % 0.05;
setup.window = 2*setup.nSearch;
setup.verbose = 0;
setup.showPlots = true;


% search dimensions
setup.modelType = 'SVM-Bespoke';
%setup.activeVar = [ 16 17 22 23 27 ];
setup.activeVar = [ 9 16 17 22 23 27 ];



setup.randomSeed = 0;

options = defOptions( setup );


data = readAccData( setup.datapath, options.data );


options.optimize = defOptimiseVar( ...
                            setup, ...
                            options.data.nPredictors );
                        
options.optimize.nObs = length( data.(setup.curveType).outcome );
options.optimize.subjects = data.(setup.curveType).subject;
options.optimize.partitioning = options.part.outer;


% set the synchronisation points
[ data.noarms.landingACC, data.noarms.impactACC ] = ...
                                detectJumpLanding(  ...
                                        data.noarms.signal.lb, ...
                                        data.noarms.takeoffVGRF, ...
                                        data.noarms.landingTime, ...
                                        options.preproc.landing );
                                
data.noarms.takeoffACC = detectJumpTakeoff( ...
                                    data.noarms.signal.lb, ...
                                    data.noarms.takeoffVGRF, ...
                                    data.noarms.landingACC, ...
                                    options.preproc.takeoff );
                                

% summarise key information
disp(['Basis = ' options.gpr.basis]);
disp(['Kernel = ' options.gpr.kernel]);
disp(['Sigma = ' num2str(log10(options.gpr.sigmaN0))]);
disp(['PreTime = ' num2str(setup.preLength)]);
disp(['PostTime = ' num2str(setup.postLength)]);
disp(['nBasis = ' num2str(options.fda.nBasis)]);
disp(['Roughness = ' num2str(log10(options.fda.lambda))]);


% ------------------------------------------------------------
%  Run the model
% ------------------------------------------------------------

switch setup.method
    
    case 'GridSearch'
        outputs = gridSearch2( data, options, setup );
               
    case 'NestedSearch'
        output = smOptimiserNCV( @accModelRun, ...
                                 options.optimize.varDef, ...
                                 options.optimize, ...
                                 data.noarms, ...
                                 options );
                                     
    case 'Single'
        [ optimum, model, optOutput, srchOutput ] = smOptimiser( ...
                                            @accModelRun, ...
                                            options.optimize.varDef, ...
                                            options.optimize, ...
                                            data.noarms, ...
                                            options );
    
    case 'Fixed'
        n = length( data.outcome );
        options.part.inner = options.part.outer;
        hp = [];
        [ ~, ~, output ] = accModelRun(  ...
                                   data, ...
                                   'Repeated', ...
                                   true( n, 1 ), ...
                                   false( n, 1 ), ...
                                   options, ...
                                   hp );
                                         
    case 'Holdout'
        trnSelect = (attributes.(curveType).dataset==1);
        tstSelect = (attributes.(curveType).dataset==2);
        hp = [];
        [ ~, ~, output ] = accModelRun(  ...
                                   data, ...
                                   'Specified', ...
                                   trnSelect, ...
                                   tstSelect, ...
                                   options, ...
                                   hp );
        
end

                       




function outputs = gridSearch2( data, options, setup )

algorithms = options.optimize.varDef(4).Range;
sensors = data.sensors;
jumpTypes = data.curves;

nAlgorithms = length( algorithms );
nSensors = length( sensors );
nJumpTypes = length( jumpTypes );

outputs = cell( nAlgorithms, nSensors, nJumpTypes );

for a = 1:nAlgorithms
    
    options.model.type = algorithms{ a };
    
    switch a
        case 1
            %setup.activeVar = [ 12 16 17 21 22 23 27 ];
            %setup.activeVar = [ 16 17 22 23 27 ];
            setup.activeVar = [ 12 16 17 ];
            options.fda.basisDensity = 7/1000;
            options.fpca.nRetainedComp = 24;
            options.fda.lambda = 10^(-9.48);
        case 2
            %setup.activeVar = [ 8 9 10 11 16 17 21 22 23 27 ];
            setup.activeVar = [ 16 17 23 ];
            options.fda.basisDensity = 8/1000;
            options.fpca.nRetainedComp = 24;
        case 3
            %setup.activeVar = [ 5 6 7 16 17 21 22 23 27 ];
            %setup.activeVar = [ 16 17 21 22 23 27 ];
            setup.activeVar = [ 16 17 23 ];
            options.fda.basisDensity = 8/1000;
            options.fpca.nRetainedComp = 23;
    end
    options.optimize = defOptimiseVar( setup, options.data.nPredictors );
    options.optimize.partitioning = options.part.outer;
    
    disp('*******************************');
    disp(['Algorithm = ' options.model.type]);
    disp('*******************************');   
    
    for s = 1 %1:nSensors
        
        options.data.sensors = sensors{ s };

        disp('*******************************');
        disp(['Sensor = ' options.data.sensors]);
        disp('*******************************');

        for j = 2 %2:3
            
            subset = data.(jumpTypes{ j });
            options.optimize.nObs = length( data.(jumpTypes{j}).outcome );
            options.optimize.subjects = subset.subject;
            
            disp('*******************************');
            disp(['Jump Type = ' jumpTypes{j}]);
            disp('*******************************');
            
            outputs{a,s,j} = smOptimiserNCV( @accModelRun, ...
                                             options.optimize.varDef, ...
                                             options.optimize, ...
                                             subset, ...
                                             options );
                                         
            
            if ismac 
                save( fullfile(setup.datapath, ...
                        'smOptimiser Results (MAC).mat'), ...
                        'outputs', 'options' );
            else
                save( fullfile(setup.datapath, ...
                        'smOptimiser Results (PC).mat'), ...
                        'outputs', 'options' );
            end
                                         
        end
        
    end
    
end



end

