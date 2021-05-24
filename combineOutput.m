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

function results = combineOutput( outputs )

[ nModels, nSensors, nTypes ] = size( outputs );

% find which outputs are included

models = {'LR', 'SVM', 'GPR' };
sensors = { 'LB', 'UB', 'LS', 'RS' };
types = { 'Both', 'WOA', 'WA' };
tableFields = { 'Model', 'Sensor', 'JumpType', 'ValRMSE' };

c = 0;

for i = 1:nModels
    
    for j = 1:nSensors
        
        for k = 1:nTypes
            
            if ~isempty( outputs{i,j,k} )
                
                % generate category table of required length
                out = outputs{i,j,k};
                nFolds = length( out.valFolds );
                catTable = table(  repelem( models(i), nFolds, 1 ), ...
                                   repelem( sensors(j), nFolds, 1 ), ...
                                   repelem( types(k), nFolds, 1 ), ...
                                   'VariableName', tableFields(1:3) );
                
               
                % add validation RMSE
                outcome = array2table( out.valFolds, ...
                                       'VariableName', tableFields(4) );

                newTable = [ catTable outcome ];

                if c == 0
                    results.valRMSE = newTable;
                else
                    results.valRMSE = [ results.valRMSE; newTable ];
                end

                c = c+1;
               
            end
            
        end
        
    end

end


end

