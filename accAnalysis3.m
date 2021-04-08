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

datapath = 'data/';


% ************************************************************************
%   Read data
% ************************************************************************

load( fullfile(datapath, 'AccelerometerSignals') );
load( fullfile(datapath, 'GRFFeatures') );


% ************************************************************************
%   Constants
% ************************************************************************

sensor = 'lb';
curveType = 'noarms';
sID = find( sensor == string(sensorNames) );
cID = find( curveType == string(curveNames) );

tFreq = 0.25; % sampling frequency per unit time
tNorm = 1000; % points per second
tLength = 2000; % max duration in milliseconds

options.datapath = datapath;
options.doHyperparameterOptimisation = false;
options.doGenerateRegCurves = false;  %%% CURVE GENERATION %%%
options.curveNames = curveNames;
options.sensorNames = sensorNames;
options.seriesNames = seriesNames;


% ************************************************************************
%   Key variables
% ************************************************************************

% ********** Method **********
% GridSearch - perform a grid search of 1 or 2 parameters
% RandomSearch - perform a random search with optimisation
% Fixed - evaluate a fixed model on training/validation data
% Holdout - evaluate a fixed model on holdout data
options.method = 'Fixed';
options.optimize.doNestedSearch = true;
options.generateDistributions = true;
options.plotErrorDist = true;

options.model.type = 'GPR-Bespoke';
options.optimize.objective = 'Loss'; % LossQ4
options.nRuns = 50;
options.reportInterval = 1;

options.data.doReduceSample = false;
options.data.reducedSampleMethod = 'ReduceSubject';
options.data.reducedSize = 25; % number of subjects
options.data.reducedSamplesPerSubject = 1; % jumps per subject

options.data.jumpDetection = 'TakeoffACC'; % alignment method
options.data.doIncludeExtraJumps = true;

preLength = 1432;
postLength = 1208;
idxLength = tFreq*(preLength+postLength);

options.preproc.useResultant = true; % resultant (1D) signal?
options.preproc.doFixedSeparation = false; % fix gap between windows (flight time)?
options.preproc.doPriorRotation = false;

partitioning.method = 'MonteCarloSubject'; % LeaveOneOutSubject MonteCarloSubject
partitioning.doInversion = false;
options.doControlRandomisation = false;
options.doBySubject = true;

nInnerLoop = 10; % 20
kInnerFolds = 10;
nOuterLoop = 100; % 10
kOuterFolds = 10; % 10

options.fda.nBasis = 100; % number of bases (18) Ch5=100 Ch6=110 100
options.fda.nBasisDensity = 1/20; % bases per time unit 
options.fda.lambda = 10^(4.80); % roughness penalty (4.80)
options.fda.useDensity = false; % whether of not to use a fixed number of bases

options.fpca.doFPCApartitioning = true; % allow test data to be used for FPC calculation
options.fpca.nRetainedComp = 15; % retained components from FPCA 35
options.fpca.nRetainedCompWarp = 3; % retained components from warp
options.fpca.doVarimax = false; % varimax rotations?

options.reg.doRegistration = false;
options.reg.doInitialise = false; % one-time only
options.reg.doCalculation = false; % perform the calculation or read from file?
options.lm.setApplied = 'p1';

options.filter.method = 'All'; % type of selection 
options.filter.criterion = 'Threshold'; 
options.filter.rThreshold = 0.1; %10^(-2.81)
options.filter.maxPredictors = 30; % max predictors in 1D

options.data.doMultiCurves = false;
options.data.curves = 'ACC+AD1+AD2+VEL+DIS+PWR';


strategy = input('Strategy (B/R/S) = ', 's');
switch upper(strategy)

    case 'B'
        options.sampling.doSignalBased = false;
        options.sampling.doFeatureBased = false;
        colour = 'k';
        strategy = 'Baseline';
    
    case 'R'
        options.sampling.doSignalBased = true;
        options.sampling.doFeatureBased = false;
        colour = 'r';
        strategy = 'Rotations';

    case 'S'
        options.sampling.doSignalBased = false;
        options.sampling.doFeatureBased = true;
        colour = 'b';
        strategy = 'SMOTER';
      
end

options.sampling.over = input('Oversampling Ratio = '); % multiple of cases to add
options.sampling.under = input('Undersampling Ratio = '); % proportion of cases to remove
options.sampling.nWeightings = input('nWeighting = ');
options.sampling.knn = 8; % number of nearest neighbours
options.sampling.nFPC = 6; % number of FPCs for nearest neighbours
options.sampling.angSD = 20;
options.sampling.axisR = 1;
options.sampling.doGlobal = false;

fig = input('Figure = ');
showPoints = input('Show Points = ');



randomSeed = 0;

nPredictors = options.fpca.nRetainedComp* ...
                (1 + ~options.preproc.useResultant*2)* ...
    (1 + options.data.doMultiCurves*((length(options.data.curves)+1)/4-1));
disp(['nPredictors = ' num2str(nPredictors)]);


% ************************************************************************
%   Model Hyperparameters
% ************************************************************************

options.gpr.basis = 'None'; % None
options.gpr.kernel = 'Exponential'; % SquaredExponential
options.gpr.sigmaN0 = 10^(-2.20); % noise standard deviation (-2.20)
options.gpr.standardize = false; % false for Ch. 5
options.gpr.constSigma = true;
options.gpr.sigmaMin = 1E-4; % 1E-2 for over-sampling
options.gpr.sigmaMax = 20;
options.gpr.lengthScaling = false;

options.svm.kernel = 'Polynomial';
options.svm.boxConstraint = 10^(6.59); % 2.57E-2; % 10^0.524;
options.svm.kernelScale = 10^(3.52); % 3.79E-2; % 10^0.416;
options.svm.epsilon = 10^(-1.63); % 7.53E-1; % 10^-0.820;
options.svm.standardize = false;

options.lr.lambdaLR = 10^(-6.48);
options.lr.regularization = 'ridge';
options.lr.learner = 'leastsquares';

disp(['Basis = ' options.gpr.basis]);
disp(['Kernel = ' options.gpr.kernel]);
disp(['Sigma = ' num2str(log10(options.gpr.sigmaN0))]);
disp(['PreTime = ' num2str(preLength)]);
disp(['PostTime = ' num2str(postLength)]);
disp(['nBasis = ' num2str(options.fda.nBasis)]);
disp(['Roughness = ' num2str(log10(options.fda.lambda))]);


% ************************************************************************
%   Selected Predictors
% ************************************************************************

predNames = tblFieldNames( nPredictors, {'fpc'} );

predSelection = true( 1, nPredictors );
% SELECTION FROM 7-019 FOR 3D SIGNAL:
%predSelection = [ 1 1 1 1 1 1 1 1 1 1 1 0 1 0 0 ];
% SELECTION FROM 7-019 FOR 3D SIGNAL:
%predSelection = [ 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ...
%                  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ...
%                  1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
% SELECTION FROM 7-026 FOR 1D-MULTI CURVE SIGNAL:
%predSelection = [ 1 1 1 1 1  1 1 1 0 1  0 0 0 0 0 ...
%                  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0 ...
%                  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0 ...
%                  1 1 0 1 0  0 0 0 0 0  0 0 0 0 0 ...
%                  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0 ...
%                  1 1 1 0 1  0 0 0 0 1  0 0 0 0 0 ];

predTable = array2table( predSelection );
predTable.Properties.VariableNames = predNames;

options.predictor = table2struct( predTable );

% ************************************************************************
%   Optimization variables
% ************************************************************************

options.optimize.percentLoss = false;
options.optimize.objectiveDescr = 'SM Prediction (W\cdotkg^{-1})'; %'Loss CV (Inner Fold)';
options.optimize.doSMValidation = false;
options.optimize.SMFile = 'ID-5-029 SVM Opt 2000.mat';
options.optimize.randomSearchUpdate = 20;
options.optimize.doConvergence = false;
options.optimize.nRamp = options.nRuns;
options.optimize.allGranular = false;
options.optimize.dotUpdate = 1;
options.optimize.maxObjEval1 = 50;
options.optimize.maxObjEval2 = 0;
options.optimize.initMaxLoss = 20; % 10 
options.optimize.maxTries = 100;
options.optimize.explore1 = 0.5; % 2
options.optimize.explore2 = 1;
options.optimize.plotFcn = []; %{@plotObjectiveModel, @plotMinObjective};
options.optimize.verbose = 1;
options.optimize.setInitial = false;
options.optimize.plotType = 'Line'; % None
options.optimize.doGPfit = false;
options.optimize.doPlotPoints = false;
options.optimize.doDiscretePoints = true;
options.optimize.doSigmoid = false;
options.optimize.doPlotConfidence = true;
options.optimize.doAddCI2Legend = true;
options.optimize.overlapFactor = 0.50;
options.optimize.varJoint = false;
options.optimize.lossLim = [2 8];
options.optimize.contourStep = 0.2;
options.optimize.lossFormat = '%.1f';
options.optimize.avgWindow = 10;
options.optimize.doMultipleFigures = false;
options.optimize.subsamplingMethod = 'KFold';

options.optimize.tolPSO = 0.01;
options.optimize.tolFMin = 0.001;
options.optimize.maxIter = 10000;

% files
options.optimize.file.doRetrieval = false;
options.optimize.file.reg = 'RegReference';
options.optimize.file.regVar = [ ];

% active parameters
options.optimize.activeVar = [ 35 37 38 42 43 ]; %[ 40:39+nPredictors ];

% data filtering
i = 1;
options.optimize.grp(i) = "data";
options.optimize.var(i) = "arms";
options.optimize.descr(i) = "Jump Type";
options.optimize.lim{i} = [];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = { 'Both', 'No Arms', 'With Arms' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "data";
options.optimize.var(i) = "sex";
options.optimize.descr(i) = "Sex";
options.optimize.lim{i} = [];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = { 'All', 'Male', 'Female' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "data";
options.optimize.var(i) = "perfLevel";
options.optimize.descr(i) = "Performance Level";
options.optimize.lim{i} = [];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = { 'All', 'Low', 'Intermediate', 'High' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );   
    
% algorithm parameter
i = 4;
options.optimize.grp(i) = "model";
options.optimize.var(i) = "type";
options.optimize.descr(i) = "Algorithm";
options.optimize.lim{i} = [];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
%options.optimize.fcn{i} = { 'LR', 'LR-RDG', 'LR-LSS', ...
%                            'SVM-L', 'SVM-G', ...
%                            'GPR-SE', 'GPR-M52', ...
%                            'NN-5', 'NN-10', ...
%                            'TR-ENS' };
options.optimize.fcn{i} = { 'LR-Bespoke', 'GPR-Bespoke' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
 
% GPR parameters
i = 5;
options.optimize.grp(i) = "gpr";
options.optimize.var(i) = "basis";
options.optimize.descr(i) = "GPR Basis Function";
options.optimize.lim{i} = [0.5 4.5];
options.optimize.bounds{i} = [0.5 4.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = { 'None', 'Constant', 'Linear', 'PureQuadratic' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "gpr";
options.optimize.var(i) = "kernel";
options.optimize.descr(i) = "GPR Kernel Function";
options.optimize.lim{i} = [0.5 5.5];
options.optimize.bounds{i} = [0.5 5.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = { 'SquaredExponential', 'Exponential', ...
                            'Matern32', 'Matern52', 'RationalQuadratic' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "gpr";
options.optimize.var(i) = "sigmaN0";
options.optimize.descr(i) = "\it\sigma_{N}";
options.optimize.lim{i} = [-4 2];
options.optimize.bounds{i} = [-4 2];
options.optimize.isLog(i) = true;
options.optimize.isCat(i) = false;
%options.optimize.fcn{i} = 10.^(-3.0:0.1:2.0);
%options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
%        [1, 51], 'Type', 'integer', ...
%        'Optimize', ismember( i, options.optimize.activeVar ) );
options.optimize.fcn{i} = @(x) 10^x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [-4 2], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    

i = i+1;
options.optimize.grp(i) = "gpr";
options.optimize.var(i) = "standardize";
options.optimize.descr(i) = "Standardise";
options.optimize.lim{i} = [0.5 2.5];
options.optimize.bounds{i} = [0.50 2.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = [false true];
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1 2], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
% SVM parameters
i = 9;
options.optimize.grp(i) = "svm";
options.optimize.var(i) = "kernel";
options.optimize.descr(i) = "SVM Kernel Function";
options.optimize.lim{i} = [0.5 3.5];
options.optimize.bounds{i} = [0.50 3.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = {'Linear', 'Gaussian', 'Polynomial'};
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "svm";
options.optimize.var(i) = "boxConstraint";
options.optimize.descr(i) = "Box Constraint";
options.optimize.lim{i} = [-6 8];
options.optimize.bounds{i} = [-6 8];
options.optimize.isLog(i) = true;
options.optimize.isCat(i) = false;
%options.optimize.fcn{i} = 10.^(-2.0:0.25:3.0);
%options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
%        [1 21], 'Type', 'integer', ...
%        'Optimize', ismember( i, options.optimize.activeVar ) );
options.optimize.fcn{i} = @(x) 10^x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [-6 8], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "svm";
options.optimize.var(i) = "kernelScale";
options.optimize.descr(i) = "Kernel Scale";
options.optimize.lim{i} = [-6 8];
options.optimize.bounds{i} = [-6 8];
options.optimize.isLog(i) = true;
options.optimize.isCat(i) = false;
%options.optimize.fcn{i} = 10.^(-2.0:0.25:3.0);
%options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
%        [1 21], 'Type', 'integer', ...
%        'Optimize', ismember( i, options.optimize.activeVar ) );
options.optimize.fcn{i} = @(x) 10^x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [-6 8], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "svm";
options.optimize.var(i) = "epsilon";
options.optimize.descr(i) = "\epsilon";
options.optimize.lim{i} = [-4 3];
options.optimize.bounds{i} = [-4 3];
options.optimize.isLog(i) = true;
options.optimize.isCat(i) = false;
%options.optimize.fcn{i} = 10.^(-2.0:0.1:2.0);
%options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
%        [1 41], 'Type', 'integer', ...
%        'Optimize', ismember( i, options.optimize.activeVar ) ); % PP IQR = 12.7 
options.optimize.fcn{i} = @(x) 10^x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [-4 3], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "svm";
options.optimize.var(i) = "standardize";
options.optimize.descr(i) = "Standardise";
options.optimize.lim{i} = [0.5 2.5];
options.optimize.bounds{i} = [0.50 2.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = [false true];
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 2], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
% LR parameters
i = 14;
options.optimize.grp(i) = "lr";
options.optimize.var(i) = "lambdaLR";
options.optimize.descr(i) = "LR Lambda";
options.optimize.lim{i} = [-12 12];
options.optimize.bounds{i} = [-12 12];
options.optimize.isLog(i) = true;
options.optimize.isCat(i) = false;
%options.optimize.fcn{i} = 10.^(-5.0:0.1:5.0);
%options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
%        [1 101], 'Type', 'integer', ...
%        'Optimize', ismember( i, options.optimize.activeVar ) );
options.optimize.fcn{i} = @(x) 10^x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [-12 12], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

    
    
i = i+1;
options.optimize.grp(i) = "lr";
options.optimize.var(i) = "regularization";
options.optimize.descr(i) = "Regularisation Method";
options.optimize.lim{i} = [0.5 2.5];
options.optimize.bounds{i} = [0.5 2.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = {'lasso', 'ridge'};
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "lr";
options.optimize.var(i) = "learner";
options.optimize.descr(i) = "LR Solver";
options.optimize.lim{i} = [0.5 2.5];
options.optimize.bounds{i} = [0.5 2.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = {'svm', 'leastsquares'};
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

    
% time window parameters
i = 17;
options.optimize.grp(i) = "preproc";
options.optimize.var(i) = "tLength1";
options.optimize.descr(i) = "\it t_{\rmpre} \rm(ms)";
options.optimize.lim{i} = [0, 3000];
options.optimize.bounds{i} = [1 801];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = (-200:4:3000);
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1 801], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "preproc";
options.optimize.var(i) = "tLength2";
options.optimize.descr(i) = "\it t_{\rmpost} \rm(ms)";
options.optimize.lim{i} = [0, 3000];
options.optimize.bounds{i} = [1 801];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = (-200:4:3000);
%options.optimize.fcn{i} = (0:20:2000);
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1 801], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "preproc";
options.optimize.var(i) = "doFixedSeparation";
options.optimize.descr(i) = "Fixed Flight Time";
options.optimize.lim{i} = [];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = [false true];
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 2], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "data";
options.optimize.var(i) = "syncNoiseSD";
options.optimize.descr(i) = "Synchronisation Noise SD (ms)";
options.optimize.lim{i} = [0 100];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = (0:4:100);
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 26], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "data";
options.optimize.var(i) = "jumpDetection";
options.optimize.descr(i) = "Alignment";
options.optimize.lim{i} = [0.5 3.5];
options.optimize.bounds{i} = [0.5 3.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
%options.optimize.fcn{i} = { 'TakeoffACC', 'LandingACC', 'ImpactACC' };
options.optimize.fcn{i} = { 'TakeoffVGRF', 'TakeoffACC' };
%options.optimize.fcn{i} = {'TakeoffACC', ...
%                            'LandingACC', ...
%                            'ImpactACC', 'Power1ACC', 'Power2ACC' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );


% smoothing parameters
i = 22;
options.optimize.grp(i) = "fda";
options.optimize.var(i) = "nBasisDensity";
options.optimize.descr(i) = "Basis Function Density / Data Point";
options.optimize.lim{i} = [-3 -1];
options.optimize.bounds{i} = [-3 -1];
options.optimize.isLog(i) = true;
options.optimize.isCat(i) = false;
%options.optimize.fcn{i} = [ 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 40, ...
%                                 45, 50, 55, 60, 70, 80, 100, 125, 150 ]/1000;
%options.optimize.fcn{i} = 0.005:0.005:0.60;
%options.optimize.fcn{i} = (1:250)/1000;
%options.optimize.fcn{i} = 1./[ 60 30 20 15 12 10 6 5 4 3 2 1 ]; 
options.optimize.fcn{i} = @(x) 10^x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [-3 -1], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "fda";
options.optimize.var(i) = "nBasis";
options.optimize.descr(i) = "No. Basis Functions";
options.optimize.lim{i} = [15, 200];
options.optimize.bounds{i} = [15 200];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [15 200], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
    
i = i+1;
options.optimize.grp(i) = "fda";
options.optimize.var(i) = "lambda";
options.optimize.descr(i) = "log_{10}\it\lambda\rm";
options.optimize.init{i} = 6;
options.optimize.lim{i} = [0 12];
options.optimize.bounds{i} = [0 12];
options.optimize.isLog(i) = true;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) 10^x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [0 12], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
%options.optimize.lim{i} = [0, 10];
%options.optimize.bounds{i} = [1 51];
%options.optimize.isLog(i) = true;
%options.optimize.isCat(i) = false;
%options.optimize.fcn{i} = 10.^(-12:1:12);
%options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
%        [1 25], 'Type', 'integer', ...
%        'Optimize', ismember( i, options.optimize.activeVar ) );
    
    
% registration parameters
i = 25;
options.optimize.grp(i) = "lm";
options.optimize.var(i) = "setApplied";
options.optimize.descr(i) = "Registration Landmark Sets";
options.optimize.lim{i} = [0.5 4.5];
options.optimize.bounds{i} = [0.5 4.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = { 'none', 'p1', 'p2', 'p1p2' };
%options.optimize.fcn{i} = { 'none', 'setA' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "reg";
options.optimize.var(i) = "wLambda";    
options.optimize.descr(i) = "log_{10}(\it\lambda_{\rmWarp})\rm";
options.optimize.lim{i} = [1, 5];
options.optimize.bounds{i} = [0.5 5.49];
options.optimize.isLog(i) = true;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = [ 1E0 1E2 1E4 1E6 1E8 ]; % missing 1E4
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 5], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "fpca";
options.optimize.var(i) = "nRetainedCompWarp";
options.optimize.descr(i) = "Number of Retained Warp FPCs";
options.optimize.lim{i} = [0, 5];
options.optimize.bounds{i} = [0.5 5.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
ptions.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 5], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

% FPCA parameters
i = 28;
options.optimize.grp(i) = "fpca";
options.optimize.var(i) = "nRetainedComp";
options.optimize.descr(i) = "Number of Retained FPCs";
options.optimize.lim{i} = [0, 30];
options.optimize.bounds{i} = [0.5 30.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 30], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;    
options.optimize.grp(i) = "fpca";
options.optimize.var(i) = "doVarimax";
options.optimize.descr(i) = "Perform Varimax?";
options.optimize.lim{i} = [0.5 2.5];
options.optimize.bounds{i} = [0.5 2.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = [ false true ];
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 2], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar )  );

% feature selection parameters
i = 30;
options.optimize.grp(i) = "filter";
options.optimize.var(i) = "rThreshold";
options.optimize.descr(i) = "Predictor Selection Threshold for correlation, \it r";
options.optimize.lim{i} = [-4, 0];
options.optimize.bounds{i} = [-4.0 -0.5];
options.optimize.isLog(i) = true;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) 10^x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [-4.0, -0.5], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "filter";
options.optimize.var(i) = "maxPredictors";
options.optimize.descr(i) = "Number of Retained Predictors";
options.optimize.lim{i} = [0, 30];
options.optimize.bounds{i} = [0.5 30.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 30], 'Type', 'integer',  ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "preproc";
options.optimize.var(i) = "doPriorRotation";
options.optimize.descr(i) = "Signal Orientation Correction";
options.optimize.lim{i} = [0.5 2.5];
options.optimize.bounds{i} = [0.5 2.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = [ false true ];
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 2], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar )  );

    
% sample size reduction parameters
i = 33;
options.optimize.grp(i) = "data";
options.optimize.var(i) = "reducedSize";
options.optimize.descr(i) = "Sample Size (Subjects)";
options.optimize.lim{i} = [1, 100];
options.optimize.bounds{i} = [0.5 60.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 60], 'Type', 'integer',  ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "data";
options.optimize.var(i) = "reducedSamplesPerSubject";
options.optimize.descr(i) = "Jumps per Participant";
options.optimize.lim{i} = [1, 4];
options.optimize.bounds{i} = [0.5 4.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 4], 'Type', 'integer',  ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

% data augmentation parameters
i = 35;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "nWeightings";
options.optimize.descr(i) = "Number of Weightings";
options.optimize.lim{i} = [0, 15];
options.optimize.bounds{i} = [-0.49 15.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [0, 15], 'Type', 'integer',  ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "threshold";
options.optimize.descr(i) = "Case Selection Threshold";
options.optimize.lim{i} = [0 0.9];
options.optimize.bounds{i} = [0 0.9];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [0, 0.9], 'Type', 'real',  ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "over";
options.optimize.descr(i) = "Over-sampling Ratio";
options.optimize.lim{i} = [0, 5];
options.optimize.bounds{i} = [0 5];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [0, 5], 'Type', 'real',  ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "under";
options.optimize.descr(i) = "Under-sampling Ratio";
options.optimize.lim{i} = [0, 0.9];
options.optimize.bounds{i} = [0 0.9];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [0 0.9], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

% over-sampling rotation method
i = 39;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "angSD";
options.optimize.descr(i) = strcat("Random Rotation SD (", char(176), ")");
options.optimize.lim{i} = [0 30];
options.optimize.bounds{i} = [0 30];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [0 30], 'Type', 'real', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );
  
i = i+1;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "axisR";
options.optimize.descr(i) = "Rotation Axis";
options.optimize.lim{i} = [0.5 3.5];
options.optimize.bounds{i} = [0.5 3.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1 3], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "doGlobal";
options.optimize.descr(i) = "Use Global Reference Frame?";
options.optimize.lim{i} = [0.5 2.5];
options.optimize.bounds{i} = [0.5 2.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = [ false true ];
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1, 2], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar )  );    
    
% over-sampling SMOTER method
i = 42;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "knn";
options.optimize.descr(i) = "SMOTER Nearest Neighbours";
options.optimize.lim{i} = [0, 10];
options.optimize.bounds{i} = [0.5 10.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1 10], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );   
    
i = i+1;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "nFPC";
options.optimize.descr(i) = "No. FPCs for Nearest Neighbours";
options.optimize.lim{i} = [0, 15];
options.optimize.bounds{i} = [0.5 15.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = @(x) x;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        [1 15], 'Type', 'integer', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );   
   
i = i+1;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "interpolation";
options.optimize.descr(i) = "Interpolation Distribution";
options.optimize.lim{i} = [0.5 2.5];
options.optimize.bounds{i} = [0.5 2.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = { 'Uniform', 'Normal' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

i = i+1;
options.optimize.grp(i) = "sampling";
options.optimize.var(i) = "estimation";
options.optimize.descr(i) = "Outcome Estimation Method";
options.optimize.lim{i} = [0.5 2.5];
options.optimize.bounds{i} = [0.5 2.49];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = true;
options.optimize.fcn{i} = { 'Linear', 'Gaussian Process' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );    

% sensor selection parameter
i = 46;
options.data.sensorCodes = { 'LB', 'UB', 'LS', 'RS' };
options.optimize.grp(i) = "data";
options.optimize.var(i) = "sensors";
options.optimize.descr(i) = "Accelerometer attachment site";
options.optimize.lim{i} = [];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = options.data.sensorCodes;
%options.optimize.fcn{i} = { 'LB', 'UB', 'LS', 'RS', 'LB+UB', 'LB+LS', ...
%                             'LB+RS', 'UB+LS', 'UB+RS' };
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
        options.optimize.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, options.optimize.activeVar ) );

% multi-curve selection parameter
curveCodes = { 'ACC', 'AD1', 'AD2', 'VEL', 'DIS', 'PWR' };
curveOptions = cell( 1, 2^length(curveCodes)-1 );
for j = 1:2^length(curveCodes)-1
    c = find( fliplr(de2bi(j)') );
    curveOptions(j) = curveCodes( c(1) );
    for k = 2:length(c)
        curveOptions(j) = strcat( curveOptions(j), '+', curveCodes(c(k)) );
    end
end
i = 47;
curveOptions = cellstr( curveOptions );
options.data.curveCodes = curveCodes;
options.optimize.grp(i) = "data";
options.optimize.var(i) = "curves";
options.optimize.descr(i) = "Computed Curves Included";
options.optimize.lim{i} = [];
options.optimize.isLog(i) = false;
options.optimize.isCat(i) = false;
options.optimize.fcn{i} = curveOptions;
options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
            options.optimize.fcn{i}, 'Type', 'categorical', ...
            'Optimize', ismember( i, options.optimize.activeVar ) );

        
% predictor selection parameters as binary switches
for j = 1:nPredictors
    i = 47+j;
    options.optimize.grp(i) = "predictor";
    options.optimize.var(i) = "fpc"+num2str(j,'%03d');
    options.optimize.descr(i) = "FPC "+num2str(j,'%03d');
    options.optimize.lim{i} = [0.5 2.5];
    options.optimize.bounds{i} = [0.5 2.49];
    options.optimize.isLog(i) = false;
    options.optimize.isCat(i) = true;
    options.optimize.fcn{i} = [ false true ];
    options.optimize.varDef(i) = optimizableVariable( options.optimize.var(i), ...
                [1, 2], 'Type', 'integer', ...
                'Optimize', ismember( i, options.optimize.activeVar ) );
end


% ************************************************************************
%   Options
% ************************************************************************

options.data.cID = cID; % 1 = All jumps; 2 = Jumps WOA; 3 = Jumps WA
options.data.sID = sID; % 1 = LB, 2 = UB, 3 = LS, 4 = RS
options.data.arms = options.optimize.fcn{1}{cID};
options.data.sensors = options.data.sensorCodes{ options.data.sID };
options.data.filterInAdvance = false; % filters for sex and perfLevel (don't use for arms)
options.data.sex = 'All';
options.data.perfLevel = 'All';
options.data.measure = 'PeakPower';
options.data.nPerfLevels = 3;

options.data.doControlRandomisation = options.doControlRandomisation;
options.data.randomSeed = randomSeed;

options.data.testJumpDetection = 'None'; % test harness to use
options.data.syncNoiseSD = 0; 

options.data.doUseAccData = true; % whether to use ACC data (or VGRF)
options.data.weighting = false;
options.data.doCustomStandardization = false;
options.data.doIncludeAttributes = false;
options.data.sensorNames = sensorNames;
options.data.seriesNames = seriesNames;

options.preproc.tFreq = tFreq; % sampling frequency
options.preproc.tLength1 = preLength; % time window before take-off
options.preproc.tLength2 = postLength; % time window after take-off
options.preproc.maxLength = tFreq*(preLength+postLength)+1; % max number of points
options.preproc.maxLength1 = tFreq*preLength+1; % max number of points
options.preproc.maxLength2 = tFreq*postLength+1; % max number of points

options.preproc.fixedSeparation = 250; % fixed separation if required
options.preproc.do3dTransform = false;
options.preproc.transformFunction = @cart2pol;
options.preproc.doDiscontinuityCorrection = false;
options.preproc.initOrientation = [ -1 0 0 ];
options.preproc.doRandomRotation = false;
options.preproc.doRandomDimension = 2;
options.preproc.angleSD = 15*pi/180;

options.preproc.landing.maxSpikeWidth = 30;
options.preproc.landing.freefallThreshold = 1.00; % (g) limit for freefall
options.preproc.landing.freefallRange = 65; % 112 period for calculating freefall acc
options.preproc.landing.idxOffset = -10; % -23 bias
options.preproc.landing.nSmooth = 5; % moving average window (x*2+1)

options.preproc.takeoff.idxMaxDivergence = 85;
options.preproc.takeoff.idxOffset = -1; % bias
options.preproc.takeoff.nSmooth = 10; % moving average window (x*2+1)
options.preproc.takeoff.initOrientation = options.preproc.initOrientation;
options.preproc.takeoff.doReorientation = true;

options.fpca.doCentreFunctions = true; % does FPC1 exclude the mean?
options.fpca.doShowComponents = false;
options.fpca.doFPCApartitioningComparison = false;
options.fpca.doPlotComponents = false;

options.fda.basisOrder = 4; % 4th order for a basis expansion of cubic splines
options.fda.penaltyOrder = 2; % roughness penalty

options.reg.filename = fullfile(datapath, 'ACCRegistration-JumpDetection6');
options.reg.nBasis = 15; % number of bases for temporal function
options.reg.basisOrder = 1; 
options.reg.wLambda = 1E6; % roughness penalty for temporal function
options.reg.yLambda = 1E4; % roughness penalty to prevent wiggles in y
options.reg.lambdaIdxFcn = @(x) 5*round(log10(x),1)+1; % 5 for 0.2 increment
options.reg.nLambda = 51;
options.reg.nWLambda = 51;
options.reg.calcCurves = cID;
options.reg.calcSensors = 1;
options.reg.calcLM = 2:4; % specified sets below
options.reg.calcLambda = 0:0.2:10; %0:1:8;
options.reg.calcWLambda = 6;

options.lm.nBasis = 50; % number of bases for landmark search
options.lm.lambda = 1E4; % heavily smoothed for landmark search
options.lm.basisOrder = options.fda.basisOrder; % same as above
options.lm.penaltyOrder = options.fda.penaltyOrder;
options.lm.doCurvePlots = false; % display plots for checks
options.lm.doFixedReference = false;
options.lm.fixedReference = [ 180, 610 ]; % [ 180, 520, 610 ];
options.lm.sets = { 'none', 'p1', 'p2', 'p1p2', 'p1d1p2', 'top2', 'ldp2', 'd1p2' };

options.lm.none.pwrMax1 = false;
options.lm.none.takeoff = false;
options.lm.none.landing = false;
options.lm.none.accd1Max = false;
options.lm.none.pwrMax2 = false;

options.lm.p1.pwrMax1 = true;
options.lm.p1.takeoff = false;
options.lm.p1.landing = false;
options.lm.p1.accd1Max = false;
options.lm.p1.pwrMax2 = false;

options.lm.p2.pwrMax1 = false;
options.lm.p2.takeoff = false;
options.lm.p2.landing = false;
options.lm.p2.accd1Max = false;
options.lm.p2.pwrMax2 = true;

options.lm.p1p2.pwrMax1 = true;
options.lm.p1p2.takeoff = false;
options.lm.p1p2.landing = false;
options.lm.p1p2.accd1Max = false;
options.lm.p1p2.pwrMax2 = true;

options.lm.p1d1p2.pwrMax1 = true;
options.lm.p1d1p2.takeoff = false;
options.lm.p1d1p2.landing = false;
options.lm.p1d1p2.accd1Max = true;
options.lm.p1d1p2.pwrMax2 = true;

options.lm.top2.pwrMax1 = false;
options.lm.top2.takeoff = true;
options.lm.top2.landing = false;
options.lm.top2.accd1Max = false;
options.lm.top2.pwrMax2 = true;

options.lm.ldp2.pwrMax1 = false;
options.lm.ldp2.takeoff = false;
options.lm.ldp2.landing = true;
options.lm.ldp2.accd1Max = false;
options.lm.ldp2.pwrMax2 = true;

options.lm.d1p2.pwrMax1 = false;
options.lm.d1p2.takeoff = false;
options.lm.d1p2.landing = false;
options.lm.d1p2.accd1Max = true;
options.lm.d1p2.pwrMax2 = true;

options.truncation.doControlRandomisation = options.doControlRandomisation;
options.truncation.nTrialsPerSubject = 4; % number of jumps to retain per subject
options.truncation.doRandomiseSubjects = true; 
options.truncation.nSubjectsRequired = 55; % number of subjects to retain
options.truncation.nSubjectsTrueResponse = 30; % number of subjects with true response
options.truncation.doAddNoise = false; % whether to add to response for some subjects
options.truncation.noiseSD = 0.5; % standard deviation of noise for response
options.truncation.var = 'nSubjectsRequired';
options.truncation.values = 25:10:55;

partitioning.doControlRandomisation = options.doControlRandomisation;
partitioning.randomSeed = randomSeed;
partitioning.iterations = 1;
partitioning.kFolds = 10;
partitioning.split = [ 0.70, 0.0, 0.30 ];
partitioning.trainSubset = 'Full';
partitioning.testSubset = 'Full';

options.part.inner = partitioning;
options.part.inner.iterations = nInnerLoop;
options.part.inner.kFolds = kInnerFolds;

options.part.select = partitioning;
options.part.select.method = 'KFoldSubject';
options.part.select.iterations = nOuterLoop;
options.part.select.kFolds = kOuterFolds;

options.part.outer = partitioning;
options.part.outer.iterations = nOuterLoop;
options.part.outer.kFolds = kOuterFolds;

options.filter.kID = 1;
options.filter.jID = 1;
options.filter.doControlRandomisation = options.doControlRandomisation;
options.filter.lengthScaleThreshold = 1E2; % 1E3
options.filter.doInterleave = true; % interleave
options.filter.maxPredictors = 1; % max predictors in 1D
options.filter.var = 'MaxPredictors';
options.filter.values = 10;
options.filter.dim = 7; %0b111; % in binary the dimensions to include
options.filter.sensors = 1; %2:2^4-1; % list of sensors for predictors
options.filter.series = 15; %1:2^6-1;

options.reduce.method = 'None';
options.reduce.nRetainedCompPCA = 3;

options.sampling.doControlRandomisation = options.doControlRandomisation;
options.sampling.showDistribution = false;
options.sampling.caseSelection = 'Probability';
options.sampling.threshold = 0.3; % proportion of max weight above which cases may be removed

options.sampling.distFunction = 'Kernel';
options.sampling.topend = false;
options.sampling.distanceMetric = 'Euclidean'; 
options.sampling.interpolation = 'Uniform'; % for over-sampling
options.sampling.estimation = 'Linear'; % GP model estimation

options.plot.doShowPerformance = false;
options.plot.doShowPartPerf = false;
options.plot.performanceType = 'Residuals';
options.plot.doShowModelError = false;
options.plot.doShowLengthScaling = true;
options.plot.doShowFitPanel = false;
options.plot.doShowModelVariance = false;

options.plot.full.font = 'Times New Roman';
options.plot.full.fontSize = 16;
options.plot.full.xLabelRotation = 0;
options.plot.full.axisLineWidth = 1;
options.plot.full.lineWidth = 1.5;
options.plot.full.box = false;
options.plot.full.tickDirection = 'Out';
options.plot.full.doPlotPoints = options.optimize.doPlotPoints;

options.plot.sub.font = 'Times New Roman';
options.plot.sub.fontSize = 24;
options.plot.sub.xLabelRotation = 0;
options.plot.sub.axisLineWidth = 1;
options.plot.sub.lineWidth = 1;
options.plot.sub.box = false;
options.plot.sub.tickDirection = 'Out';
options.plot.sub.tickLength = [0.025, 0.025];

options.plot.mini.font = 'Times New Roman';
options.plot.mini.fontSize = 36;
options.plot.mini.xLabelRotation = 0;
options.plot.mini.axisLineWidth = 2.5;
options.plot.mini.lineWidth = 2.5;
options.plot.mini.box = false;
options.plot.mini.tickDirection = 'Out';
options.plot.mini.doPlotPoints = options.optimize.doPlotPoints;
   
       
% ------------------------------------------------------------
%   Construct the data structure for the model
% ------------------------------------------------------------

data.signal = signal.raw( :, cID );
data.takeoff = signal.takeoff{ cID };
data.landing = curveFTSet{ cID };

switch options.data.testJumpDetection

    case 'Takeoff'
        % test the settings for takeoff detections
        data.landingACC = detectJumpLanding(  data.signal{1}, ...
                                    data.takeoff, data.landing, ...
                                    options.preproc.landing );
        detectJumpTakeoffOptimiser( data.signal{1}, ...
                            data.takeoff, ...
                            data.landingACC, ...
                            options.preproc.takeoff );
    
    case 'Landing'
        % test the settings for landing detection
        detectJumpLandingOptimiser( data.signal{1}, ...
                            data.takeoff, ...
                            data.landing, ...
                            options.preproc.landing );
                        
end


% set the synchronisation points
data.takeoffVGRF = data.takeoff;
data.landingVGRF = fix(0.25*data.landing)+data.takeoff;

[ data.landingACC, data.impactACC ] = detectJumpLanding(  data.signal{1}, ...
                                    data.takeoff, data.landing, ...
                                    options.preproc.landing );
data.takeoffACC = detectJumpTakeoff( data.signal{1}, ...
                                    data.takeoff, ...
                                    data.landingACC, ...
                                    options.preproc.takeoff );
                                

if options.preproc.useResultant
    % convert the signals to resultants
    for i = 1:length( data.signal )
        for j = 1:length( data.signal{i} )
            data.signal{ i }{ j } = sqrt( sum(data.signal{i}{j}.^2, 2) );
        end
    end
end

switch options.data.measure
    case 'PeakPower'
        data.outcome = outcomes.(curveType).peakPower( :, 1 );
    case 'JumpHeight'
        data.outcome = outcomes.(curveType).jumpHeight( :, 1 );
    case 'JumpType'
        data.outcome = outcomes.(curveType).withArms;
end        

if options.doBySubject
    % perform calculations (truncation, partitioning) by subject
    data.subject = attributes.(curveType).subject;
else
    % perform by trial by creating a new subject ID by trial
    data.subject = 1:length( data.outcome );
end

data.sex = categorical( attributes.(curveType).sex, ...
                        [1 2], {'Male', 'Female'} );
                    
switch curveType
    case 'all'
        data.withArms = withArms;
    case 'noarms'
        data.withArms = false( length(data.outcome), 1 );
    case 'arms'
        data.withArms = true( length(data.outcome), 1 );
end

data.perfLevel = performanceLevel( data.outcome, ...
                                   data.subject, ...
                                   options.data.nPerfLevels );

if options.doGenerateRegCurves
    generateRegCurves( data, options );
    return;
end

% retrieve the previously computed FPCA FD objects
if options.reg.doRegistration && ~options.reg.doCalculation
    load( options.reg.filename );
    data.fdXReg = fdXReg;
    data.fdWReg = fdWReg;
end


% ------------------------------------------------------------
%   Apply Filters
% ------------------------------------------------------------

if options.data.filterInAdvance
    filter = dataFilter( data, options.data );
    
    for i = 1:length( data.signal )
        data.signal{i} = data.signal{i}( filter );
    end
    data.takeoff = data.takeoff( filter );
    data.landing = data.landing( filter );
    data.takeoffVGRF = data.takeoffVGRF( filter );
    data.landingVGRF = data.landingVGRF( filter );   
    data.takeoffACC = data.takeoffACC( filter );   
    data.landingACC = data.landingACC( filter );   
    data.outcome = data.outcome( filter );
    data.subject = data.subject( filter );
    data.sex = data.sex( filter );
    data.withArms = data.withArms( filter );
    data.perfLevel = data.perfLevel( filter );
    
end


% ------------------------------------------------------------
%  Run the model
% ------------------------------------------------------------

switch options.method
    
    case 'GridSearch'
        output = gridSearch( data, options );
        
    case 'RandomSearch'
        output = randomSearch( data, options );
    
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


if options.generateDistributions
    % generate distributions
    [ Xp, Yp, Ep ] = outputDistributions( output );
end

if options.plotErrorDist
    % errors by peak power
    figure(fig); hold on;
    fitModel = plotModelFitSmooth( output.valY, output.valYhat, ...
                        colour, true, showPoints, ...
                        20, 70, 20, options.plot.sub );
end                        


