% ************************************************************************
% Function: plotSignalComponents
% Purpose:  Plot FPCs
%
% Parameters:
%       fpca: 1st PCA data structure
%
% Output:
%       Plots and text
%
% ************************************************************************

function plotSignalComponents( fpca  )

tTakeoff = 0;
tLanding = 486;
tProp = -305;

opt.plot.font = 'Times New Roman';
opt.plot.fontSize = 48;
opt.plot.xLabelRotation = 0;
opt.plot.lineWidth = 5;
opt.plot.dotLineWidth = 3;
opt.plot.axisLineWidth = 2.5;
opt.plot.box = false;
opt.plot.tickDirection = 'Out';

% peak power correlation sign for resultant acc.
%r = [ +1 +1 -1 +1 -1   -1 -1 -1 +1 +1   -1 +1 +1 +1 +1 ]';
% peak power correlation sign for resultant vel.
%r = [ +1 -1 +1 -1 -1   -1 +1 +1 -1 -1   -1 -1 +1 -1 -1 ]';
% peak power correlation sign for resultant pwr.
%r = [ +1 +1 -1 -1 -1   +1 -1 +1 -1 +1   -1 -1 +1 +1 -1 ]';
% peak power correlation sign for acc-x (no correction)
r(:,1) = [ -1 -1 +1 -1 +1   +1 +1 +1 -1 -1   -1 +1 +1 +1 -1 ];
% peak power correlation sign for acc-y (no correction)
r(:,2) = [ -1 +1 -1 -1 +1   -1 -1 +1 -1 -1   -1 -1 -1 -1 -1 ];
% peak power correlation sign for acc-z (no correction)
r(:,3) = [ -1 -1 -1 -1 -1   -1 -1 -1 +1 +1   -1 +1 -1 -1 +1 ];
% peak power correlation sign for acc-x (with correction)
%r(:,1) = [ +1 +1 -1 -1 -1   -1 +1 +1 -1 -1   +1 -1 -1 +1 +1 ];
% peak power correlation sign for acc-y (with correction)
%r(:,2) = [ +1 +1 -1 -1 +1   -1 -1 +1 +1 -1   +1 +1 +1 -1 +1 ];
% peak power correlation sign for acc-z (with correction)
%r(:,3) = [ +1 +1 +1 +1 -1   +1 +1 -1 -1 -1   -1 +1 +1 -1 -1 ];
% peak power correlation sign for resultant acc (varimax).
%r = [ +1 -1 -1 +1 -1   -1 -1 -1 +1 +1   -1 +1 +1 -1 -1 ]';
% peak power correlation sign for resultant vel (varimax).
%r = [ +1 -1 +1 +1 -1   +1 -1 +1 +1 -1   -1 +1 -1 -1 +1 ]';
% peak power correlation sign for resultant pwr (varimax).
%r = [ +1 +1 +1 -1 +1   +1 +1 -1 -1 -1   +1 -1 -1 -1 -1 ]';


pcaBasis = getbasis( fpca.meanfd );
tRange = getbasisrange( pcaBasis );
tSpan = getbasispar( pcaBasis );
t1 = tRange(1):0.1*(tSpan(2)-tSpan(1)):tRange(2);

nComp = length( fpca.varprop ); 
d = size( fpca.harmscr, 3 );

for i = 1:d

    for k = 1:nComp
        figure;
        hold on;
        
        % draw take-off line
        plot( [tTakeoff tTakeoff], [-4 4], 'k:', ...
                            'LineWidth', opt.plot.dotLineWidth );
        % draw landing line
        plot( [tLanding tLanding], [-4 4], 'k:', ...
                            'LineWidth', opt.plot.dotLineWidth );
        % draw propulsion phase
        plot( [tProp tProp], [-4 4], 'k:', ...
                            'LineWidth', opt.plot.dotLineWidth );     
        
        y0 = eval_fd( t1, fpca.meanfd );
        y0 = y0( :, 1, i );
        yd = sqrt( fpca.values(k) )*eval_fd( t1, fpca.harmfd(k) );
        yd = yd( :, 1, i );
        
        t2 = [ t1, fliplr(t1) ];
        yPlus = [ y0+r(k,i)*yd; fliplr(y0')' ];
        yMinus= [ y0-r(k,i)*yd; fliplr(y0')' ];
        
        % draw shaded regions for plus and minus
        plotRef(2) = fill( t2, yPlus, 'r', 'FaceAlpha', 0.25, ...
                        'DisplayName', '+' );
        plotRef(3) = fill( t2, yMinus, 'b', 'FaceAlpha', 0.25, ...
                        'DisplayName', '-' );
        % draw a border line
        plot( t1, y0+r(k,i)*yd, 'r', 'LineWidth', opt.plot.lineWidth);
        plot( t1, y0-r(k,i)*yd, 'b', 'LineWidth', opt.plot.lineWidth);
        % draw the mean line
        plotRef(1) = plot( t1, y0, 'k', ...
                        'LineWidth', opt.plot.lineWidth );  
                    
        hold off;
        
        xlim( [-1000, 1000] );
        ylim( [-2, 2] );
        
        title(['FPC' num2str(k)]);
        xlabel('Time (ms)');
        ylabel('Acceleration (g)');
        
        % set preferred properties
        ax = gca;
        ax.FontName = opt.plot.font;
        ax.FontSize = opt.plot.fontSize;
        ax.XTickLabelRotation = opt.plot.xLabelRotation;
        ax.LineWidth = opt.plot.axisLineWidth;
        ax.Box = opt.plot.box;
        ax.TickDir = opt.plot.tickDirection;
        ax.XTick = [-1000, 0, 1000];
        ax.YTick = [ 0, 1, 2, 3, 4 ];
        
        
    end              
    %pause;
        
end

end