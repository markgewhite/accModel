% ************************************************************************
% Function: plotModelFitSmooth
% Purpose:  Plot observed vs predicted - smoothed
%
% Parameters:
%       type: 'Validity' or 'Residual'
%       plotName: title for the plot
%       obs: observed
%       pred: predicted
%       axMin: axis min
%       axMax: axis max
%       resMax: residual max (optional)
%
% Output:
%       model: smooth fitted line
%       Plot in current figure
%
% ************************************************************************

function [ model, predSmooth ] = plotModelFitSmooth( ...
                obs, pred, colour, usePercent, showPoints, ...
                xMin, xMax, yMax, opt )
            
if usePercent
    y = 100*abs(pred-obs)./pred;
else
    y = abs(pred-obs);
end

model = fitrgp(  obs, y, ...
                    'BasisFunction', 'pureQuadratic', ...
                    'KernelFunction', 'rationalQuadratic' );
                
xRange = xMin:0.2:xMax;

[ predSmooth, predCI ] = predict( model, xRange' );
predSmooth = smoothdata( predSmooth, 'Gaussian', 20 );
predCI = smoothdata( predCI, 'Gaussian', 20 );

if showPoints
    xRangeFlip = [ xRange'; flipud( xRange' )];
    predCIFlip = [ (predSmooth+predCI); flipud(predSmooth-predCI) ];
    fill(   xRangeFlip, predCIFlip, colour, ...
            'FaceAlpha', 0.15, ...
            'LineStyle', 'none' );
else
    plot( xRange, predSmooth+predCI, 'k-', 'LineWidth', 1 );
    hold on;
    plot( xRange, predSmooth-predCI, 'k-', 'LineWidth', 1 );
end

hold on;

if showPoints
    % thin out points for clarity
    selection = randsample( length(y), fix(0.25*length(y)) );

    plot( obs(selection), y(selection), [colour 'o'], ...
                'LineWidth', 1, ...
                'MarkerSize', 3, ...
                'MarkerFace', colour );
end
            
plot( xRange, predSmooth, [colour '-'], 'LineWidth', 4 );


hold off;
xlabel('Peak Power (W\cdotkg^{-1})');
if usePercent
    ylabel('Validation Absolute Error (%)');
else
    ylabel('Validation Absolute Error (W\cdotkg^{-1})');
end
xlim([ xMin, xMax ]);
ylim( [ 0, yMax ] );

set( gca, 'FontName', opt.font );
set( gca, 'FontSize', opt.fontSize );
set( gca, 'LineWidth', opt.axisLineWidth);
set( gca, 'Box', opt.box );
set( gca, 'TickDir', opt.tickDirection );


end