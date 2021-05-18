% ************************************************************************
% Function: accModelRun
% Purpose:  Run the Accelerometer Signal Model 
%           - Prepare predictors
%           - Filter the cases
%           - Partition the data for cross validation
%           - Generate augmented data
%           - Run the model
%           - Determine model performance
%
%
% Parameters:
%       X: all predictors (training + validation)
%       Y: all outcomes (training + validation)
%       trnIdx: logical array identifying the training cases
%       valIdx: logical array identifying the validation cases
%       LM: array of landmarks, pre-identified (training + validation)
%       options
%       hyperparams
%
%  NB The variables are listed out this way rather than using the
%     the 'data' structure in order to minimise data passing
%     to/from this function.
%
% Output:
%       loss: optimal model loss
%       constraints: vector indicating incompatible parameters
%       info: user data on the model, etc
%
% ************************************************************************


function [ obj, constraints, info ] = accModelRun( hp, data, options, ...
                                                   dataIdx )


specificSplit = (nargin == 4);
                                               
% ------------------------------------------------------------
%   Unpack the hyperparmeters
% ------------------------------------------------------------

if ~isempty( hp ) 
    if istable( hp )
        hp = table2cell( hp );
    end
    j = 0;
    for i = options.optimize.activeVar

        optGroup = options.optimize.grp(i);
        optVar = options.optimize.var(i);
        j = j + 1;
        if strcmp( options.optimize.varDef(i).Type, 'categorical' )
            switch hp{j}
                case 'false'
                    optValue = false;
                case 'true'
                	optValue = true;
                otherwise
                    optValue = char( hp{j} );
            end
        else
            optValue = options.optimize.fcn{i}( hp{j} );
        end
        options.(optGroup).(optVar) = optValue;

    end
    
end


% ------------------------------------------------------------
%   Check if constraints are violated
% ------------------------------------------------------------

% check if there are enough bases for the retained components
constraints(1) = options.fpca.nRetainedComp - options.fda.nBasis;
% check if the time window is not inverted
constraints(2) = options.preproc.minLength ...
                - (options.preproc.tLength1 + options.preproc.tLength2);
% check if penalty order is at least two orders lower than basis order
constraints(3) = -(options.fda.basisOrder - options.fda.penaltyOrder)+2;
if any( constraints > 0 )
    obj = 10;
    info = 0;
    return
end


% ------------------------------------------------------------
%   Extract data
% ------------------------------------------------------------

Y = data.outcome;
S = data.subject;

tLanding = data.landingTime;

% selected desired synchronisation to desired set of points
switch options.data.jumpDetection
    case 'TakeoffVGRF'
        syncIdx = data.takeoffVGRF;
    
    case 'LandingVGRF'
        syncIdx = data.landingVGRF;

    case 'TakeoffACC'
        syncIdx = data.takeoffACC;
        
    case 'LandingACC'  
        syncIdx = data.landingACC;

    case 'ImpactACC'  
        syncIdx = data.impactACC;
        
    otherwise
        error('Unrecognised Jump Detection Method.');

end

% introduce noise into synchronisation, if required 
if options.data.syncNoiseSD > 0
    syncIdx = round( normrnd( syncIdx, ...
                    options.data.syncNoiseSD*options.preproc.tFreq ), 0 );
end

nSensors = (length( options.data.sensors )+1)/3;
sensor = contains( options.data.sensorCodes, options.data.sensors(1:2) );
signal = cell( nSensors, 1 );
signal{1} = data.signal.(options.data.sensorCodes{sensor});
for i = 2:nSensors
    sensor = contains( options.data.sensorCodes, ...
                        options.data.sensors(i*3-2:i*3-1) );
    signal{i} = data.signal.(options.data.sensorCodes{sensor});
end


% ------------------------------------------------------------
%   Apply Filters
% ------------------------------------------------------------

filter = dataFilter( data, options.data );

Y = Y( filter );
S = S( filter );
tLanding = tLanding( filter );
syncIdx = syncIdx( filter );
for i = 1:nSensors
    signal{i} = signal{i}( filter, :, : );
end


% ------------------------------------------------------------
%  define a single partition, if required, per evaluation
% ------------------------------------------------------------
        
% create multiple sub-partitions within training fold
if specificSplit
    trnIdx = dataIdx;
    valIdx = ~dataIdx;
    
else
    [ trnIdx, valIdx ] = partitionData( ...
                            Y, ...
                            S, ...
                            options.part.inner );
end

nPartitions = size( trnIdx, 2 );


% ------------------------------------------------------------
%  normalise the length of signals and perform any transforms
% ------------------------------------------------------------

tFreq = options.preproc.tFreq;
preLength = options.preproc.tLength1;
postLength = options.preproc.tLength2;

options.preproc.maxLength = tFreq*(preLength+postLength)+1; % max number of points
options.preproc.maxLength1 = tFreq*preLength+1; % max number of points
options.preproc.maxLength2 = tFreq*postLength+1; % max number of points
   
% extract the signals of varying lengths and into a fixed size array
sigX = signalTransforms( signal, syncIdx, tLanding, options.preproc );
nDim = size( sigX{1}, 3 );


% ------------------------------------------------------------
%   Set window size
% ------------------------------------------------------------

% starting with the standard length raw data series
% trim off data from the beginning and from the end
startIdx = ceil(options.preproc.maxLength1-options.preproc.tLength1*tFreq);
endIdx = ceil(options.preproc.maxLength1+options.preproc.tLength2*tFreq);

tSpan = -options.preproc.tLength1:1/tFreq:options.preproc.tLength2;

% truncate the signals to the required window size
for i = 1:nSensors
    sigX{ i }  = sigX{ i }( startIdx:endIdx, :, : );
end


% ------------------------------------------------------------
%  generate synthetic signals from the training data, if required
% ------------------------------------------------------------

if options.sampling.doSignalBased
    % works only on the first sensor data
    
    % switch time and case columns   
    sigX{1} = permute( sigX{1}, [2, 1, 3] ); 
    % store data as start point
    sigX0 = sigX{1};
    Y0 = Y;

    for i = 1:nPartitions
        
        % augment the training data
        [ augSigX, augY, parent, removal ]= resampleData( ...
                            sigX0( trnIdx(:,i), :, : ), ...
                            Y0( trnIdx(:,i) ), ...
                            'Rotation', ...
                            options.sampling );

        % append the augmented signals
        sigX{1} = [ sigX{1}; augSigX ]; 
        % append the augmented outcomes
        Y = [ Y; augY ]; %#ok<AGROW>

        % count changes
        nAug = length( parent );
        nRemove = length( removal );

        % add an empty block to the validation array
        augIdx = false( nAug, nPartitions);
        valIdx = [ valIdx; augIdx ]; %#ok<AGROW>
        % insert a selection column for the training data
        augIdx( :, i ) = true( nAug, 1 );
        trnIdx = [ trnIdx; augIdx ]; %#ok<AGROW>
        % thin out the training data that was earmarked for removal
        trnIdx( removal, i ) = false( nRemove, 1 );
        
    end
    
    % switch back time and case columns
    sigX{1} = permute( sigX{1}, [2, 1, 3] );
        
end



% ------------------------------------------------------------
%  smooth signal time series data
% ------------------------------------------------------------

% convert the signals into smooth functions
[ fdX, fdXParams, info.df, info.gcv ] = ...
                        signalFDA(  sigX, ...
                                    tSpan, ...
                                    options.fda );

                                
% ------------------------------------------------------------
%  perform registration to align acceleration curves
% ------------------------------------------------------------

if options.reg.doRegistration && ~strcmp(options.lm.setApplied, 'none')
       
    if options.reg.doCalculation

        % generate new registered curves and save them
        
        % convert takeoff and landing indices to time for landmarks fn
        tTakeoff = (data.takeoffACC-data.takeoffVGRF)/tFreq;
        tLanding = (data.landingACC-data.takeoffVGRF)/tFreq;
        
        % find landmarks
        % only works on the first sensor data
        
        LM = findACClandmarks( sigX{1}, ...
                               tSpan, ...
                               tTakeoff, ...
                               tLanding, ...
                               options.lm );

        if options.lm.doFixedReference
            LM.mean = options.lm.fixedReference;
        end

        options.reg.yLambda = options.fda.lambda;
        [ info.fdXReg, info.fdWReg ] = registerCurves(  fdX{1}, ...
                                        tSpan, ...
                                        LM, ...
                                        options.reg );
                                    
        fdX{1} = info.fdXReg;
        fdW = info.fdWReg;
                                    
        % don't attempt model processing
        % save it and return
        obj = 0;
        return;
        
    else
        
        % lookup previously computed registered curves
        lambdaIdx = options.reg.lambdaIdxFcn( options.fda.lambda );
        wlambdaIdx = options.reg.lambdaIdxFcn( options.reg.wLambda );
        
        curveFld = options.curveNames{ options.data.cID };
        sensorFld = options.sensorNames{ options.data.sID };
        lmFld = options.lm.setApplied;
    
        fdX{1} = data.fdXReg.(curveFld).(sensorFld).(lmFld) ...
                                                { lambdaIdx, wlambdaIdx };
        fdW = data.fdWReg.(curveFld).(sensorFld).(lmFld) ...
                                                { lambdaIdx, wlambdaIdx };
                                            
        if isempty( fdX{1} )
            error(['No registered curves available for ( ' ...
                        num2str( lambdaIdx ) ', ' ...
                        num2str( wlambdaIdx ) ' )']);
        end
        % processed curves from above ignored
    
    end
                               
else
    
    fdW = [];

end


% ------------------------------------------------------------
%  derive multiple curves based on acceleration curves
% ------------------------------------------------------------

if options.data.doMultiCurves

    fdX = deriveAccCurves( fdX, fdW, options.data.curves, options.fda );

end
nCurves = length( fdX );


% ------------------------------------------------------------
%  construct predictors, if FPC definition not restricted
% ------------------------------------------------------------

if ~options.fpca.doFPCApartitioning
    % FPC definition not restricted to training only
    % FPCs may be defined by all data
    % they may be determined once prior to the inner loop
    
    %  perform functional principal component analysis
    try
        [ allX, ~, fpca ] = assemblePredictors( ...
                                fdX, ...
                                fdW, ...
                                fdXParams, ...
                                true( size(trnIdx,1), 1 ),...
                                false( size(valIdx,1), 1 ), ...
                                options.fpca );
    catch
        obj = NaN;
        info = 0;
        constraints(2) = 100;
        return
    end
end


% ------------------------------------------------------------
%  Run the model K times
% ------------------------------------------------------------

nComp = options.fpca.nRetainedComp;
nCasesTrain = length( find(trnIdx) );
nCasesValid = length( find(valIdx) );
nPredictors = nCurves*nDim*nComp;

info.trnYhat = zeros( nCasesTrain, 1 );
info.valYhat = zeros( nCasesValid, 1 );
info.trnY = zeros( nCasesTrain, 1 );
info.valY = zeros( nCasesValid, 1 );

info.trnX = zeros( nCasesTrain, nPredictors );
info.sqerr = zeros( nCasesValid, 1 );

info.foldLoss = zeros( nPartitions, 1 );

info.score = zeros( nPartitions, nPredictors );
info.varprop = zeros( nPartitions, nPredictors );

info.trnXCorr = zeros( nPartitions, nPredictors );
info.trnXRank = zeros( nPartitions, nPredictors );
info.selectX = false( nPartitions, nPredictors );

trnIdxEnd = 0;
valIdxEnd = 0;
        
for k = 1:nPartitions

    
    % ------------------------------------------------------------
    %  construct the predictors (X) and outcomes (Y)
    % ------------------------------------------------------------

    if options.fpca.doFPCApartitioning
        %  perform functional principal component analysis
        try
            [ trnX, valX, fpca ] = assemblePredictors( ...
                                                fdX, ...
                                                fdW, ...
                                                fdXParams, ...
                                                trnIdx(:,k), ...
                                                valIdx(:,k), ...
                                                options.fpca );
        catch
            obj = NaN;
            info = 0;
            constraints(2) = 100;
            return
        end

    else
        % extract the FPC scores from the pre-processed FPCA
        trnX = allX( trnIdx(:,k), : );
        valX = allX( valIdx(:,k), : );
    end

    % setup the outcome values
    trnY = Y( trnIdx(:,k) );
    valY = Y( valIdx(:,k) );
    
    % record the mean absolute FPC scores, variance proportion
    info.score( k, : ) = mean( abs(table2array(trnX)) );
    for j = 1:nCurves
        for i = 1:nDim
            pStart = (j-1)*nDim*nComp+(i-1)*nComp+1;
            pEnd = pStart+nComp-1;
            info.varprop( k, pStart:pEnd ) = fpca{j}.varprop;
        end
    end
    
    % ------------------------------------------------------------
    %  Manual standardisation, if required
    % ------------------------------------------------------------

    if options.data.doCustomStandardization
        trnX = normalize( trnX, 'zscore' );
        valX = normalize( valX, 'zscore' );
    end
        
    % ------------------------------------------------------------
    %  filter the predictors
    % ------------------------------------------------------------

    % filter the predictors, as required
    [ info.selectX(k,:), info.trnXRank(k,:), info.trnXCorr(k,:)] = ...
                                filterPredictors( trnX, trnY, options ); 
    
    if sum( info.selectX(k,:) ) == 0
        constraints(2) = 99;
        info = 0;
        obj = NaN;
        return;
    end

    %  Select the predictors for this iteration
    trnX = trnX( :, info.selectX( k, : ) );
    valX = valX( :, info.selectX( k, : ) );

    
    % --------------------------------------------------------
    %  Perform over/under sampling
    % --------------------------------------------------------

    if options.sampling.doFeatureBased
        
        % resample the data specifically for this fold
        
        XNames = trnX.Properties.VariableNames;

        [ augX, augY, ~, removal ] = resampleData( ...
                            table2array( trnX ), ...
                            trnY, ...
                            'SMOTER', ...
                            options.sampling );

        
        % append the augmented data
        augX = array2table(augX);
        augX.Properties.VariableNames = XNames;
        trnX = [ trnX; augX ];          %#ok<AGROW>
        
        % append the augmented outcomes
        trnY = [ trnY; augY ]; %#ok<AGROW>

        % remove the specified rows
        trnX( removal, : ) = [];
        trnY( removal ) = [];

    end

    
    % ------------------------------------------------------------
    %  Record assignments
    % ------------------------------------------------------------        

    % record assignments
    trnIdxStart = trnIdxEnd+1;
    trnIdxEnd = trnIdxStart+length( trnY )-1;

    valIdxStart = valIdxEnd+1;
    valIdxEnd = valIdxStart+length( valY )-1;
       

    % ------------------------------------------------------------
    %  Run the model
    % ------------------------------------------------------------
    
    % check for full column rank
    HFcn = @(X)[ones(size(X,1),1),X,X.^2];
    H = HFcn( table2array(trnX) );
    if rank( H ) ~= size( H, 2 )
        % not full column rank (some FPC scores are too small)
        constraints(5) = 1;
        info = 0;
        obj = 10;
        return;
    end

    % Build the model with various options
    switch options.model.type

        case 'GPR-Bespoke'
            try
                model = fitrgp(...
                            trnX, ...
                            trnY, ...
                            'BasisFunction', options.gpr.basis, ...
                            'KernelFunction', options.gpr.kernel, ...
                            'Sigma', options.gpr.sigmaN0, ...
                            'ConstantSigma', options.gpr.constSigma, ...
                            'SigmaLowerBound', options.gpr.sigmaMin, ...
                            'Standardize', options.gpr.standardize );
            catch
                constraints(2) = 999;
                info = 0;
                obj = NaN;
                return;
            end

        case 'SVM-Bespoke'
            model = fitrsvm(...
                        trnX, ...
                        trnY, ...
                        'KernelFunction', options.svm.kernel, ...
                        'BoxConstraint', options.svm.boxConstraint, ...
                        'KernelScale', options.svm.kernelScale, ...
                        'Epsilon', options.svm.epsilon, ...
                        'Standardize', options.svm.standardize );
                    
        case 'LR-Bespoke'
            trnX = table2array( trnX );
            valX = table2array( valX );
            model = fitrlinear(...
                        trnX, ...
                        trnY, ...
                        'Lambda', options.lr.lambdaLR, ...
                        'Regularization', options.lr.regularization, ...
                        'Learner', options.lr.learner );           
            
        case 'LR'
            trnX = table2array( trnX );
            valX = table2array( valX );
            model = fitlm(...
                        trnX, ...
                        trnY, ...
                        'linear' );
                                                                                                                                  
        case 'LR-RDG'
            trnX = table2array( trnX );
            valX = table2array( valX );
            lambda = 1E-2;
            [model, fitInfo ]  = fitrlinear(...
                        trnX, ...
                        trnY, ...
                        'Lambda', lambda, ...
                        'Regularization', 'Ridge', ...
                        'Learner', 'LeastSquares' ); 
        
        case 'LR-LSS'
            trnX = table2array( trnX );
            valX = table2array( valX );
            lambda = 1E-3;
            [model, fitInfo ]  = fitrlinear(...
                        trnX, ...
                        trnY, ...
                        'Lambda', lambda, ...
                        'Regularization', 'Lasso', ...
                        'Learner', 'SVM' ); 
                           
        case 'ELST'
            trnX = table2array( trnX );
            valX = table2array( valX );
            lambda = 0.0001;
            [B, fitInfo ]  = lasso(...
                        trnX, ...
                        trnY, ...
                        'Alpha', 0.5, ...
                        'Lambda', lambda ); 
                    
        case 'TR'
            model = fitrtree(...
                        trnX, ...
                        trnY, ...
                        'MinLeafSize', 1 ); 
        
        case 'TR-ENS'
            model = fitrensemble(...
                        trnX, ...
                        trnY, ...
                        'Method', 'LSBoost', ...
                        'NumLearningCycles', 35, ...
                        'LearnRate', 0.2 ); 
        
        case 'SVM-L'
            model = fitrsvm(...
                        trnX, ...
                        trnY, ...
                        'KernelFunction', 'linear', ...
                        'BoxConstraint', 0.0011, ...
                        'KernelScale', 0.097, ...
                        'Epsilon', 0.167 );
        
        case 'SVM-G'
            model = fitrsvm(...
                        trnX, ...
                        trnY, ...
                        'KernelFunction', 'gaussian', ...
                        'BoxConstraint', 302, ...
                        'KernelScale', 38.6, ...
                        'Epsilon', 0.083 );
        
        case 'GPR-SE'
            model = fitrgp(...
                        trnX, ...
                        trnY, ...
                        'KernelFunction', 'SquaredExponential', ...
                        'Sigma', 2.2 );
        
        case 'GPR-M52'
            model = fitrgp(...
                        trnX, ...
                        trnY, ...
                        'KernelFunction', 'Matern52', ...
                        'Sigma', 1.8 );
        
        case 'NN-5'
            net = feedforwardnet( 5 );

            combX = table2array( [ trnX; valX ] )';
            combY = [ trnY; valY ]';
            
            net.divideFcn = 'divideind';
            net.divideParam.trainInd = 1:length(trnY);
            net.divideParam.valInd = length(trnY)+(1:length(valY));
            
            net.trainParam.epochs = 50;
            net.trainParam.showWindow = false;

            net = train( net, combX, combY ); 
        
        case 'NN-10'
            net = feedforwardnet( 10 );

            combX = table2array( [ trnX; valX ] )';
            combY = [ trnY; valY ]';
            
            net.divideFcn = 'divideind';
            net.divideParam.trainInd = 1:length(trnY);
            net.divideParam.valInd = length(trnY)+(1:length(valY));
            
            net.trainParam.epochs = 50;
            net.trainParam.showWindow = false;

            net = train( net, combX, combY ); 
            
        case 'CTREE'
            model = fitctree(...
                        trnX, ...
                        trnY ); 
                    
        case 'CTREE-E'
            model = fitcensemble(...
                        trnX, ...
                        trnY ); 
                    
        case 'CKNN'
            model = fitcknn(...
                        trnX, ...
                        trnY ); 

        case 'CSVM'
            model = fitcsvm(...
                        trnX, ...
                        trnY ); 
                    
    end


    % ------------------------------------------------------------
    %  Generate predictions from the model
    % ------------------------------------------------------------

    switch options.model.type
        
        case {'GPR-Bespoke', 'SVM-Bespoke', 'LR-Bespoke', ...
                'LR', 'LR-RDG', 'LR-LSS', ...
                'TR', 'TR-ENS', ...
                'SVM-L', 'SVM-G', ...               
                'GPR-SE', 'GPR-M52', ...
                'CTREE', 'CTREE-E', 'CKNN', 'CSVM' }
            info.valYhat( valIdxStart:valIdxEnd ) = predict( model, valX );
            info.trnYhat( trnIdxStart:trnIdxEnd ) = predict( model, trnX );
            
        case {'ELST'}
            info.valYhat( valIdxStart:valIdxEnd ) = ...
                                    fitInfo.Intercept+valX*B;
            info.trnYhat( trnIdxStart:trnIdxEnd ) = ...
                                    fitInfo.Intercept+trnX*B;
                                
        case {'NN-5', 'NN-10'}
            info.valYhat( valIdxStart:valIdxEnd ) = ...
                                    net( table2array(valX)' )';
            info.trnYhat( trnIdxStart:trnIdxEnd ) = ...
                                    net( table2array(trnX)' )';
                                
    end

    % record the training and validation values for this partition
    if isa( trnX, 'table' )
        info.trnX( trnIdxStart:trnIdxEnd, : ) = table2array( trnX );
    else
        info.trnX( trnIdxStart:trnIdxEnd, : ) = trnX;
    end
    info.trnY( trnIdxStart:trnIdxEnd ) = trnY;
    info.valY( valIdxStart:valIdxEnd ) = valY;
    
    % record the squared errors
    info.sqerr( valIdxStart:valIdxEnd ) = ...
                (info.valYhat( valIdxStart:valIdxEnd ) ...
                   - info.valY( valIdxStart:valIdxEnd ) ).^2;
    
    % calculate the loss for the fold
    info.foldLoss( k ) = sqrt( sum(info.sqerr(valIdxStart:valIdxEnd)) / ...
                            (valIdxEnd-valIdxStart+1) );

              
end

% record the final model (specific split requested)
if specificSplit
    info.model = model;
end

if options.model.type(1) == 'C'
    % calculate the loss (accuracy) across all folds
    info.loss = nnz( info.valYhat==info.valY ) / nCasesValid;
    info.resubLoss = nnz( info.trnYhat==info.trnY ) / nCasesTrain;
else
    % calculate the loss (RMSE) across all folds
    info.loss = sqrt( sum((info.valYhat-info.valY).^2) / nCasesValid );
    info.resubLoss = sqrt( sum((info.trnYhat-info.trnY).^2) / nCasesTrain );
end

% calculate the R squared value across all folds
info.rsq = corr( info.valYhat, info.valY ).^2;

% convert to a percentage error, if required
if options.optimize.percentLoss
    info.loss = 100*info.loss/mean( info.valY );
    info.resubLoss = 100*info.resubLoss/mean( info.trnY );
    info.foldLoss = 100*info.foldLoss/mean( info.valY );
end

% calculate the in-fold validation RMSE and its variance
info.lossFoldMean = mean( info.foldLoss );
info.lossFoldSD = std( info.foldLoss );
info.lossFoldCV = info.lossFoldSD/info.lossFoldMean;

info.lossFoldMedian = median( info.foldLoss );
info.lossFoldIQR = iqr( info.foldLoss );
info.lossFoldQ1 = prctile( info.foldLoss, 25 );
info.lossFoldQ3 = prctile( info.foldLoss, 75 );


% calculate the RMSE for each quartile
info.lossQuartile = quartileLoss( info.valY, info.valYhat );

% calculate the objective function
switch options.optimize.objective
    case 'Loss'
        obj = info.loss;
    case 'ResubLoss'
        obj = info.resubLoss;
    case 'LossFoldMean'
        obj = info.lossFoldMean;
    case 'LossFoldMedian'
        obj = info.lossFoldMedian;
    case 'LossQ1'
        obj = info.lossQuartile(1);
    case 'LossQ2'
        obj = info.lossQuartile(2);
    case 'LossQ3'
        obj = info.lossQuartile(3);
    case 'LossQ4'
        obj = info.lossQuartile(4);
    otherwise
        error('Unrecognised objective.');
end


end


