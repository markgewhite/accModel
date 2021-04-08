% ************************************************************************
% Function: modelOutputPlot
% Purpose:  Plot the results from the model grid search/optimisation
%           as it progresses.
%
% Parameters:
%           
%
% Output:
%       stop: flag instructing routines whether to stop
%
% ************************************************************************


function stop = modelOutputPlot( results, state, opt, optPlot )

persistent modelOutputFigure

% constants
meshFactor = 100;
nPts = meshFactor+1;

if ~isfield( opt, 'doMultipleFigures' )
    opt.doMultipleFigures = false;
end

stop = false;

switch state

    case 'initial'
        if opt.doMultipleFigures
            nFig = length(opt.activeVar);
            modelOutputFigure = gobjects( nFig, 1 );
            for i = 1:nFig
                modelOutputFigure(i) = figure();
            end
        else
            modelOutputFigure = figure();
        end
        
        
    case 'iteration'
             
        % extract the valid points
        validPts = results.ObjectiveTrace ~= 0;       

        Xall = results.XTrace( validPts, : );
        Yall = results.ObjectiveTrace( validPts );
      
        if opt.doMultipleFigures
            v = optPlot.varID;
            figure( modelOutputFigure(v) );
            % select only the variable of interest
            % to fool the plotting function
            Xall = Xall( :, v );
            results.var = results.var( v );
            results.varDef = results.varDef( v );
            results.lim = results.lim( v );
            results.descr = results.descr( v );
            results.range = results.range( v );
            results.grp = results.grp( v );
            if v ~= 3 %strcmp( results.varDef{1}.Type, 'categorical' )
                opt.plotType = 'Box';
            else
                opt.plotType = 'Line';
            end
        else
            figure( modelOutputFigure );
        end
        
        nVar = size( Xall, 2 );
        
        % take logarithms if variable in wide scale
        for i = 1:nVar
            if results.isLog(i)
                Xall.(results.var(i)) = log10( Xall.(results.var(i)) );
            end
        end

        switch opt.plotType
            
            case 'Line'
                
                % prepare the set of points for predictions
                if strcmp( results.varDef{1}.Type, 'categorical' )
                    Xfit = table2array( Xall );
                else
                    if opt.doDiscretePoints
                        h = 1;
                    else
                        h = (results.lim{1}(2) - results.lim{1}(1)) ...
                                            /meshFactor;
                    end
                    Xfit = (results.lim{1}(1) : h : results.lim{1}(2))';
                    if opt.doDiscretePoints
                        Xplot = twice( Xfit, 0.5 );
                    else
                        Xplot = Xfit;
                    end
                end

                % determine how many levels to plot as separate lines
                if nVar == 2
                    if strcmp( results.varDef{2}.Type, 'categorical' )
                        levels = string( results.range{2} );
                        levelsDescr = levels;
                    else
                        levels = results.fcn{2}(results.range{2});
                        levelsDescr = string( levels );
                    end
                    if results.isLog(2)
                        levels = log10( levels );
                    end
                    nLines = sum( any( Xall.(results.var(2)) == levels ) );
                    % create the line descriptions for the legend
                    if isa( levels, 'double' )
                        levelsDescr = strings( length(levels), 1 );
                        for i = 1:length(levels)
                            levelsDescr(i) = [ char(results.descr(2)) ...
                                ' = ' num2str( levels(i) ) ];
                        end
                    end
                else
                    levels = '-';
                    levelsDescr = "";
                    nLines = 1;                   
                end
                
                plotRef = gobjects( nLines*(1+opt.doAddCI2Legend*2), 1 );
                p = 0;

                for i = 1:nLines

                    if nVar == 2
                        % which rows belong to this level?
                        linePts = Xall.(results.var(2)) == levels(i);
                    else
                        linePts = true( size( Xall, 1 ), 1 );
                    end

                    % use those subset points for this level
                    X = Xall( linePts, results.var(1) );
                    Y = Yall( linePts );

                    if opt.doGPfit
                        % fit a Gaussian process through the points
                        objModel = fitrgp( X, Y, ...
                                            'BasisFunction', 'Constant', ... 
                                            'KernelFunction', 'ARDMatern52' );

                        % use the model to get predicted points
                        [ Yfit, Yci ] = predict( objModel, Xfit );
                        Ynoise = objModel.Sigma;
                        Yci = Yci/1.96;
                    else
                        % fit a line based on mean values at each X
                        % find length of X before it repeats
                        Xtab = table2array(X);
                        nPts = find( Xtab==max(Xtab), 1 );
                        % reshape it into an array for averaging
                        Yarray = reshape( Y, nPts, length(Xtab)/nPts );
                        Yfit = median( Yarray, 2 );
                        if size( Yarray, 2) > 1
                            Yci = std( Yarray, 0, 2 );
                            Ynoise = Yci*1.96;
                        else
                            Yci = zeros( nPts, 1 );
                            Ynoise = zeros( nPts, 1 );
                        end
                    end
                    
                    % repeat each point twice for an integer plot
                    if opt.doDiscretePoints
                        Yplot = twice( Yfit );
                        Yciplot = twice( Yci );
                        Ynoiseplot = twice( Ynoise );
                    else
                        Yplot = Yfit;
                        Yciplot = Yci;
                        Ynoiseplot = Ynoise;
                    end
                    
                    % setup the colour scheme, one for each line
                    switch i
                        case 1
                            colour = colormap( winter(12) );
                        case 2
                            colour = colormap( autumn(12) );
                        case 3
                            colour = colormap( summer(12) );
                        case 4
                            colour = colormap( spring(12) );
                        case 5
                            colour = colormap( gray(12) );
                        otherwise
                            colour = colormap( colorcube );
                    end

                    if opt.doPlotPoints
                        % plot the individual points
                        plot( table2array(X), Y, 'o', ...
                                    'MarkerFaceColor', colour(2,:), ...
                                    'MarkerSize', 5 );
                        hold on;
                    end

                    % plot the model fit lines
                    p = p + 1;
                    plotRef(p) = plot( Xplot, Yplot, ...
                                        'Color', colour(4,:), ...
                                        'LineWidth', 1.5, ...
                                        'DisplayName', char(levelsDescr(i)) );
                    if ~opt.doPlotPoints
                        hold on;
                    end
                    
                    if opt.doPlotConfidence
                        % plot the model confidence interval
                        if opt.doAddCI2Legend
                            p = p + 1;
                            plotRef(p) = plot( Xplot, Yplot+Yciplot, '--', ...
                                        'Color', colour(6,:), 'LineWidth', 1, ...
                                        'DisplayName', '90% Confidence' );                            
                        else
                            plot( Xplot, Yplot+Yciplot, '--', ...
                                        'Color', colour(6,:), 'LineWidth', 1 );
                        end
                        plot( Xplot, Yplot-Yciplot, '--', ...
                                    'Color', colour(6,:), 'LineWidth', 1 );

                        % plot the model noise level
                        if opt.doAddCI2Legend
                             p = p + 1;
                             plotRef(p) = plot( Xplot, Yplot+Ynoiseplot, ':', ...
                                    'Color', colour(8,:), 'LineWidth', 1, ...
                                    'DisplayName', 'Model Noise' );                           
                        else
                            plot( Xplot, Yplot+Ynoiseplot, ':', ...
                                    'Color', colour(8,:), 'LineWidth', 1 );
                        end
                        plot( Xplot, Yplot-Ynoiseplot, ':', ...
                                    'Color', colour(8,:), 'LineWidth', 1 );
                    end

                end

                hold off;
                xlim( results.lim{1} );
                if ~isempty( opt.lossLim )
                    ylim( opt.lossLim );
                    ytickformat( opt.lossFormat );
                end
                xlabel( results.descr(1) );
                if opt.percentLoss
                    ylabel([opt.objectiveDescr ' (%)']);
                else
                    ylabel([opt.objectiveDescr ' (W\cdotkg^{-1})']);
                end
                legend( plotRef );
                
            
            case 'Contour'
                % draw a contour plot instead

                if strcmp( results.varDef{1}.Type, 'categorical' ) || ...
                    strcmp( results.varDef{2}.Type, 'categorical' )
                    error('At least one variable is categorical - unsuitable for contour');
                end
                
                Xall = table2array( Xall );
                                               
                if ~isfield( results, 'objModel' )
                    % create the model that fits the points
                    results.objModel = fitrgp( Xall, Yall, ...
                                    'BasisFunction', 'Constant', ... 
                                    'KernelFunction', 'ARDMatern52' );
                end
                              
                % create fine mesh for each variable
                if isfield( results, 'cutVar' )
                    xyVar = results.cutVar;
                else
                    xyVar = [1 2];
                end
                Xfit = zeros( nPts, 2 );
                for i = 1:2
                    h = ( results.lim{ xyVar(i) }(2) ...
                            - results.lim{ xyVar(i) }(1) )/meshFactor;
                    Xfit(:,i) = results.lim{ xyVar(i) }(1) ...
                                        : h : results.lim{ xyVar(i) }(2);
                end
                
                % transform into mesh for contour plots
                [ X1mesh, X2mesh ] = meshgrid( Xfit(:,1), Xfit(:,2) );
                                            
                % turn them into a long array for predictions
                X1long = reshape( X1mesh, nPts^2, 1 );
                X2long = reshape( X2mesh, nPts^2, 1 );
                if isfield( results, 'optValues' )
                    Xlong = repmat( results.optValues, nPts^2, 1 );
                    Xlong( :, xyVar(1) ) = array2table(X1long);
                    Xlong( :, xyVar(2) ) = array2table(X2long);
                else
                    Xlong = [ X1long X2long ];
                end
                
                % predict the losses from the model
                Ylong = predict( results.objModel, Xlong );
                
                % turn the predictions into a mesh for contouring
                Ymesh = reshape( Ylong, nPts, nPts );

                [ cMatrix, cObj ] = contour( X1mesh, X2mesh, Ymesh, 20, ...
                                        'LineWidth', 1.5, ...
                                        'ShowText', 'on', ...
                                        'LabelSpacing', 4*72 );
                cObj.LevelList = round( cObj.LevelList, 2);
                clabel( cMatrix, cObj);
  
                hold on;

                if opt.doPlotPoints
                    % plot the individual points
                    plot( Xall(:,xyVar(1)), Xall(:,xyVar(2)), ...
                        'o', 'MarkerFaceColor', 'b', 'MarkerSize', 5 );
                end

                hold off;
                xlim( results.lim{ xyVar(1) } );
                ylim( results.lim{ xyVar(2) } );
                xlabel( results.descr( xyVar(1) ) );
                ylabel( results.descr( xyVar(2) ) );
            
                
            case 'Surface'
                % draw a flat surface plot 

                if strcmp( results.varDef{1}.Type, 'categorical' ) || ...
                    strcmp( results.varDef{2}.Type, 'categorical' )
                    error('At least one variable is categorical - unsuitable for contour');
                end
                
                Xall = table2array( Xall );
                                               
                % fit a line based on mean values at each X
                % find length of X before it repeats
                nXPts = (find( Xall(:,1)==max(Xall(:,1)), 1 ));
                nYPts = (find( Xall(:,2)==max(Xall(:,2)), 1 )+nXPts-1)/nXPts;

                % transform into mesh for contour plots
                Xall(1:nXPts,1) = 1:nXPts; % HACK
                [ X1mesh, X2mesh ] = meshgrid( Xall(1:nXPts,1), ...
                                               Xall(1:nXPts:nXPts*nYPts,2) );
                                                           
                % find mean values at each point
                Yarray = reshape( Yall, nYPts, nXPts, ...
                                    length(Yall)/(nXPts*nYPts) );
                Ymesh = mean( Yarray, 3 )';

                clf;
                surface( X1mesh, X2mesh, Ymesh, ...
                            'FaceColor', 'None', ...
                            'Marker', 'o', 'EdgeColor', 'none', ...
                            'MarkerFaceColor', 'flat', ...
                            'MarkerSize', 20, 'MarkerEdge', 'k', ...
                            'LineWidth', 1 )
  
                xlim( results.lim{1} );
                ylim( results.lim{2} );
                xlabel( results.descr(1) );
                ylabel( results.descr(2) );
                
            case 'Box'
                
                if opt.varJoint && nVar == 2
                    Xall = table2array( Xall );
                    Xjoint = categorical( ...
                                strcat( Xall(:,2), {' + '}, Xall(:,1) ) );
                    descr = strcat( results.descr(2), {' + '}, ...
                                                results.descr(1) );
                    boxObj = boxplot( Yall, Xjoint, ...
                                            'PlotStyle', 'Compact', ...
                                            'Notch', 'on' );
                    xlabel( descr );
                    
                else
                    [ rows, cols ] = sqdim( nVar );
                    for i = 1:nVar

                        %subplot( rows, cols, i ); 
                        boxObj = boxplot( Yall, table2cell(Xall(:,i)), ...
                                                            'Notch', 'on' );
                        xlabel( results.descr(i) );

                    end
                end
                
                if ~isempty( opt.lossLim )
                    ylim( opt.lossLim );
                    ytickformat( opt.lossFormat );
                end
                
                if opt.percentLoss
                    ylabel([opt.objectiveDescr ' (%)']);
                else
                    ylabel([opt.objectiveDescr ' (W\cdotkg^{-1})']);
                end

        end
              
        % set preferred properties
        set( gca, 'FontName', optPlot.font );
        set( gca, 'FontSize', optPlot.fontSize );
        set( gca, 'XTickLabelRotation', optPlot.xLabelRotation );
        set( gca, 'LineWidth', optPlot.lineWidth );
        set( gca, 'Box', optPlot.box );
        set( gca, 'TickDir', optPlot.tickDirection );
        
        drawnow;
        
        
    case 'done'
        
    otherwise
        
end



end