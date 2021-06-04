% ************************************************************************
% Function: combineOutput
% Purpose:  Combine outputs from accAnalysis for statistical reporting
%
%
% Parameters:
%       outputs: cell array of smOptimiserNCV outputs
%
%       cell array has three dimensions:
%           1: model-type
%           2: sensor
%           3: jump type
%
%       each cell is a structure of:
%           .estimate (outer validation RMSE across all folds)
%           .valFolds (per fold RMSE)
%           .optima (structure of traces recording intermediate and final)
%           .search (structure of traces recording random search)
%
% Output:
%       results: data structure of combined results from all outputs
%
% ************************************************************************

function [ results, outputs ] = combineOutput( outputs, setup )

[ nModels, nSensors, nTypes ] = size( outputs );

results.valRMSE = [];
results.params.data = [];
results.params.lr = [];
results.params.svm = [];
results.params.gpr = [];
results.glmCoeff = [];
results.glmCoeffSelect = [];
nDataParams = 7;

for i = 1:nModels
    
    for j = 1:nSensors
        
        for k = 1:nTypes
            
            if ~isempty( outputs{i,j,k} )
                
                out = outputs{i,j,k}; % shorthand
                
                % update validation RMSE table
                results.valRMSE = updateValRMSE( results.valRMSE, ...
                                         i, j, k, ...
                                         out.valFolds );
                                                                                      
                % update optimal data parameters table
                dataParams = ...
                    out.optima.XFinal( :, end-nDataParams+1:end );
                results.params.data = updateOptModel( results.params.data, ...
                                         i, j, k, ...
                                         dataParams );
                 
                % update optimal model parameters table
                switch out.optima.XFinal.Properties.VariableNames{1}
                    case 'lambdaLR'
                        results.params.lr = updateOptModel( ...
                                         results.params.lr, ...
                                         i, j, k, ...
                                         out.optima.XFinal(:,1:3) );
                    case 'kernel'
                        results.params.svm = updateOptModel( ...
                                         results.params.svm, ...
                                         i, j, k, ...
                                         out.optima.XFinal(:,1:4) );
                    case 'basis'
                        results.params.gpr = updateOptModel( ...
                                         results.params.gpr, ...
                                         i, j, k, ...
                                         out.optima.XFinal(:,1:3) );
                end                                          
                                             
                % check if GLM model exists, if not generate it
                if isfield( out, 'models' )
                    glmExists = isfield( out.models, 'glmModel' );
                else
                    glmExists = false;
                end
                if ~glmExists
                    out.models.glmModel = ...
                            genGLMModel( out.search.XTrace, ...
                                         out.search.YTrace, ...
                                         setup, false );
                    disp(['Model fitted: i= ' num2str(i) ...
                                      '; j= ' num2str(j) ...
                                      '; k= ' num2str(k) ]);
                end

                % check if GLM model exists, if not generate it
                if isfield( out, 'models' )
                    glmExists = isfield( out.models, 'glmModelSelect' );
                else
                    glmExists = false;
                end
                if ~glmExists
                    out.models.glmModelSelect = ...
                            genGLMModel( out.search.XTrace, ...
                                         out.search.YTrace, ...
                                         setup, true );
                    disp(['Select Model fitted: i= ' num2str(i) ...
                                      '; j= ' num2str(j) ...
                                      '; k= ' num2str(k) ]);
                end
                
                
                % update GLM coefficients table (no selection)
                results.glmCoeff = updateGLMCoeff( ...
                                            results.glmCoeff, ...
                                            i, j, k, ...
                                            out.models.glmModel );
                
                % update GLM coefficients table (selection)
                results.glmCoeffSelect = updateGLMCoeff( ...
                                            results.glmCoeffSelect, ...
                                            i, j, k, ...
                                            out.models.glmModelSelect );
                                               
               outputs{i,j,k} = out;
                              
            end
            
        end
        
    end

end


end




function T1 = updateValRMSE( T0, i, j, k, rmse )

nFolds = length( rmse );

catT = categoryTable( i, j, k, nFolds );

rmseT = array2table( rmse, 'VariableName', {'RMSE'} );

T1 = [ T0; catT rmseT ];

end


function T1 = updateOptModel( T0, i, j, k, paramT )

nFolds = size( paramT, 1 );

catT = categoryTable( i, j, k, nFolds );

T1 = [ T0; catT paramT ];

end


function T1 = updateGLMCoeff( T0, i, j, k, models )

c = 0;
coeffT = [];
for m = 1:length( models )
    
    % count coefficients
    nCoeff = size( models{m}.Coefficients, 1 );
    c = c + nCoeff;
    
    % create coefficients table without row labels
    coeffTm = models{m}.Coefficients;
    coeffTm.Properties.RowNames = {};
    % insert a new column for coefficient names
    coeffTm = addvars( coeffTm, ...
                       models{m}.CoefficientNames', ...
                       'Before', 'Estimate', ...
                       'NewVariableNames', {'Coefficient'} );
    
    coeffT = [ coeffT; coeffTm ];  %#ok<AGROW>
    
end

catT = categoryTable( i, j, k, c );

T1 = [ T0; catT coeffT  ];

end



function T = categoryTable( i, j, k, n )

models = {'LR', 'SVM', 'GPR' };
sensors = { 'LB', 'UB', 'LS', 'RS' };
types = { 'Both', 'WOA', 'WA' };
tableFields = { 'Model', 'Sensor', 'JumpType' };

T = table(  repelem( string(models{i}), n, 1 ), ...
            repelem( string(sensors{j}), n, 1 ), ...
            repelem( string(types{k}), n, 1 ), ...
            'VariableName', tableFields );
               
end


function model = genGLMModel( X, Y, setup, doSelect )

nObs = size( X, 1 );

nSubset = setup.nFit*setup.nRepeats*setup.nSearch;
nInter = setup.nInterTrace*setup.nRepeats*setup.nSearch;

model = cell( setup.nFit, 1 );
for i = 1:setup.nFit
    
    % select observations for the inter range for each run
    id = (nSubset-nInter+1:nSubset) + (i-1)*nSubset;
    % and remove invalid observations
    glmObs = false( nObs, 1 );
    glmObs( id ) = Y( id )~=10;
    % make table
    glmData = [ X( glmObs, : ) array2table(Y( glmObs )) ];
    glmData.Properties.VariableNames{ end } = 'Outcome';
    
    % fit model
    if doSelect
        model{i} = compact(  stepwiseglm( glmData, 'linear', ...
                  'Criterion', 'bic' ) );
    else
        model{i} = compact(  fitglm( glmData ) );
    end
        
end


end

