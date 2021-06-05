% ************************************************************************
% Function: defOptions
% Purpose:  Define optimisation variables
%
%
% Parameters:
%       setup: bespoke setup as a structure
%
% Output:
%       opt: options structure
%
% ************************************************************************

function opt = defOptions( setup )


% ************************************************************************
%   Key variables
% ************************************************************************

opt.method = setup.method; 'Fixed';
opt.optimize.doNestedSearch = true;
opt.generateDistributions = true;
opt.plotErrorDist = false;

opt.model.type = 'GPR-Bespoke';
opt.nRuns = 50;
opt.reportInterval = 1;

opt.data.doReduceSample = false;
opt.data.reducedSampleMethod = 'ReduceSubject';
opt.data.reducedSize = 25; % number of subjects
opt.data.reducedSamplesPerSubject = 1; % jumps per subject

opt.data.standardize = setup.standardize;
opt.data.doMultiCurves = false;
opt.data.curves = 'ACC+AD1+AD2+VEL+DIS+PWR';
opt.data.jumpDetection = 'TakeoffVGRF'; % alignment method
opt.data.doIncludeExtraJumps = true;

opt.preproc.useResultant = setup.useResultant; % resultant (1D) signal?
opt.preproc.doFixedSeparation = false; % fix gap between windows (flight time)?
opt.preproc.doPriorRotation = false;

partitioning.method = 'KFoldSubject'; % LeaveOneOutSubject MonteCarloSubject
partitioning.doInversion = false;
opt.doControlRandomisation = false;

opt.fda.nBasis = 56; % number of bases (18) Ch5=100 Ch6=110 100
opt.fda.nBasisDensity = setup.nBasisDensity; % bases per time unit 
opt.fda.useDensity = true; % whether of not to use a fixed number of bases
opt.fda.basisOrderAndPenalty = setup.basisOrderAndPenalty; 
opt.fda.lambda = setup.lambda; % roughness penalty (4.80)

opt.fpca.doFPCApartitioning = true; % allow test data to be used for FPC calculation
opt.fpca.nRetainedComp = setup.nRetainedComp; % retained components from FPCA 35
opt.fpca.nRetainedCompWarp = 3; % retained components from warp
opt.fpca.doVarimax = false; % varimax rotations?

opt.reg.doRegistration = false;
opt.reg.doInitialise = false; % one-time only
opt.reg.doCalculation = false; % perform the calculation or read from file?
opt.lm.setApplied = 'p1';

opt.filter.method = 'All'; % type of selection 
opt.filter.criterion = 'Threshold'; 
opt.filter.rThreshold = 0.1; %10^(-2.81)
opt.filter.maxPredictors = 30; % max predictors in 1D





strategy = 'B'; % input('Strategy (B/R/S) = ', 's');
switch upper(strategy)

    case 'B'
        opt.sampling.doSignalBased = false;
        opt.sampling.doFeatureBased = false;
        colour = 'k';
        strategy = 'Baseline';
    
    case 'R'
        opt.sampling.doSignalBased = true;
        opt.sampling.doFeatureBased = false;
        colour = 'r';
        strategy = 'Rotations';

    case 'S'
        opt.sampling.doSignalBased = false;
        opt.sampling.doFeatureBased = true;
        colour = 'b';
        strategy = 'SMOTER';
      
end


% ************************************************************************
%   Model Hyperparameters
% ************************************************************************

opt.gpr.basis = 'None'; % None
opt.gpr.kernel = 'SquaredExponential'; % SquaredExponential
opt.gpr.sigmaN0 = 10^(-0.61); % noise standard deviation (-2.20)
opt.gpr.constSigma = true;
opt.gpr.sigmaMin = 1E-4; % 1E-2 for over-sampling
opt.gpr.sigmaMax = 20;
opt.gpr.lengthScaling = false;

opt.svm.kernel = 'Polynomial';
opt.svm.boxConstraint = 10^(6.59); % 2.57E-2; % 10^0.524;
opt.svm.kernelScale = 10^(3.52); % 3.79E-2; % 10^0.416;
opt.svm.epsilon = 10^(-1.63); % 7.53E-1; % 10^-0.820;

opt.lr.lambdaLR = 10^(-3.96);
opt.lr.regularization = 'ridge'; % was ridge
opt.lr.learner = 'leastsquares';


% ************************************************************************
%   Other options
% ************************************************************************

opt.data.sensorCodes = { 'lb', 'ub', 'ls', 'rs' };
opt.data.sensors = setup.sensors;
opt.data.arms = setup.curveType;
opt.data.sex = 'All';
opt.data.perfLevel = 'All';
opt.data.measure = 'PeakPower';
opt.data.nPerfLevels = 3;
opt.data.doControlRandomisation = opt.doControlRandomisation;
opt.data.randomSeed = setup.randomSeed;
opt.data.doBySubject = true;
opt.data.testJumpDetection = 'None'; % test harness to use
opt.data.syncNoiseSD = 0; 
opt.data.doUseAccData = true; % whether to use ACC data (or VGRF)
opt.data.weighting = false;
opt.data.doIncludeAttributes = false;

opt.preproc.tFreq = setup.tFreq; % sampling frequency
opt.preproc.tLength1 = setup.preLength; % time window before take-off
opt.preproc.tLength2 = setup.postLength; % time window after take-off
opt.preproc.maxLength = setup.tFreq*(setup.preLength+setup.postLength)+1; % max number of points
opt.preproc.maxLength1 = setup.tFreq*setup.preLength+1; % max number of points
opt.preproc.maxLength2 = setup.tFreq*setup.postLength+1; % max number of points
opt.preproc.minLength = 50; % constraint in time intervals (ms)

opt.preproc.fixedSeparation = 250; % fixed separation if required
opt.preproc.do3dTransform = false;
opt.preproc.transformFunction = @cart2pol;
opt.preproc.doDiscontinuityCorrection = false;
opt.preproc.initOrientation = [ -1 0 0 ];
opt.preproc.doRandomRotation = false;
opt.preproc.doRandomDimension = 2;
opt.preproc.angleSD = 15*pi/180;

opt.preproc.landing.maxSpikeWidth = 30;
opt.preproc.landing.freefallThreshold = 1.00; % (g) limit for freefall
opt.preproc.landing.freefallRange = 65; % 112 period for calculating freefall acc
opt.preproc.landing.idxOffset = -10; % -23 bias
opt.preproc.landing.nSmooth = 5; % moving average window (x*2+1)

opt.preproc.takeoff.idxMaxDivergence = 85;
opt.preproc.takeoff.idxOffset = -1; % bias
opt.preproc.takeoff.nSmooth = 10; % moving average window (x*2+1)
opt.preproc.takeoff.initOrientation = opt.preproc.initOrientation;
opt.preproc.takeoff.doReorientation = true;

opt.fpca.doCentreFunctions = true; % does FPC1 exclude the mean?
opt.fpca.doShowComponents = false;
opt.fpca.doFPCApartitioningComparison = false;
opt.fpca.doPlotComponents = false;

opt.fda.basisOrder = 5; % 4th order for a basis expansion of cubic splines
opt.fda.penaltyOrder = 1; % 2nd order roughness penalty

opt.reg.filename = fullfile(setup.datapath, 'ACCRegistration-JumpDetection6');
opt.reg.nBasis = 15; % number of bases for temporal function
opt.reg.basisOrder = 1; 
opt.reg.wLambda = 1E6; % roughness penalty for temporal function
opt.reg.yLambda = 1E4; % roughness penalty to prevent wiggles in y
opt.reg.lambdaIdxFcn = @(x) 5*round(log10(x),1)+1; % 5 for 0.2 increment
opt.reg.nLambda = 51;
opt.reg.nWLambda = 51;
%opt.reg.calcCurves = cID;
opt.reg.calcSensors = 1;
opt.reg.calcLM = 2:4; % specified sets below
opt.reg.calcLambda = 0:0.2:10; %0:1:8;
opt.reg.calcWLambda = 6;

opt.lm.nBasis = 50; % number of bases for landmark search
opt.lm.lambda = 1E4; % heavily smoothed for landmark search
opt.lm.basisOrder = opt.fda.basisOrder; % same as above
opt.lm.penaltyOrder = opt.fda.penaltyOrder;
opt.lm.doCurvePlots = false; % display plots for checks
opt.lm.doFixedReference = false;
opt.lm.fixedReference = [ 180, 610 ]; % [ 180, 520, 610 ];
opt.lm.sets = { 'none', 'p1', 'p2', 'p1p2', 'p1d1p2', 'top2', 'ldp2', 'd1p2' };

opt.lm.none.pwrMax1 = false;
opt.lm.none.takeoff = false;
opt.lm.none.landing = false;
opt.lm.none.accd1Max = false;
opt.lm.none.pwrMax2 = false;

opt.lm.p1.pwrMax1 = true;
opt.lm.p1.takeoff = false;
opt.lm.p1.landing = false;
opt.lm.p1.accd1Max = false;
opt.lm.p1.pwrMax2 = false;

opt.lm.p2.pwrMax1 = false;
opt.lm.p2.takeoff = false;
opt.lm.p2.landing = false;
opt.lm.p2.accd1Max = false;
opt.lm.p2.pwrMax2 = true;

opt.lm.p1p2.pwrMax1 = true;
opt.lm.p1p2.takeoff = false;
opt.lm.p1p2.landing = false;
opt.lm.p1p2.accd1Max = false;
opt.lm.p1p2.pwrMax2 = true;

opt.lm.p1d1p2.pwrMax1 = true;
opt.lm.p1d1p2.takeoff = false;
opt.lm.p1d1p2.landing = false;
opt.lm.p1d1p2.accd1Max = true;
opt.lm.p1d1p2.pwrMax2 = true;

opt.lm.top2.pwrMax1 = false;
opt.lm.top2.takeoff = true;
opt.lm.top2.landing = false;
opt.lm.top2.accd1Max = false;
opt.lm.top2.pwrMax2 = true;

opt.lm.ldp2.pwrMax1 = false;
opt.lm.ldp2.takeoff = false;
opt.lm.ldp2.landing = true;
opt.lm.ldp2.accd1Max = false;
opt.lm.ldp2.pwrMax2 = true;

opt.lm.d1p2.pwrMax1 = false;
opt.lm.d1p2.takeoff = false;
opt.lm.d1p2.landing = false;
opt.lm.d1p2.accd1Max = true;
opt.lm.d1p2.pwrMax2 = true;

opt.truncation.doControlRandomisation = opt.doControlRandomisation;
opt.truncation.nTrialsPerSubject = 4; % number of jumps to retain per subject
opt.truncation.doRandomiseSubjects = true; 
opt.truncation.nSubjectsRequired = 55; % number of subjects to retain
opt.truncation.nSubjectsTrueResponse = 30; % number of subjects with true response
opt.truncation.doAddNoise = false; % whether to add to response for some subjects
opt.truncation.noiseSD = 0.5; % standard deviation of noise for response
opt.truncation.var = 'nSubjectsRequired';
opt.truncation.values = 25:10:55;

partitioning.doControlRandomisation = opt.doControlRandomisation;
partitioning.randomSeed = setup.randomSeed;
partitioning.iterations = 1;
partitioning.kFolds = 10;
partitioning.split = [ 0.70, 0.0, 0.30 ];
partitioning.trainSubset = 'Full';
partitioning.testSubset = 'Full';

opt.part.inner = partitioning;
opt.part.inner.iterations = setup.nInnerLoop;
opt.part.inner.kFolds = setup.kInnerFolds;

opt.part.outer = partitioning;
opt.part.outer.iterations = setup.nOuterLoop;
opt.part.outer.kFolds = setup.kOuterFolds;


opt.filter.kID = 1;
opt.filter.jID = 1;
opt.filter.doControlRandomisation = opt.doControlRandomisation;
opt.filter.lengthScaleThreshold = 1E2; % 1E3
opt.filter.doInterleave = true; % interleave
opt.filter.maxPredictors = 1; % max predictors in 1D
opt.filter.doReorder = false; % re-order predictors based on LS
opt.filter.var = 'MaxPredictors';
opt.filter.values = 10;
opt.filter.dim = 7; %0b111; % in binary the dimensions to include
opt.filter.sensors = 1; %2:2^4-1; % list of sensors for predictors
opt.filter.series = 15; %1:2^6-1;

opt.data.nPredictors = opt.fpca.nRetainedComp* ...
                (1 + ~opt.preproc.useResultant*2)* ...
    (1 + opt.data.doMultiCurves*((length(opt.data.curves)+1)/4-1));

predSelection = true( 1, opt.data.nPredictors );
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
predNames = tblFieldNames( opt.data.nPredictors, {'fpc'} );
predTable.Properties.VariableNames = predNames;
opt.filter.predictor = table2struct( predTable );


opt.reduce.method = 'None';
opt.reduce.nRetainedCompPCA = 3;

opt.sampling.over = 1.0; % multiple of cases to add
opt.sampling.under = 1.0; % proportion of cases to remove
opt.sampling.nWeightings = 0;
opt.sampling.knn = 8; % number of nearest neighbours
opt.sampling.nFPC = 6; % number of FPCs for nearest neighbours
opt.sampling.angSD = 20;
opt.sampling.axisR = 1;
opt.sampling.doGlobal = false;

opt.sampling.doControlRandomisation = opt.doControlRandomisation;
opt.sampling.showDistribution = false;
opt.sampling.caseSelection = 'Probability';
opt.sampling.threshold = 0.3; % proportion of max weight above which cases may be removed
opt.sampling.distFunction = 'Kernel';
opt.sampling.topend = false;
opt.sampling.distanceMetric = 'Euclidean'; 
opt.sampling.interpolation = 'Uniform'; % for over-sampling
opt.sampling.estimation = 'Linear'; % GP model estimation

opt.plot.doShowPerformance = false;
opt.plot.doShowPartPerf = false;
opt.plot.performanceType = 'Residuals';
opt.plot.doShowModelError = false;
opt.plot.doShowLengthScaling = true;
opt.plot.doShowFitPanel = false;
opt.plot.doShowModelVariance = false;

opt.plot.full.font = 'Times New Roman';
opt.plot.full.fontSize = 16;
opt.plot.full.xLabelRotation = 0;
opt.plot.full.axisLineWidth = 1;
opt.plot.full.lineWidth = 1.5;
opt.plot.full.box = false;
opt.plot.full.tickDirection = 'Out';
opt.plot.full.doPlotPoints = false;

opt.plot.sub.font = 'Times New Roman';
opt.plot.sub.fontSize = 24;
opt.plot.sub.xLabelRotation = 0;
opt.plot.sub.axisLineWidth = 1;
opt.plot.sub.lineWidth = 1;
opt.plot.sub.box = false;
opt.plot.sub.tickDirection = 'Out';
opt.plot.sub.tickLength = [0.025, 0.025];

opt.plot.mini.font = 'Times New Roman';
opt.plot.mini.fontSize = 36;
opt.plot.mini.xLabelRotation = 0;
opt.plot.mini.axisLineWidth = 2.5;
opt.plot.mini.lineWidth = 2.5;
opt.plot.mini.box = false;
opt.plot.mini.tickDirection = 'Out';
opt.plot.mini.doPlotPoints = false;


end