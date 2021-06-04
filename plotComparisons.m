% ************************************************************************
% Script:   plotComparisons
% Purpose:  Read spreadsheet wih outputs from optimisations
%           and plot results for publication
%
%
% ************************************************************************

path = '/Users/markgewhite/Google Drive/PhD/Studies/Jumps/Analysis/PLOS ONE';
filename = 'Outer Validation RMSE (P1-017).xlsx';
varTypes = { 'char', 'char', 'char', 'char', 'single', 'double', 'double' };

excelOpts = spreadsheetImportOptions( 'NumVariables', 7, ...
                                     'Sheet', 'ValRMSE', ...
                                     'DataRange', 2, ...
                                     'VariableNamesRange', 1, ...
                                     'PreserveVariableNames', true, ...
                                     'VariableTypes', varTypes );

signalOrder = { 'Resultant', 'Triaxial' };
modelOrder = { 'LR', 'SVM', 'GPR' };
sensorOrder = { 'LB', 'UB', 'LS', 'RS' };
jumptypeOrder = { 'WOA', 'WA' };

data = readtable( fullfile( path, filename ), excelOpts );
data.Signal = categorical( data.Signal, signalOrder );
data.Model = categorical( data.Model, modelOrder );
data.Sensor = categorical( data.Sensor, sensorOrder );
data.JumpType = categorical( data.JumpType, jumptypeOrder );


figObj = figure;

% signal box plot
ax(1) = subplot(2,4,1);
boxObj{1} = boxchart(  ax(1), data.Signal, data.ValRMSE );
xlabel( ax(1), 'Signal Representation');
ylabel( ax(1), 'Outer Val. RMSE W\cdotkg^{-1}');   

% model box plot
ax(2) = subplot(2,4,2);
boxObj{2} = boxchart(  ax(2), data.Model, data.ValRMSE );
xlabel( ax(2), 'Model Type');

% sensor box plot
ax(3) = subplot(2,4,3);
boxObj{3} = boxchart(  ax(3), data.Sensor, data.ValRMSE );
xlabel( ax(3), 'Sensor Location');

% jump type box plot
ax(4) = subplot(2,4,4);
boxObj{4} = boxchart(  ax(4), data.JumpType, data.ValRMSE );
xlabel( ax(4), 'Jump Type');
ax(4).XTickLabel = { 'CMJ_{NA}', 'CMJ_{A}' }; 

% model & sensor combination plot
data.ModelSensor = categorical( data.Sensor.*data.Model );
subsetID = data.Signal=='Resultant' & data.JumpType=='WOA';
subset = data( subsetID, : );

ax(5) = subplot(2,1,2);
boxObj{5} = boxchart(  ax(5), subset.ModelSensor, subset.ValRMSE );
xlabel( ax(5), 'Sensor Location & Model Type Combinations');
ylabel( ax(5), 'Outer Val. RMSE W\cdotkg^{-1}');   

row2Pos = ax(5).Position;

for i = 1:5
    
    if i < 5
        ylim( ax(i), [1,10]);
        ms = 3;
        labelX = 0.04;
        labelY = 1.05;
        subPos = ax(i).Position;
        ax(i).Position = [ subPos(1) subPos(2)+0.03 subPos(3) subPos(4)-0.02 ];
    else
        ylim( ax(i), [1,8]);
        ms = 4;
        labelX = 0.01;
        labelY = 1.05;
        subPos = ax(i).Position;
        ax(i).Position = [ subPos(1) subPos(2)+0.02 subPos(3) subPos(4) ];
    end
    
    for j = 1:length(boxObj{i})
        boxObj{i}(j).JitterOutliers = 'on';
        boxObj{i}(j).MarkerStyle = 'x';
        boxObj{i}(j).MarkerSize = ms;
    end

    text( ax(i), labelX, labelY, ['(' char(64+i) ')'], ...
                'Units', 'normalized', ...
                'FontName', 'Arial', ...
                'FontSize', 10 );
    
    set( ax(i), 'FontName', 'Arial' );
    set( ax(i), 'FontSize', 9 );
    set( ax(i), 'LineWidth', 1 );
    set( ax(i), 'Box', false );
    set( ax(i), 'TickDir', 'out' );

end
     







