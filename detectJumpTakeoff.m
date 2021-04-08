% ************************************************************************
% Function: detectJumpTakeoff
% Purpose:  Detect the jump takeoff from the signal alone
%
% Parameters:
%       x: discrete series
%       opt: options
%
% Output:
%       tLanding: detected landing times
%
% ************************************************************************


function [ idxTakeoff, rmse, constraint ] = ...
                    detectJumpTakeoff( signal, idxCrit, idxLanding, opt )

if size( signal{1}, 2 )~=3
    error('Signal is not 3D.');
end

nCases = size( signal, 1 ); % number of time series
idxXMin = zeros( nCases, 1 );
idxXMax = zeros( nCases, 1 );
idxDXMax = zeros( nCases, 1 );
idxDZMax = zeros( nCases, 1 );
idxTakeoff = zeros( nCases, 1 ); % practical
angle = zeros( nCases, 1 );

for i = 1:nCases

    % re-orientate
    if opt.doReorientation
        [ sig, angle(i) ] = rotateVecInitial( signal{i}, opt.initOrientation, 10 );
    else
        sig = signal{i};
    end
        
    % work with the 'vertical' axis
    x = sig( 1:idxLanding(i), 1 );
    z = sig( 1:idxLanding(i), 3 );
    
    % smooth the signal using a moving average
    x = movmean( x, opt.nSmooth*2+1 );
    z = movmean( z, opt.nSmooth*2+1 );   
    
    % find the rate of change
    dx = centraldiff( x );
    dz = centraldiff( z );
    
    % find the X trough
    [ ~, idxXMin(i) ] = min( x );
    
    % now find the X max after this point
    [~, idxXMaxPt ] = max( x(idxXMin(i):end) );
    idxXMax(i) = idxXMaxPt+idxXMin(i)-1;
       
    % work backwards from XMax and find the peak in the derivative of X
    [ ~, idxDXMax(i) ] = max( dx(1:idxXMax(i)) );
    
    % work backwards from XMax and find the peak in the derivative of Z
    [ ~, idxDZMax(i) ] = max( dz(1:idxXMax(i)) );

    % determine which to use
    % first preference is idxDZMax, then idxDXMax and idxXZero
    if idxXMax(i) - idxDZMax(i) < opt.idxMaxDivergence
        idxTakeoff(i) = idxDZMax(i);
    else
        idxTakeoff(i) = idxDXMax(i);
    end
    
    % apply fixed bias offset
    idxTakeoff(i) = idxTakeoff(i) + opt.idxOffset;

    if false
       
        % convert indices to times
        tSpan = ((1:length(x)) - idxCrit(i))*4;
        tXMin = (idxXMin(i) - idxCrit(i))*4;
        tXMax = (idxXMax(i) - idxCrit(i))*4;
        tDXMax = (idxDXMax(i) - idxCrit(i))*4;
        tDZMax = (idxDZMax(i) - idxCrit(i))*4;
        tCrit = (idxCrit(i) - idxCrit(i))*4;
        tTakeoff = (idxTakeoff(i) - idxCrit(i))*4;
        
        figure(1);
        clf;
        yyaxis left;
        
        pRef(1) = plot( tSpan, x, 'r-', 'LineWidth', 2, ...
                            'DisplayName', '\it a_{x} \rm(LHS)' );
        hold on; 
        pRef(2) = plot( tSpan, z, 'b-', 'LineWidth', 2, ...
                             'DisplayName', '\it a_{z} \rm(LHS)' );
        plot( [tSpan(1),0], [0,0], 'k:', 'LineWidth', 1 );
        
        plot( tXMin, x(idxXMin(i)), 'ko', ...
                            'LineWidth', 1.5, 'MarkerSize', 10 );
        plot( tXMax, x(idxXMax(i)), 'ko', ...
                            'LineWidth', 1.5, 'MarkerSize', 10 );
        
        ylim( [-2.5,2.5] );
        ylabel( 'Acceleration (g)' );
        
        yyaxis right;
        
        pRef(3) = plot( tSpan, dx*250, 'r--', 'LineWidth', 1.0, ...
                        'DisplayName', '\it da_{x}/dt \rm(RHS)' ); 
        pRef(4) = plot( tSpan, dz*250, 'b--', 'LineWidth', 1.0, ...
                        'DisplayName', '\it da_{z}/dt \rm(RHS)' ); 

        plot( tDZMax, dz(idxDZMax(i))*250, 'ko', ...
                            'LineWidth', 2.5, 'MarkerSize', 10 );
        plot( tDXMax, dx(idxDXMax(i))*250, 'ko', ...
                            'LineWidth', 1.5, 'MarkerSize', 10 );

        ylabel( 'Differentiated Acceleration, \itda/dt \rm(g/s)' );
                        
        yyaxis left;        
        pRef(5) = plot( [tCrit, tCrit], [-5, 5], 'k-', ...
                        'LineWidth', 1.5, 'DisplayName', 'True Takeoff' );
        pRef(6) = plot( [tTakeoff, tTakeoff], [-5, 5], 'k--', ...
                        'LineWidth', 1, 'DisplayName', 'Est. Takeoff' );
        
        hold off
        xlim( [-500, 250] );
        xlabel( 'Time (ms)' );

        legend( pRef, 'Location', 'Best' );
        pause;
    end
    

end

rmse = sqrt( sum( (idxTakeoff-idxCrit).^2, 1 )/ nCases );
constraint = -1;

end


