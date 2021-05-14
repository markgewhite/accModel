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
% RandomSearch - perform a random search with optimisation
% Fixed - evaluate a fixed model on training/validation data
% Holdout - evaluate a fixed model on holdout data
setup.method = 'smOptimiser';
setup.tFreq = 0.25; % sampling frequency per unit time
setup.tNorm = 1000; % points per second
setup.tLength = 2000; % max duration in milliseconds

setup.sensors = 'lb';
setup.curveType = 'noarms';

setup.preLength = 2000;
setup.postLength = 0;
setup.idxLength = setup.tFreq*(setup.preLength+setup.postLength);

setup.nInnerLoop = 2; % 20
setup.kInnerFolds = 2;
setup.nOuterLoop = 20; % 10
setup.kOuterFolds = 10; % 10

setup.nFit = 5; 
setup.nSearch = 5;
setup.nRepeats = 1;
setup.nInterTrace = fix( 0.5*setup.nFit );
setup.porousness = 0.05;
setup.verbose = 1;
setup.activeVar = [ 5, 6, 7, 8 ];

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
        output = gridSearch( data, options );
        
    case 'RandomSearch'
        output = randomSearch( data, options );
        
    case 'smOptimiser'
        output = smOptimiserNCV( @accModelRun, ...
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

                       


