% ************************************************************************
% Function: modelSelectionPlot
% Purpose:  Plot the results from the model selection as it progresses
%
% Parameters:
%           
%
% Output:
%       stop: flag instructing routines whether to stop
%
% ************************************************************************


function stop = modelSelectionPlot( results, state, opt, optPlot )

persistent modelOutputFigure count

stop = false;

switch state

    case 'initial'
        modelOutputFigure = figure();
        count = 0;
        
    case 'iteration'
      
        figure( modelOutputFigure );
        count = count + 1;
        nVar = size( results.bestHP, 2 );
        
        if opt.varJoint
            bestHP = table2array( results.bestHP );
            bestJoint = strcat( bestHP(1:count,2), {' + '}, bestHP(1:count,1) );
            bestHPcat = categorical( bestJoint );           
            descr = strcat( results.descr(2), {' + '}, ...
                                        results.descr(1) );
            plotObj = histogram( bestHPcat );
            set( plotObj, 'LineWidth', 1.5 );
            xlabel( descr );
            ylabel('Selection Frequency');

        else
            [ rows, cols ] = sqdim( nVar );
            for i = 1:nVar
                subplotObj = subplot( rows, cols, i );
                if strcmp( results.varDef{i}.Type, 'real' )
                    
                    bestHP = results.bestHP.(results.var(i))(1:count);
                    if results.isLog(i)
                        bestHP = log10( bestHP );
                        interval = ( log10(results.lim{i}(2)) ...
                                    - log10(results.lim{i}(1)) )/100;
                        x = log10(results.lim{i}(1)):interval: ...
                                    log10(results.lim{i}(2));
                        pdca = fitdist( bestHP , 'Kernel', 'Kernel', 'Normal' );
                        y = pdf( pdca, x );
                        y = y./sum(y);
                        x = 10.^x; % reverse transform
                        plotObj = semilogx( x, y ); % but plot with transform

                    else
                        interval = ( results.lim{i}(2) ...
                                    - results.lim{i}(1) )/100;
                        x = results.lim{i}(1):interval: ...
                                    results.lim{i}(2);
                        pdca = fitdist( bestHP , 'Kernel', 'Kernel', 'Normal' );
                        y = pdf( pdca, x );
                        y = y./sum(y);
                        plotObj = plot( x, y );
                        
                    end
                    xlim( results.lim{i} );
                    ylabel('Selection Probability');
                    ytickformat( '%.3f' );
                    
                else
                    
                    bestHP = results.bestHP.(results.var(i))(1:count);
                    if strcmp( results.var(i), 'standardize' )
                        temp = strings( length(bestHP), 1 );
                        temp( bestHP==1 ) = 'No';
                        temp( bestHP==2 ) = 'Yes';
                        bestHP = temp;
                    end
                    bestHP = categorical( bestHP );
                    plotObj = histogram( bestHP );
                    ylabel('Selection Frequency');
                
                end

                xlabel( results.descr(i) );
                               
                % set preferred properties
                set( subplotObj, 'FontName', optPlot.font );
                set( subplotObj, 'FontSize', optPlot.fontSize );
                set( subplotObj, 'LineWidth', optPlot.axisLineWidth );
                set( subplotObj, 'Box', optPlot.box );
                set( subplotObj, 'TickDir', optPlot.tickDirection );
                set( subplotObj, 'TickLength', optPlot.tickLength );
                set( plotObj, 'LineWidth', optPlot.lineWidth );
                
            end
        end
        
        drawnow;
        
        
    case 'done'
        
        fig = figure( modelOutputFigure );
        
        nVar = size( results.bestHP, 2 );
        for i = 1:nVar
            subplotObj = fig.Children(nVar-i+1);
            pos = subplotObj.Position(1:2) + [-0.1 0.14];
            dim = [ pos 0.1 0.1 ];
            annotation( 'textbox', dim, ...
                'String', ['(' char(64+i) ')'], ...
                'LineStyle', 'none', ...
                'FontName', optPlot.font, ...
                'FontSize', optPlot.fontSize+4 );
        end
        
        
    otherwise
        
end

end