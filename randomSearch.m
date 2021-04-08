% ************************************************************************
% Function: randomSearch
% Purpose:  Model selection with a random search with optimisation 
%           applied on the resulting parameter space.
%
%
% Parameters:
%       data
%       options
%       hyperparameters
%
% Output:
%       bestHP: optimal hyperparameter values
%
% ************************************************************************

function result = randomSearch( data, options )


opt = options.optimize;
opt.plot = options.plot.full;

% ------------------------------------------------------------
%   Set all model to use all data - no outer partitioning
% ------------------------------------------------------------

if options.part.select.kFolds > 1 
    options.part.select.doControlRandomisation = true;
    options.part.select.randomSeed = input('Random Seed (Outer Partitioning) = ');
    nModels = options.part.select.iterations;
    [ trnSelect, valSelect ] = partitionData(  data.outcome, ...
                                     data.subject, ...
                                     options.part.select );
else
    nModels = 1; %options.part.select.iterations;
    trnSelect = true( length( data.outcome ), nModels );
    valSelect = false( length( data.outcome ), nModels );
end
    

% ------------------------------------------------------------
%   Setup model-specific results structure
% ------------------------------------------------------------

v = opt.activeVar;
nVar = length( v );
nDim = 1+~options.preproc.useResultant*2;
nPredictors = options.fpca.nRetainedComp* ...
                (1 + ~options.preproc.useResultant*2)* ...
    (1 + options.data.doMultiCurves*((length(options.data.curves)+1)/4-1));

hp = cell( nVar, 1 );
hpIndex = zeros( nVar, 1 );

result = cell( nModels, 1 );

for m = 1:nModels

    result{m}.range = cell( nVar, 1 );
    result{m}.grp = strings( nVar, 1 );
    result{m}.var = strings( nVar, 1 );
    result{m}.descr = strings( nVar, 1 );
    result{m}.lim = cell( nVar, 1 );
    result{m}.isLog = false( nVar, 1 );
    result{m}.isCat = false( nVar, 1 );
    result{m}.varDef = cell( nVar, 1 );
    varTypes = cell( nVar, 1 );
    nLevels = ones( 2, 1 );
    result{m}.lowerBounds = zeros( nVar, 1 );
    result{m}.upperBounds = zeros( nVar, 1 );
    result{m}.doRounding = false( nVar, 1 );

    for i = 1:nVar
        result{m}.fcn{i} = opt.fcn{ v(i) };
        result{m}.grp(i) = opt.grp( v(i) );
        result{m}.var(i) = opt.var( v(i) );
        result{m}.descr(i) = opt.descr( v(i) );
        result{m}.lim(i) = opt.lim( v(i) );
        result{m}.isLog(i) = opt.isLog( v(i) );
        result{m}.isCat(i) = opt.isCat( v(i) );
        result{m}.varDef(i) = {opt.varDef( v(i) )};
        switch opt.varDef( v(i) ).Type
            case 'categorical'
                varTypes{i} = 'categorical';
                result{m}.range{i} = opt.varDef( v(i) ).Range;
            case 'integer'
                varTypes{i} = 'double';
                result{m}.range{i} = opt.varDef( v(i) ).Range(1): ...
                            opt.varDef( v(i) ).Range(2);
            case 'real'
                varTypes{i} = 'double';
                result{m}.range{i} = [opt.varDef( v(i) ).Range(1), ...
                            opt.varDef( v(i) ).Range(2) ];
        end
        nLevels(i) = length( result{m}.range{i} );
        result{m}.lowerBounds(i) = opt.bounds{ v(i) }(1);
        result{m}.upperBounds(i) = opt.bounds{ v(i) }(2);
        result{m}.doRounding(i) = ~strcmp(opt.varDef( v(i) ).Type, ...
                                'real') || opt.allGranular;
    end
    
    doRound = result{m}.doRounding; % shorthand
    
    result{m}.ObjectiveTrace = ...
                zeros( opt.randomSearchUpdate*options.nRuns, 1 );
    
    result{m}.XTrace = table( ...
                'Size', [opt.randomSearchUpdate*options.nRuns, nVar], ...
                'VariableTypes', varTypes, ...
                'VariableNames', result{m}.var );
            
    result{m}.InnerObjective = ...
                zeros( opt.randomSearchUpdate*options.nRuns,...
                                    options.part.inner.iterations );
                            
    result{m}.XTraceIndex = ...
                zeros( opt.randomSearchUpdate*options.nRuns, nVar );

    result{m}.pso.Xidx = zeros( options.nRuns, nVar );
    result{m}.pso.X = table(    'Size', [options.nRuns, nVar], ...
                                'VariableTypes', varTypes, ...
                                'VariableNames', result{m}.var );
    result{m}.pso.obj = zeros( options.nRuns, 1 );
    result{m}.pso.modelSD = zeros( options.nRuns, 1 );
    result{m}.pso.noise = zeros( options.nRuns, 1 );
    
    result{m}.optLoss = zeros( options.nRuns, 1 );
    result{m}.optLossMean = zeros( options.nRuns, 1 );
    result{m}.optLossSD = zeros( options.nRuns, 1 );
    
    result{m}.outerLoss = zeros( options.nRuns, 1 );
    result{m}.outerLossMean = zeros( options.nRuns, 1 );
    
    result{m}.predCorr = zeros( opt.randomSearchUpdate*options.nRuns,...
                                nPredictors );
    
    result{m}.predRank = zeros( opt.randomSearchUpdate*options.nRuns,...
                                nPredictors );
                            
    result{m}.selection = zeros( opt.randomSearchUpdate*options.nRuns,...
                                nPredictors );

end


varConv.fcn = result{1}.fcn;
varConv.varDef = result{1}.varDef;
varConv.range = result{1}.range;
varConv.isLog = result{1}.isLog;


%varCombo = combnk( 1:nVar, 2 );
varCombo = (1:nVar)';
if ~strcmp( options.optimize.plotType, 'None')
    nCombo = size( varCombo, 1 );
else
    nCombo = 0;
end

% ------------------------------------------------------------
%   Setup the optimization options
% ------------------------------------------------------------
                      
                            
optionsPSO = optimoptions('particleswarm', ...
                    'Display', 'Final', ...
                    'FunctionTolerance', opt.tolPSO, ...
                    'MaxIterations', opt.maxIter );                               

                
% ------------------------------------------------------------
%   Repeat the random search for a number of repetitions
% ------------------------------------------------------------

disp([ 'Arms = ' options.data.arms ]);
disp([ 'Sex = ' options.data.sex ]);
disp([ 'Level = ' options.data.perfLevel] );
disp([ 'Curves = ' options.data.curves ]);
disp([ 'Measure = ' options.data.measure ]);
disp(' ');
disp([ 'PreLength  = ' num2str(options.preproc.tLength1) ' ms' ]);
disp([ 'PostLength = ' num2str(options.preproc.tLength2) ' ms' ]);
disp([ 'Jump Detection = ' options.data.jumpDetection ]);
disp([ 'Basis Functions  = ' num2str(options.fda.nBasis) ]);
disp([ 'Use Density = ' num2str(options.fda.useDensity) ]);
disp([ 'Roughness Penalty = ' num2str(options.fda.lambda,'%5.0e') ]);
disp(' ');
disp([ 'Model = ' options.model.type ]);
disp([ 'Outer Iterations = ' num2str(options.nRuns) ]);
disp([ 'Optimiser Iterations = ' num2str(options.optimize.maxObjEval1) ]);
disp([ 'Inner Iterations = ' num2str(options.part.inner.iterations) ]);
disp([ 'Select K-Folds = ' num2str(options.part.select.kFolds) ]);
disp([ 'Inner K-Folds  = ' num2str(options.part.inner.kFolds) ]);
disp([ 'Number of Jumps = ' num2str(length(data.outcome)) ]);
disp(' ');
disp([ 'FPCA Partitioning  = ' num2str(options.fpca.doFPCApartitioning) ]);
disp([ 'Retained Components  = ' num2str(options.fpca.nRetainedComp) ]);
disp([ 'Warp Components = ' num2str(options.fpca.nRetainedCompWarp) ]);
disp(' ');

mStart = input('Outer Fold Start = ');
mEnd = input('Outer Fold End = ');

for m = mStart:mEnd
    
    disp(['Model = ' num2str(m)]);
    
    c = 0;
    
    % set a new seed for this set of models
    % that will be used in partitioning
    rng( 'shuffle' );
    options.part.inner.randomSeed = floor(rand*10000);
    disp(['PARTITION SEED = ' num2str(options.part.inner.randomSeed)]);
    
    % ------------------------------------------------------------
    %   Setup model-specific plots
    % ------------------------------------------------------------

    for i = 1:nCombo
        modelContourPlot( (m-1)*nCombo+i, [], [], [], [], 'initial', opt );
    end
    
    if opt.doSMValidation
        result{m}.ValidationTrace = ...
                zeros( opt.randomSearchUpdate*options.nRuns, 1 );
    end

    randomState = rng; % store initial random state
    for k = 1:options.nRuns

        disp(['Iteration = ' num2str(k)]);

        tic;

        % ------------------------------------------------------------
        %   Random search
        % ------------------------------------------------------------
        
        if k > 1 && opt.doConvergence
            % restrict search to loss less than a
            % progressively reducing proportion of previous minimum
            alpha = max(1 - k/opt.nRamp, 1);
            maxLoss = (1+alpha)*result{m}.pso.obj(k-1);
        else
            % start with the initial specified maximum
            maxLoss = opt.initMaxLoss;
        end

        rng( randomState ); % restore random state where it left off
        for j = 1:opt.randomSearchUpdate-1 % one less for optimum obs.

            if mod(j,opt.dotUpdate) == 0
                fprintf('.');
            end
            
            obj = NaN;
            nTry = 0;
            while (isnan( obj ) || obj > maxLoss) && nTry <= opt.maxTries % repeat until the model is valid

                inRange = false;
                while ~inRange
                
                    % randomly select the parameter values
                    if opt.allGranular
                        % all parameters granular
                        for i = 1:nVar      
                            hpIndex(i) = randi( nLevels(i) );
                            if strcmp( result{m}.varDef{i}.Type, 'categorical' )
                                hp{i} = result{m}.fcn{i}( hpIndex(i) );
                            else
                                hp{i} = result{m}.range{i}( hpIndex(i) );
                            end               
                        end
                    else
                        % only categorical parameters are granular
                        % numerical parameters are real or integer
                        for i = 1:nVar
                            switch result{m}.varDef{i}.Type
                                case 'categorical'
                                    hpIndex(i) = randi( nLevels(i) );
                                    hp{i} = result{m}.fcn{i}( hpIndex(i) );
                                case 'integer'
                                    hpIndex(i) = randi( nLevels(i) );
                                    hp{i} = result{m}.range{i}( hpIndex(i) );
                                case 'real'
                                    hpIndex(i) = min(result{m}.range{i}) + ...
                                        rand*(max(result{m}.range{i}) ...
                                          - min(result{m}.range{i}));
                                    hp{i} = hpIndex(i);
                            end               
                        end
                    end
                        
                    if k > 1
                        % model exists (after first iteration)
                        % get prediction of what this model error would be
                        estLoss = predict( result{m}.objModel, hpIndex' );
                        if estLoss < maxLoss
                            inRange = true;
                        else
                            % compute probability of accepting params
                            % based on normal distribution of
                            % sigma = half the SD of observations
                            sigma = 0.5*std( result{m}.ObjectiveTrace(1:c) );
                            pAccept = exp(-0.5*((estLoss-maxLoss)/sigma)^2);
                            inRange = rand<pAccept;
                        end
                        
                    else
                        % no objective model yet (first iteration)
                        inRange = true;
                    end
                    % inRange = true; %ALWAYS
                    nTry = nTry+1;
                
                end
                if nTry > opt.maxTries
                    disp('Attempts to find suitable point exceeded maximum');
                end

                % run the model for this set of parameters
                [ obj, ~, modelOutput ] = accModelRun(   ...
                                       data, ...
                                       'Repeated', ...
                                       trnSelect( :, m ), ...
                                       valSelect( :, m ), ...
                                       options, ...
                                       hp );

            end


            % store the results
            c = c + 1; 
            result{m}.InnerObjective( c, : ) = modelOutput.foldLoss;
            result{m}.XTraceIndex( c, : ) = hpIndex;
            result{m}.ObjectiveTrace( c ) = obj;
            for i = 1:nVar
                result{m}.XTrace.(result{m}.var(i))( c ) = hp{i};
            end
    
            % validate the surrogate models
            if opt.doSMValidation
                result{m}.ValidationTrace( c ) = ...
                    predict( surrogateModel, hpIndex' );
            end

        end

        randomState = rng; % preserve random state
        
        fprintf('\n');

        % ------------------------------------------------------------
        %   Optimisation - find minimum in parameter space
        % ------------------------------------------------------------

        result{m}.objModel = fitrgp(  ...
                            result{m}.XTraceIndex( 1:c, : ), ...
                            result{m}.ObjectiveTrace( 1:c ), ...
                            'CategoricalPredictors', result{m}.isCat, ...
                            'BasisFunction', 'Constant', ... 
                            'KernelFunction', 'ARDMatern52', ...
                            'Standardize', false );
                        
                        
        objFcn = @(param) modelEvaluationPSO2( result{m}.objModel, ...
                                               param, ...
                                               doRound );
                                           
        optimum = particleswarm(    objFcn, ...
                                    nVar, ...
                                    result{m}.lowerBounds, ...
                                    result{m}.upperBounds, ...
                                    optionsPSO );
                                
        result{m}.optimum( doRound ) = round( optimum( doRound ) );
        result{m}.optimum( ~doRound ) = optimum( ~doRound );

        result{m}.pso.Xidx( k, : ) = result{m}.optimum;                
        result{m}.pso.obj( k ) = objFcn( result{m}.optimum );

        result{m}.optValues = pso2BayesVarConv( result{m}.optimum, ...
                                                  varConv );
        result{m}.pso.X( k, : ) = result{m}.optValues;
        result{m}.pso.noise( k ) = result{m}.objModel.Sigma;
        [ ~, result{m}.pso.modelSD( k ) ] = ...
                        predict( result{m}.objModel, result{m}.optimum );

        disp(['Particle Swarm Optimum = ' num2str( optimum ) ]);


        % ------------------------------------------------------------
        %   Report results
        % ------------------------------------------------------------

        disp( result{m}.optValues );


        disp( ['Surogate Model: Loss = ' num2str( result{m}.pso.obj(k) ) ...
                    ' +/- ' num2str( result{m}.pso.modelSD(k) ) ...
                    '; noise = ' num2str( result{m}.pso.noise(k) )] );
                
        % ------------------------------------------------------------
        %   Inner Loss
        % ------------------------------------------------------------                

        [ obj, ~, modelOutput ] = ...
                    accModelRun(   ...
                                   data, ...
                                   'Repeated', ...
                                   trnSelect( :, m ), ...
                                   valSelect( :, m ), ...
                                   options, ...
                                   result{m}.optValues );             
        
        % store the results
        c = c + 1;
        
        if ~isnan( obj )
            obj = min( obj, maxLoss ); % prevent instability
            result{m}.optLoss(k) = obj;
            result{m}.InnerObjective( c, : ) = modelOutput.foldLoss;
            result{m}.XTraceIndex( c, : ) = result{m}.optimum;
            result{m}.ObjectiveTrace( c ) = obj;
            result{m}.XTrace(c,:) = result{m}.optValues;
            result{m}.optLossMean(k) = modelOutput.lossFoldMean;
            result{m}.optLossSD(k) = modelOutput.lossFoldSD;

            disp( ['Inner Model:   Loss = ' ...
                    num2str( result{m}.optLoss(k) ) ' (aggr.); ' ...
                    num2str( result{m}.optLossMean(k) ) ' +/- ' ...
                    num2str( result{m}.optLossSD(k) ) ] );

            % ------------------------------------------------------------
            %   Outer Loss
            % ------------------------------------------------------------                

            if options.part.select.kFolds > 1

                [ obj, ~, modelOutput ] = ...
                        accModelRun(   data, ...
                                       'Specified', ...
                                       trnSelect( :, m ), ...
                                       valSelect( :, m ), ...
                                       options, ...
                                       result{m}.optValues );

                if ~isnan( obj )
                    % valid result
                    result{m}.outerLoss(k) = obj;
                    result{m}.outerLossMean(k) = modelOutput.lossFoldMean;
                    disp( ['Outer Model:   Loss = ' ...
                            num2str( result{m}.outerLoss(k) ) ' (aggr.); ' ...
                            num2str( result{m}.outerLossMean(k) ) ] );
                else
                    % invalid
                    disp( 'Actual Model:   INVALID');
                end

            end    

        else
            
            % for an invalid model
            % store an adverse result, to dissuade future PSOs
            % but not so high that it causes distortions
            result{m}.ObjectiveTrace( c ) = ...
                prctile( result{m}.ObjectiveTrace(1:c-1), 75 );
            result{m}.XTrace(c,:) = result{m}.optValues;
            result{m}.XTraceIndex( c, : ) = result{m}.optimum;
            disp('INVALID');
        
        end
        
        
        % ------------------------------------------------------------
        %   Plot contour sets
        % ------------------------------------------------------------

        for i = 1:nCombo
            modelContourPlot( (m-1)*nCombo+i, varCombo(i,:), ...
                                result{m}.optimum, ...
                                [], result{m}, 'iteration', opt );
        end

        computeTime = toc;
        disp(['Computation Time = ' num2str(computeTime)]);

    end

    
    % ------------------------------------------------------------
    %   Save the results to a temporary file
    % ------------------------------------------------------------

    if ismac 
        save(fullfile(options.datapath,'Random Search Temp (MAC).mat'), ...
                'result','options');
    else
        save(fullfile(options.datapath,'Random Search Temp (PC).mat'), ...
                'result','options');
    end

    
end
    
end
    
    