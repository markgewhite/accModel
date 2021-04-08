% ************************************************************************
% Function: modelContourPlot
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


function stop = modelContourPlot( plotID, v, optima, slices, ...
                                    data, state, opt )

persistent modelOutputFigure

% constants
nMesh = 200;
cmap = colorcube(64);
cmap2 = colorcube(16);
lineMap = [ cmap2(13,:); cmap2(12,:); cmap2(6,:); ...
            cmap2(8,:); cmap2(3,:); cmap2(2,:)];

if ~isfield( opt, 'overlapFactor' )
    opt.overlapFactor = 0.75;
end
if ~isfield( opt, 'contourStep' )
    opt.contourStep = 0.2;
end
if ~isfield( opt, 'contourType' )
    opt.contourType = 'Lines';
end

stop = false;

switch state

    case 'initial'
        modelOutputFigure( plotID ) = figure();      
        
    case 'iteration'
             
        figure( modelOutputFigure(plotID) );
        
        % ----------------------------------------------------------------
        %  Prepare data
        % ----------------------------------------------------------------        

        if iscell( data )
            % set of results to be bagged
            % use first set to get data ranges, etc
            results = data{1};
            % collect all object models together
            nModels = length( data );
            objModel = cell( nModels, 1 );
            % objModel = [];
            for i = 1:length(data)
                objModel{i} = data{i}.objModel;
                % objModel = [ objModel data{i}.objModel ];  %#ok<AGROW>
            end
            clear data;
        
        else
            % single set of results - no bagging
            results = data;
            nModels = 1;
            objModel = results.objModel;
            clear results.objModel;
            clear data;
            
        end
                       
        % extract the valid points

        validPts = results.ObjectiveTrace ~= 0;       
        Xall = results.XTraceIndex( validPts, : );
        nVar = length( v );
        if nVar < 1 || nVar >3
            error('Incorrect number of variables for plotting');
        end

        % ----------------------------------------------------------------
        %  Create fine mesh
        % ----------------------------------------------------------------
                
        % create fine mesh for each variable 
        % for the original ranges
        % and for the index representation
        XFit = cell( nVar, 1 );
        XPlot = cell( nVar, 1 );
        isCategorical = false( nVar, 1 );
        isBoolean = false( nVar, 1 );
        nPts = zeros( nVar, 1 );
        for i = 1:nVar
            limFit(1) = round( results.lowerBounds(v(i)) );
            limFit(2) = round( results.upperBounds(v(i)) );
            
            isCategorical(i) = results.isCat( v(i) );
            isBoolean(i) = islogical( results.fcn{ v(i) } );

            if isCategorical(i) || isBoolean(i)

                limPlot = limFit;
                XFit{i} = twice( limFit(1):limFit(2), 0 )';
                XPlot{i} = twice( limFit(1):limFit(2), 0.5 )';
                
            else
            
                limPlot(1) = results.fcn{v(i)}( limFit(1) );
                limPlot(2) = results.fcn{v(i)}( limFit(2) );
                if results.isLog(v(i))
                    limPlot = log10( limPlot );
                end
                hFit = ( limFit(2)-limFit(1) )/nMesh;
                XFit{i} = (limFit(1):hFit:limFit(2))';
                hPlot = ( limPlot(2)-limPlot(1) )/nMesh;
                XPlot{i} = (limPlot(1):hPlot:limPlot(2))';
                
            end
            
            nPts(i) = length( XFit{i} );

        end
        
        % transform into mesh for contour plots
        switch nVar
            case 1
                XMeshFit = XFit{1};
                XMeshPlot = XPlot{1};
                
            case 2
                [ XMeshFit(:,:,1), XMeshFit(:,:,2) ] = ...
                                            meshgrid( XFit{1}, XFit{2} );
                [ XMeshPlot(:,:,1), XMeshPlot(:,:,2) ] = ...
                                            meshgrid( XPlot{1}, XPlot{2} );
            
            case 3
                [ XMeshFit(:,:,1), XMeshFit(:,:,2), XMeshFit(:,:,3) ] = ...
                                meshgrid( XFit{1}, XFit{2}, XFit{3} );
                [ XMeshPlot(:,:,1), XMeshPlot(:,:,2), XMeshPlot(:,:,3) ] = ...
                                meshgrid( XPlot{1}, XPlot{2}, XPlot{3} );
        end
        
        
        % ----------------------------------------------------------------
        %  Generate and plot each optimum
        % ----------------------------------------------------------------

        nOpt = size( optima, 1 );
        for j = 1:nOpt
            
            % set the optimum fit and plot parameters
            optimaFit = optima(j,:);
            optimaPlot = zeros( 1, nVar );
            for i = 1:nVar
                if isCategorical(i) || isBoolean(i)
                    optimaPlot(i) = optimaFit( v(i) );              
                else           
                    optimaPlot(i) = results.fcn{v(i)}( optima(j,v(i)) );
                    if results.isLog(v(i))
                        optimaPlot(i) = log10( optimaPlot(i) );
                    end
                end
            end

            % create the full predictor table (index representation)
            XLongFit = repmat( optima(j,:), prod(nPts), 1 );

            % turn them into a long array for predictions
            % and place them in the full predictor table
            for i=1:nVar
                XLongFit( :, v(i) ) = reshape( XMeshFit(:,:,i), prod(nPts), 1 );
            end

            % predict the losses from the model (which is based on indices)
            if nModels == 1
                % single calculation
                [ YLong, YCI ] = predict( objModel, XLongFit );
                [ YOpt, YOptCI ] = predict( objModel, optimaFit );
                noise = objModel.Sigma;
            else
                % bag predictions, confidence interval and noise
                YLongMdl = zeros( prod(nPts), nModels );
                YCIMdl = zeros( prod(nPts), nModels );
                YOptMdl = zeros( 1, nModels );
                YOptCIMdl = zeros( 1, nModels );
                noiseMdl = zeros( 1, nModels );
                for i = 1:nModels
                    [ YLongMdl(:,i), YCIMdl(:,i) ] = ...
                                        predict( objModel{i}, XLongFit );
                    [ YOptMdl(:,i), YOptCIMdl(:,i) ] = ...
                                        predict( objModel{i}, optimaFit );
                    noiseMdl(i) = objModel{i}.Sigma;
                end
                YLong = mean( YLongMdl, 2 );
                YCI = mean( YCIMdl, 2 );
                YOpt = mean( YOptMdl );
                YOptCI = mean( YOptCIMdl );
                noise = mean( noiseMdl );
                disp(['Bagged Noise = ' num2str(noise)]);
            end
            YOptMax = YOpt+opt.overlapFactor*YOptCI;
                
            ax = gca;
            pRef = [];
            switch nVar
                case 1
                    if nOpt == 1 
                        % only show optimum range, confidence interval
                        % and noise if there is only one plot
                        
                        % find the limits about the optimum
                        optIdx = YLong<=YOptMax;
                        ubIdx = 1;
                        while sum( optIdx(ubIdx:end) )>0 && ubIdx<length(optIdx)
                            % find lower bound
                            lbIdx = find( optIdx(ubIdx:end)==1, 1 )+ubIdx-1;
                            % find upper bound
                            ubIdx = find( optIdx(lbIdx:end)==0, 1 )+lbIdx-2;
                            if isempty( ubIdx )
                                ubIdx = length(optIdx);
                            end
                            % draw shaded area
                            XOptPlotRev = [ XMeshPlot(lbIdx:ubIdx); ...
                                        flipud(XMeshPlot(lbIdx:ubIdx)) ];
                            YOptPlotRev = [ YLong(lbIdx:ubIdx); ...
                                        zeros(ubIdx-lbIdx+1,1) ];                    
                            pRef(4) = fill( XOptPlotRev, ...
                                         YOptPlotRev, ...
                                         cmap(63,:), ...
                                         'LineWidth', opt.plot.lineWidth, ...
                                         'DisplayName', 'Optimum Range' );
                            hold on;
                            % output range
                            %lb = limPlot(1)+ ...
                            %        (lbIdx/nPts)*(limPlot(2)-limPlot(1));
                            %ub = limPlot(1)+ ...
                            %        (ubIdx/nPts)*(limPlot(2)-limPlot(1));
                            %disp(['CI = ' num2str(lb) ...
                            %                ' - ' num2str(ub) ]);
                            ubIdx = ubIdx+1;
                        end

                        % plot line graph showing confidence limits and noise
                        XMeshPlotRev = [ XMeshPlot; flipud(XMeshPlot) ];
                        YPlotCIRev = [ YLong-YCI; flipud(YLong+YCI) ];

                        pRef(2) = fill( XMeshPlotRev, ...
                                     YPlotCIRev, ...
                                     cmap(25,:), ...
                                     'LineWidth', opt.plot.lineWidth, ...
                                     'DisplayName', 'Confidence Limits' );

                        if ubIdx == 1
                            hold on; % for some reason no optimum range plotted
                        end

                        YPlotNoiseRev = [ YLong-noise; flipud(YLong+noise) ];
                        pRef(3) = fill( XMeshPlotRev, ...
                                     YPlotNoiseRev, ...
                                     cmap(30,:), ...
                                     'LineWidth', opt.plot.lineWidth, ...
                                     'DisplayName', 'Noise' );
                    
                        
                        % plot the bagged prediction
                        pRef(1) = plot( XMeshPlot, ...
                                     YLong, ...
                                     'Color', lineMap(j,:), ...
                                     'LineWidth', opt.plot.lineWidth, ...
                                     'DisplayName', 'Surrogate Prediction' );
	
                        
                        if false % nModels > 1
                            % plot individual model predictions
                            for i = 1:nModels
                                plot( XMeshPlot, ...
                                      YLongMdl(:,i), ...
                                      'Color', lineMap(j,:), ...
                                      'LineWidth', opt.plot.lineWidth );
                            end    
                        end
                                 
                        %pRef(4) = plot( optimaPlot(1), YOpt, '*', ...
                        %            'MarkerEdgeColor', cmap(31,:), ...
                        %            'MarkerSize', 20, ...
                        %            'LineWidth', opt.plot.lineWidth, ...
                        %            'DisplayName', 'Optimum' );
                        
                        if isCategorical(j) || isBoolean(j)
                            disp(['Predictions = ' num2str(YLong')]);
                        end

                    else
                        % plot simple curve as there will be multiple
                        pRef(j) = plot( XMeshPlot, ...
                                     YLong, ...
                                     'Color', lineMap(j,:), ...
                                     'LineWidth', 6, ...
                                     'DisplayName', ...
                                        ['Cluster ' num2str(j)] );
                        hold on;
	
                        plot( optimaPlot(1), YOpt, '*', ...
                                    'MarkerEdgeColor', lineMap(j,:), ...
                                    'MarkerSize', 25, ...
                                    'LineWidth', 3, ...
                                    'DisplayName', 'Optimum' );
                    end
                    

                case 2
                    % turn the predictions into a mesh for 2D contouring
                    YMesh = reshape( YLong, nPts(2), nPts(1) );

                    switch opt.contourType
                        case 'Lines'
                            cRange = opt.lossLim(1):opt.contourStep:opt.lossLim(2);
                            [ cMatrix, cObj ] = contour( ...
                                                 XMeshPlot(:,:,1), ...
                                                 XMeshPlot(:,:,2), ...
                                                 YMesh, ...
                                                 cRange, ...
                                                'LineWidth', 1.5, ...
                                                'ShowText', 'on', ...
                                                'LabelSpacing', 4*72 );
                            cObj.LevelList = round( cObj.LevelList, 2);
                            clabel( cMatrix, cObj, 'Color', 'k', 'FontSize', 10 );

                        case 'Solid'
                            cRange = opt.lossLim(1):opt.contourStep:opt.lossLim(2);
                            [ cMatrix, cObj ] = contourf( ...
                                                 XMeshPlot(:,:,1), ...
                                                 XMeshPlot(:,:,2), ...
                                                 YMesh, ...
                                                 cRange, ...
                                                'LineWidth', 0.5, ...
                                                'ShowText', 'off', ...
                                                'LabelSpacing', 4*72 );
                            cBar = colorbar;
                            cBar.Label.String = opt.objectiveDescr;
                            cBar.Limits = opt.lossLim;
                            cBar.TickDirection = 'out';
                            cBar.Ticks = opt.lossLim(1):opt.lossLim(2);

                        case 'Optimum'
                            cRange = opt.lossLim(1):opt.contourStep:opt.lossLim(2);
                            [ ~, cObjFull ] = contour( ...
                                                 XMeshPlot(:,:,1), ...
                                                 XMeshPlot(:,:,2), ...
                                                 YMesh, ...
                                                 cRange, ...
                                                'LineWidth', 1.5, ...
                                                'ShowText', 'on', ...
                                                'LabelSpacing', 4*72 );

                            hold on;
                            %YOptMin = round( YOptMin/opt.contourStep ) ...
                            %                *opt.contourStep;
                            YOptMax = round( YOptMax/opt.contourStep ) ...
                                            *opt.contourStep;           
                            optRange = [YOptMax YOptMax];
                            [ ~, cObjOPt ] = contour( ...
                                                 XMeshPlot(:,:,1), ...
                                                 XMeshPlot(:,:,2), ...
                                                 YMesh, ...
                                                 optRange, ...
                                                'LineWidth', 4, ...
                                                'ShowText', 'on', ...
                                                'LabelSpacing', 4*72 );
                            cmap = parula(32);
                            plot( optimaPlot(1), optimaPlot(2), '*', ...
                                    'MarkerEdgeColor', cmap(1,:), ...
                                    'MarkerSize', 20, ...
                                    'LineWidth', 2 );                                      

                    end
                    

                case 3
                    % turn the predictions into a mesh for 3D contouring
                    YMesh = reshape( YLong, nPts(1), nPts(2), nPts(3) );

                    [ cMatrix, cObj ] = contourslice( ...
                                                 XMeshPlot(:,:,1), ...
                                                 XMeshPlot(:,:,2), ...
                                                 XMeshPlot(:,:,3), ...
                                                 YMesh, ...
                                                 [], [], slices, ...
                                                 20, ...
                                                'LineWidth', 1.5, ...
                                                'ShowText', 'on', ...
                                                'LabelSpacing', 4*72 );
                    cObj.LevelList = round( cObj.LevelList, 2);
                    clabel( cMatrix, cObj);
                    

            end

        end

        
        % ----------------------------------------------------------------
        %  Configure the plot
        % ----------------------------------------------------------------

        hold off;
        if ~isempty(pRef)
            legend( pRef, 'Location', 'best' );
            legend( 'boxoff' );
        end
        
        % set the axes' limits and tick values
        xlim( results.lim{ v(1) } );
        xlabel( results.descr( v(1) ) );
        if nVar == 1
            ylim( opt.lossLim );
            yticks( opt.lossLim(1):opt.lossLim(2) );
            ylabel( opt.objectiveDescr );
        else
            ylim( results.lim{ v(2) } );
            ylabel( results.descr( v(2) ) );
        end
        
        if isCategorical(1) || isBoolean(1)
            xTickNum = unique( round(XPlot{1}) );
            xticks( xTickNum );
            if isBoolean(1)
                xticklabels( {'False', 'True'} );
                ax.XAxis.MinorTickValues = 2.5;
            else
                xticklabels( results.varDef{v(1)}.Range );
                ax.XAxis.MinorTickValues = xTickNum(1:end-1)+0.5;
            end
        end
        
        if nVar >= 2
            
            if isCategorical(2) || isBoolean(2)
                yTickNum = unique( round(XPlot{2}) );
                yticks( yTickNum );
                if isBoolean(2)
                    yticklabels( {'False', 'True'} );
                    ax.YAxis.MinorTickValues = 2.5;
                else
                    yticklabels( results.varDef{v(2)}.Range );
                    ax.YAxis.MinorTickValues = yTickNum(1:end-1)+0.5;
                end
            end
        
            if nVar == 3
                zlim( results.lim{ v(3) } );
                zlabel( results.descr( v(3) ) );
                if isCategorical(3) || isBoolean(3)
                    zTickNum = unique( round(XPlot{3}) );
                    zticks( zTickNum );
                    if isBoolean(3)
                        zticklabels( {'False', 'True'} );
                        ax.ZAxis.MinorTickValues = 2.5;
                    else
                        zticklabels( results.varDef{v(3)}.Range );
                        ax.ZAxis.MinorTickValues = zTickNum(1:end-1)+0.5;
                    end
                end
            end
            
        end
              
        % set preferred properties
        ax.FontName = opt.plot.font;
        set( gca, 'FontSize', opt.plot.fontSize );
        set( gca, 'XTickLabelRotation', opt.plot.xLabelRotation );
        set( gca, 'LineWidth', opt.plot.lineWidth );
        set( gca, 'Box', opt.plot.box );
        set( gca, 'TickDir', opt.plot.tickDirection );
        
        drawnow;
        
        
    case 'done'
        
    otherwise
        
end



end