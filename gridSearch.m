% ************************************************************************
% Function: gridSearch
% Purpose:  Model selection with grid search using the full dataset
%           All partitioning is within the accModelRun
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

function result = gridSearch( data, options )


opt = options.optimize;
optPlot = options.plot.full;

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
    nModels = options.part.select.iterations;
    trnSelect = true( length( data.outcome ), nModels );
    valSelect = false( length( data.outcome ), nModels );
end

%[ trnSelect, valSelect ] = partitionData(  data.outcome, ...
%                            data.subject, ...
%                            options.part.select );
                        

% ------------------------------------------------------------
%   Setup the grid search
% ------------------------------------------------------------

v = opt.activeVar;
nVar = length( v );

hp = cell( nVar, 1 );
result.range = cell( nVar, 1 );
result.grp = strings( nVar, 1 );
result.var = strings( nVar, 1 );
result.descr = strings( nVar, 1 );
result.lim = cell( nVar, 1 );
result.isLog = false( nVar, 1 );
result.varDef = cell( nVar, 1 );
varTypes = cell( nVar, 1 );
nLevels = ones( 2, 1 );

for i = 1:nVar
    result.fcn{i} = opt.fcn{ v(i) };
    result.grp(i) = opt.grp( v(i) );
    result.var(i) = opt.var( v(i) );
    result.descr(i) = opt.descr( v(i) );
    result.lim(i) = opt.lim( v(i) );
    result.isLog(i) = opt.isLog( v(i) );
    result.varDef(i) = {opt.varDef( v(i) )};
    switch opt.varDef( v(i) ).Type
        case 'categorical'
            varTypes{i} = 'string';
            result.range{i} = opt.varDef( v(i) ).Range;
        case {'real', 'integer'}
            varTypes{i} = 'double';
            result.range{i} = opt.varDef( v(i) ).Range(1): ...
                        opt.varDef( v(i) ).Range(2);
    end
    nLevels(i) = length( result.range{i} );
end


result.ObjectiveTrace = zeros( nLevels(1)*nLevels(2)*options.nRuns, 1 );

result.XTrace = table( 'Size', [nLevels(1)*nLevels(2)*options.nRuns, nVar], ...
                        'VariableTypes', varTypes, ...
                        'VariableNames', result.var );

result.InnerObjective = zeros( options.part.inner.iterations, ...
                                nLevels(1)*nLevels(2)*options.nRuns );
                            
result.LossMean = zeros( nLevels(1)*nLevels(2)*options.nRuns, 1 );
result.LossSD = zeros( nLevels(1)*nLevels(2)*options.nRuns, 1 );  

result.gcv = zeros( nLevels(1)*nLevels(2)*options.nRuns, 1 ); 
result.df = zeros( nLevels(1)*nLevels(2)*options.nRuns, 1 ); 

result.score = zeros( nLevels(1)*nLevels(2)*options.nRuns, ...
                            options.fpca.nRetainedComp ); 
result.varprop = zeros( nLevels(1)*nLevels(2)*options.nRuns, ...
                            options.fpca.nRetainedComp ); 
result.peak = zeros( nLevels(1)*nLevels(2)*options.nRuns, ...
                            options.fpca.nRetainedComp ); 
                        
% ------------------------------------------------------------
%   Repeat the grid search for a number of repetitions
% ------------------------------------------------------------

modelOutputPlot( [], 'initial', opt );

c = 0;

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
disp([ 'Partitioning = ' options.part.inner.method ]);
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

for k = 1:options.nRuns

    disp(['Iteration = ' num2str(k)]);
    
    tic;
    
    % ------------------------------------------------------------
    %   Run the grid search
    % ------------------------------------------------------------

    for j = 1:nLevels(2)  % 'reference' variable
        
        if nVar == 2
            if strcmp( result.varDef{2}.Type, 'categorical' )
                hp{2} = result.fcn{2}(j);
                hpchar = char( hp{2} );
            else
                hp{2} = result.range{2}(j);
                hpchar = num2str( hp{2} );
            end               
            disp(['Reference = ' char(result.grp(2)) ' - ' ...
                                char(result.var(2)) ' = ' ...
                                hpchar ]);
        end
            
        for i = 1:nLevels(1)  % 'fitted' variable

            if strcmp( result.varDef{1}.Type, 'categorical' )
                hp{1} = result.fcn{1}(i);
                hpchar = char( hp{1} );
            else
                hp{1} = result.range{1}(i);
                hpchar = num2str( hp{1} );
            end

            disp(['Grid search = ' char(result.grp(1)) ' - ' ...
                            char(result.var(1)) ' = ' ...
                            hpchar ]);
            
            % run the model for this pair of parameters

            [ obj, ~, modelOutput ] = accModelRun(   ...
                                       data, ...
                                       'Repeated', ...
                                       trnSelect( :, k ), ...
                                       valSelect( :, k ), ...
                                       options, ...
                                       hp );          
                                   
            if ~isnan(obj) % not an invalid run
                c = c + 1;
                result.InnerObjective( :, c ) = modelOutput.foldLoss;
                result.ObjectiveTrace( c ) = obj;
                result.LossMean( c ) = modelOutput.lossFoldMean;
                result.LossSD( c ) = modelOutput.lossFoldSD;
                if strcmp( result.varDef{1}.Type, 'categorical' )
                    result.XTrace.(result.var(1))( c ) = hp{1};                   
                else
                    result.XTrace.(result.var(1))( c ) =  opt.fcn{v(1)}(hp{1});
                end
                if nVar == 2
                    if strcmp( result.varDef{2}.Type, 'categorical' )
                        result.XTrace.(result.var(2))( c ) = hp{2};                   
                    else
                        result.XTrace.(result.var(2))( c ) =  opt.fcn{v(2)}(hp{2});
                    end
                end
                result.gcv( c ) = modelOutput.gcv;
                result.df( c ) = modelOutput.df;
%                result.score( c, : ) = mean( modelOutput.score );
%                result.varprop( c, : ) = mean( modelOutput.varprop );
%                result.peak( c, : ) = mean( modelOutput.peak );
            end
                       
        end
        
        if any(strcmp( opt.plotType, {'Line', 'Box'} ))
            modelOutputPlot( result, 'iteration', opt, optPlot );
        end

    end
    
    if any(strcmp( opt.plotType, {'Contour', 'Surface'} ))
        modelOutputPlot( result, 'iteration', opt, optPlot );
    end
    
    computeTime = toc;
    disp(['Computation Time = ' num2str(computeTime)]);
    
end


end
    
    