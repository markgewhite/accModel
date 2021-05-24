% ************************************************************************
% Function: defOptimiseVar
% Purpose:  Define optimisation variables
%
%
% Parameters:
%       activeVar: vector of variable indices for optimisation
%
% Output:
%       opt: optimization variable structures
%
% ************************************************************************

function opt = defOptimiseVar( setup, nPredictors )

% ************************************************************************
%   Optimisation options
% ************************************************************************

opt.percentLoss = false;
opt.objective = 'Loss';
%opt.objectiveDescr = 'SM Prediction (W\cdotkg^{-1})'; %'Loss CV (Inner Fold)';
%opt.doSMValidation = false;
%opt.SMFile = 'ID-5-029 SVM Opt 2000.mat';
%opt.randomSearchUpdate = 20;
%opt.doConvergence = false;
%opt.nRamp = opt.nRuns;
%opt.allGranular = false;
%opt.dotUpdate = 1;
%opt.maxObjEval1 = 50;
%opt.maxObjEval2 = 0;
%opt.initMaxLoss = 20; % 10 
%opt.maxTries = 100;
%opt.explore1 = 0.5; % 2
%opt.explore2 = 1;
%opt.plotFcn = []; %{@plotObjectiveModel, @plotMinObjective};
%opt.verbose = 1;
%opt.setInitial = false;
%opt.plotType = 'Line'; % None
%opt.doGPfit = false;
%opt.doPlotPoints = false;
%opt.doDiscretePoints = true;
%opt.doSigmoid = false;
%opt.doPlotConfidence = true;
%opt.doAddCI2Legend = true;
%opt.overlapFactor = 0.50;
%opt.varJoint = false;
%opt.lossLim = [2 8];
%opt.contourStep = 0.2;
%opt.lossFormat = '%.1f';
%opt.avgWindow = 10;
%opt.doMultipleFigures = false;
%opt.subsamplingMethod = 'KFold';
%opt.tolPSO = 0.01;
%opt.tolFMin = 0.001;
%opt.maxIter = 10000;

opt.initMaxLoss = 100; 
opt.maxTries = 500;
opt.tolPSO = 0.01;
opt.tolFMin = 0.001;
opt.maxIter = 10000;
opt.verbose = setup.verbose;
opt.quasiRandom = true;

opt.nFit = setup.nFit; 
opt.nSearch = setup.nSearch; 
opt.prcMaxLoss = 50;
opt.constrain = true;
opt.porousness = setup.porousness;
opt.window = setup.window;
opt.cap = 10;
opt.sigmaLB = 0.2;
opt.sigmaUB = 1.0;
opt.psoBorderInt = 2;
opt.psoBorderReal = 0.1;

opt.showPlots = setup.showPlots;
opt.useSubPlots = true;

opt.nRepeats = setup.nRepeats;
opt.nInterTrace = setup.nInterTrace;

opt.activeVar = setup.activeVar;


i = 1;
opt.grp(i) = "data";
opt.var(i) = "arms";
opt.descr(i) = "Jump Type";
opt.lim{i} = [];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = { 'Both', 'No Arms', 'With Arms' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "data";
opt.var(i) = "sex";
opt.descr(i) = "Sex";
opt.lim{i} = [];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = { 'All', 'Male', 'Female' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "data";
opt.var(i) = "perfLevel";
opt.descr(i) = "Performance Level";
opt.lim{i} = [];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = { 'All', 'Low', 'Intermediate', 'High' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );   
    
% algorithm parameter
i = 4;
opt.grp(i) = "model";
opt.var(i) = "type";
opt.descr(i) = "Algorithm";
opt.lim{i} = [];
opt.isLog(i) = false;
opt.isCat(i) = true;
%opt.fcn{i} = { 'LR', 'LR-RDG', 'LR-LSS', ...
%                            'SVM-L', 'SVM-G', ...
%                            'GPR-SE', 'GPR-M52', ...
%                            'NN-5', 'NN-10', ...
%                            'TR-ENS' };
opt.fcn{i} = { 'LR-Bespoke', 'SVM-Bespoke', 'GPR-Bespoke' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );
 
% GPR parameters
i = 5;
opt.grp(i) = "gpr";
opt.var(i) = "basis";
opt.descr(i) = "GPR Basis Function";
opt.lim{i} = [0.5 4.5];
opt.bounds{i} = [0.5 4.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = { 'None', 'Constant', 'Linear', 'PureQuadratic' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "gpr";
opt.var(i) = "kernel";
opt.descr(i) = "GPR Kernel Function";
opt.lim{i} = [0.5 5.5];
opt.bounds{i} = [0.5 5.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = { 'Exponential', 'SquaredExponential', ...
                            'Matern32', 'Matern52', 'RationalQuadratic' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "gpr";
opt.var(i) = "sigmaN0";
opt.descr(i) = "\it\sigma_{N}";
opt.lim{i} = [-4 2];
opt.bounds{i} = [-4 2];
opt.isLog(i) = true;
opt.isCat(i) = false;
%opt.fcn{i} = 10.^(-3.0:0.1:2.0);
%opt.varDef(i) = optimizableVariable( opt.var(i), ...
%        [1, 51], 'Type', 'integer', ...
%        'Optimize', ismember( i, setup.activeVar ) );
opt.fcn{i} = @(x) 10^x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [-5 3], 'Type', 'real', ...
        'Optimize', ismember( i, setup.activeVar ) );
    

i = i+1;
opt.grp(i) = "gpr";
opt.var(i) = "standardize";
opt.descr(i) = "Standardise";
opt.lim{i} = [0.5 2.5];
opt.bounds{i} = [0.50 2.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = {'false', 'true'};
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
% SVM parameters
i = 9;
opt.grp(i) = "svm";
opt.var(i) = "kernel";
opt.descr(i) = "SVM Kernel Function";
opt.lim{i} = [0.5 3.5];
opt.bounds{i} = [0.50 3.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = {'Linear', 'Gaussian', 'Polynomial'};
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "svm";
opt.var(i) = "boxConstraint";
opt.descr(i) = "Box Constraint";
opt.lim{i} = [-6 8];
opt.bounds{i} = [-6 8];
opt.isLog(i) = true;
opt.isCat(i) = false;
opt.fcn{i} = @(x) 10^x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [-7 9], 'Type', 'real', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "svm";
opt.var(i) = "kernelScale";
opt.descr(i) = "Kernel Scale";
opt.lim{i} = [-6 8];
opt.bounds{i} = [-6 8];
opt.isLog(i) = true;
opt.isCat(i) = false;
%opt.fcn{i} = 10.^(-2.0:0.25:3.0);
%opt.varDef(i) = optimizableVariable( opt.var(i), ...
%        [1 21], 'Type', 'integer', ...
%        'Optimize', ismember( i, setup.activeVar ) );
opt.fcn{i} = @(x) 10^x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [-7 9], 'Type', 'real', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "svm";
opt.var(i) = "epsilon";
opt.descr(i) = "\epsilon";
opt.lim{i} = [-4 3];
opt.bounds{i} = [-4 3];
opt.isLog(i) = true;
opt.isCat(i) = false;
%opt.fcn{i} = 10.^(-2.0:0.1:2.0);
%opt.varDef(i) = optimizableVariable( opt.var(i), ...
%        [1 41], 'Type', 'integer', ...
%        'Optimize', ismember( i, setup.activeVar ) ); % PP IQR = 12.7 
opt.fcn{i} = @(x) 10^x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [-5 4], 'Type', 'real', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "svm";
opt.var(i) = "standardize";
opt.descr(i) = "Standardise";
opt.lim{i} = [0.5 2.5];
opt.bounds{i} = [0.50 2.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = {'false', 'true'};
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
% LR parameters
i = 14;
opt.grp(i) = "lr";
opt.var(i) = "lambdaLR";
opt.descr(i) = "LR Lambda";
opt.lim{i} = [-10 10];
opt.bounds{i} = [-10 10];
opt.isLog(i) = true;
opt.isCat(i) = false;
%opt.fcn{i} = 10.^(-5.0:0.1:5.0);
%opt.varDef(i) = optimizableVariable( opt.var(i), ...
%        [1 101], 'Type', 'integer', ...
%        'Optimize', ismember( i, setup.activeVar ) );
opt.fcn{i} = @(x) 10^x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [-12 12], 'Type', 'real', ...
        'Optimize', ismember( i, setup.activeVar ) );

    
    
i = i+1;
opt.grp(i) = "lr";
opt.var(i) = "regularization";
opt.descr(i) = "Regularisation Method";
opt.lim{i} = [0.5 2.5];
opt.bounds{i} = [0.5 2.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = {'lasso', 'ridge'};
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "lr";
opt.var(i) = "learner";
opt.descr(i) = "LR Solver";
opt.lim{i} = [0.5 2.5];
opt.bounds{i} = [0.5 2.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = {'svm', 'leastsquares'};
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

    
% time window parameters
i = 17;
opt.grp(i) = "preproc";
opt.var(i) = "tLength1";
opt.descr(i) = "\it t_{\rmpre} \rm(ms)";
opt.lim{i} = [0, 3000];
opt.bounds{i} = [6 36];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = (-500:100:3500);
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1 41], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "preproc";
opt.var(i) = "tLength2";
opt.descr(i) = "\it t_{\rmpost} \rm(ms)";
opt.lim{i} = [0, 3000];
opt.bounds{i} = [6 36];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = (-500:100:3500);
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1 41], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "preproc";
opt.var(i) = "doFixedSeparation";
opt.descr(i) = "Fixed Flight Time";
opt.lim{i} = [];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = {'false', 'true'};
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "data";
opt.var(i) = "syncNoiseSD";
opt.descr(i) = "Synchronisation Noise SD (ms)";
opt.lim{i} = [0 100];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = (0:4:100);
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1, 26], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "data";
opt.var(i) = "jumpDetection";
opt.descr(i) = "Alignment";
opt.lim{i} = [0.5 3.5];
opt.bounds{i} = [0.5 3.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
%opt.fcn{i} = { 'TakeoffACC', 'LandingACC', 'ImpactACC' };
opt.fcn{i} = { 'TakeoffVGRF', 'TakeoffACC' };
%opt.fcn{i} = {'TakeoffACC', ...
%                            'LandingACC', ...
%                            'ImpactACC', 'Power1ACC', 'Power2ACC' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );


% smoothing parameters
i = 22;
opt.grp(i) = "fda";
opt.var(i) = "basisDensity";
opt.descr(i) = "Basis Function Density (fn/s)";
opt.lim{i} = [5, 20];
opt.bounds{i} = [5 20];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x/1000;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [2 23], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );
    
i = i+1;
opt.grp(i) = "fda";
opt.var(i) = "basisOrderAndPenalty";
opt.descr(i) = "Basis Function Order & Penalty Order";
opt.lim{i} = [];
opt.bounds{i} = [0.5 6.49];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = { '4-2', '5-2', '5-3', '6-2', '6-3', '6-4' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );
       
i = i+1;
opt.grp(i) = "fda";
opt.var(i) = "lambda";
opt.descr(i) = "log_{10}\it\lambda\rm";
opt.init{i} = 6;
opt.lim{i} = [-10 10];
opt.bounds{i} = [-10 10];
opt.isLog(i) = true;
opt.isCat(i) = false;
opt.fcn{i} = @(x) 10^x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [-12 12], 'Type', 'real', ...
        'Optimize', ismember( i, setup.activeVar ) );   
    
% registration parameters
i = 25;
opt.grp(i) = "lm";
opt.var(i) = "setApplied";
opt.descr(i) = "Registration Landmark Sets";
opt.lim{i} = [0.5 4.5];
opt.bounds{i} = [0.5 4.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = { 'none', 'p1', 'p2', 'p1p2' };
%opt.fcn{i} = { 'none', 'setA' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "reg";
opt.var(i) = "wLambda";    
opt.descr(i) = "log_{10}(\it\lambda_{\rmWarp})\rm";
opt.lim{i} = [1, 5];
opt.bounds{i} = [0.5 5.49];
opt.isLog(i) = true;
opt.isCat(i) = false;
opt.fcn{i} = [ 1E0 1E2 1E4 1E6 1E8 ]; % missing 1E4
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1, 5], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "fpca";
opt.var(i) = "nRetainedCompWarp";
opt.descr(i) = "Number of Retained Warp FPCs";
opt.lim{i} = [0, 5];
opt.bounds{i} = [0.5 5.49];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1, 5], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );

% FPCA parameters
i = 28;
opt.grp(i) = "fpca";
opt.var(i) = "nRetainedComp";
opt.descr(i) = "Number of Retained FPCs";
opt.lim{i} = [0, 30];
opt.bounds{i} = [3.5 30.49];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1, 35], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;    
opt.grp(i) = "fpca";
opt.var(i) = "doVarimax";
opt.descr(i) = "Perform Varimax?";
opt.lim{i} = [0.5 2.5];
opt.bounds{i} = [0.5 2.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = {'false', 'true'};
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

% feature selection parameters
i = 30;
opt.grp(i) = "filter";
opt.var(i) = "rThreshold";
opt.descr(i) = "Predictor Selection Threshold for correlation, \it r";
opt.lim{i} = [-4, 0];
opt.bounds{i} = [-4.0 -0.5];
opt.isLog(i) = true;
opt.isCat(i) = false;
opt.fcn{i} = @(x) 10^x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [-4.0, -0.5], 'Type', 'real', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "filter";
opt.var(i) = "maxPredictors";
opt.descr(i) = "Number of Retained Predictors";
opt.lim{i} = [0, 30];
opt.bounds{i} = [0.5 30.49];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1, 30], 'Type', 'integer',  ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "preproc";
opt.var(i) = "doPriorRotation";
opt.descr(i) = "Signal Orientation Correction";
opt.lim{i} = [0.5 2.5];
opt.bounds{i} = [0.5 2.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = {'false', 'true'};
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

    
% sample size reduction parameters
i = 33;
opt.grp(i) = "data";
opt.var(i) = "reducedSize";
opt.descr(i) = "Sample Size (Subjects)";
opt.lim{i} = [1, 100];
opt.bounds{i} = [0.5 60.49];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1, 60], 'Type', 'integer',  ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "data";
opt.var(i) = "reducedSamplesPerSubject";
opt.descr(i) = "Jumps per Participant";
opt.lim{i} = [1, 4];
opt.bounds{i} = [0.5 4.49];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1, 4], 'Type', 'integer',  ...
        'Optimize', ismember( i, setup.activeVar ) );

% data augmentation parameters
i = 35;
opt.grp(i) = "sampling";
opt.var(i) = "nWeightings";
opt.descr(i) = "Number of Weightings";
opt.lim{i} = [0, 15];
opt.bounds{i} = [-0.49 15.49];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [0, 15], 'Type', 'integer',  ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "sampling";
opt.var(i) = "threshold";
opt.descr(i) = "Case Selection Threshold";
opt.lim{i} = [0 0.9];
opt.bounds{i} = [0 0.9];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [0, 0.9], 'Type', 'real',  ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "sampling";
opt.var(i) = "over";
opt.descr(i) = "Over-sampling Ratio";
opt.lim{i} = [0, 5];
opt.bounds{i} = [0 5];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [0, 5], 'Type', 'real',  ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "sampling";
opt.var(i) = "under";
opt.descr(i) = "Under-sampling Ratio";
opt.lim{i} = [0, 0.9];
opt.bounds{i} = [0 0.9];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [0 0.9], 'Type', 'real', ...
        'Optimize', ismember( i, setup.activeVar ) );

% over-sampling rotation method
i = 39;
opt.grp(i) = "sampling";
opt.var(i) = "angSD";
opt.descr(i) = strcat("Random Rotation SD (", char(176), ")");
opt.lim{i} = [0 30];
opt.bounds{i} = [0 30];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [0 30], 'Type', 'real', ...
        'Optimize', ismember( i, setup.activeVar ) );
  
i = i+1;
opt.grp(i) = "sampling";
opt.var(i) = "axisR";
opt.descr(i) = "Rotation Axis";
opt.lim{i} = [0.5 3.5];
opt.bounds{i} = [0.5 3.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1 3], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "sampling";
opt.var(i) = "doGlobal";
opt.descr(i) = "Use Global Reference Frame?";
opt.lim{i} = [0.5 2.5];
opt.bounds{i} = [0.5 2.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = [ false true ];
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1, 2], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar )  );    
    
% over-sampling SMOTER method
i = 42;
opt.grp(i) = "sampling";
opt.var(i) = "knn";
opt.descr(i) = "SMOTER Nearest Neighbours";
opt.lim{i} = [0, 10];
opt.bounds{i} = [0.5 10.49];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1 10], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );   
    
i = i+1;
opt.grp(i) = "sampling";
opt.var(i) = "nFPC";
opt.descr(i) = "No. FPCs for Nearest Neighbours";
opt.lim{i} = [0, 15];
opt.bounds{i} = [0.5 15.49];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = @(x) x;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        [1 15], 'Type', 'integer', ...
        'Optimize', ismember( i, setup.activeVar ) );   
   
i = i+1;
opt.grp(i) = "sampling";
opt.var(i) = "interpolation";
opt.descr(i) = "Interpolation Distribution";
opt.lim{i} = [0.5 2.5];
opt.bounds{i} = [0.5 2.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = { 'Uniform', 'Normal' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

i = i+1;
opt.grp(i) = "sampling";
opt.var(i) = "estimation";
opt.descr(i) = "Outcome Estimation Method";
opt.lim{i} = [0.5 2.5];
opt.bounds{i} = [0.5 2.49];
opt.isLog(i) = false;
opt.isCat(i) = true;
opt.fcn{i} = { 'Linear', 'Gaussian Process' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );    

% sensor selection parameter
i = 46;
opt.grp(i) = "data";
opt.var(i) = "sensors";
opt.descr(i) = "Accelerometer attachment site";
opt.lim{i} = [];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = { 'LB', 'UB', 'LS', 'RS', 'LB+UB', 'LB+LS', ...
                             'LB+RS', 'UB+LS', 'UB+RS' };
opt.varDef(i) = optimizableVariable( opt.var(i), ...
        opt.fcn{i}, 'Type', 'categorical', ...
        'Optimize', ismember( i, setup.activeVar ) );

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
opt.grp(i) = "data";
opt.var(i) = "curves";
opt.descr(i) = "Computed Curves Included";
opt.lim{i} = [];
opt.isLog(i) = false;
opt.isCat(i) = false;
opt.fcn{i} = curveOptions;
opt.varDef(i) = optimizableVariable( opt.var(i), ...
            opt.fcn{i}, 'Type', 'categorical', ...
            'Optimize', ismember( i, setup.activeVar ) );

        
% predictor selection parameters as binary switches
for j = 1:nPredictors
    i = 47+j;
    opt.grp(i) = "predictor";
    opt.var(i) = "fpc"+num2str(j,'%03d');
    opt.descr(i) = "FPC "+num2str(j,'%03d');
    opt.lim{i} = [0.5 2.5];
    opt.bounds{i} = [0.5 2.49];
    opt.isLog(i) = false;
    opt.isCat(i) = true;
    opt.fcn{i} = [ false true ];
    opt.varDef(i) = optimizableVariable( opt.var(i), ...
                [1, 2], 'Type', 'integer', ...
                'Optimize', ismember( i, setup.activeVar ) );
end

end