% ************************************************************************
% Function: deriveAccCurves
% Purpose:  Derive multiple curves from the acceleration curves 
%
% Parameters:
%       accFd: smooth continuous functions
%       opt: options
%
% Output:
%
%
% ************************************************************************

function allFd = deriveAccCurves( accFd, wFd, curves, opt )

% constants
tNorm = 250; % time intervals per second

if isa_basis( accFd )
    accFd{1} = accFd;
    nSets = 1;
else
    nSets = length( accFd );
end
nCurves = (length( curves )+1)/4;

% set a fine mesh timespan
tSpanFine = getTimeSpanFd( accFd{1}, 0.1 );

% -------------------------------------------------
%  Derive all curves
% -------------------------------------------------
allFd = cell( nSets*nCurves, 1 );

c = 0;
for s = 1:nSets

    % start with the acceleration (it may need to be removed later)
    if contains( curves, 'ACC' )
        c = c + 1;
        allFd{c} = accFd{s};
    end 

    % get the first and second derivatives
    if contains( curves, 'AD1' )
        c = c + 1;
        allFd{c} = deriv( accFd{s}, 1 );
    end

    if contains( curves, 'AD2' )
        c = c + 1;
        allFd{c} = deriv( accFd{s}, 2 );
    end

    % discretise the acceleration
    if contains( curves, {'VEL', 'DIS', 'PWR'} )

        accPts = eval_fd( accFd{s}, tSpanFine ) - 1;  

        % integrate acceleration to find velocity
        velPts = cumtrapz( accPts ) / tNorm;
        velFd = smoothDataFast( velPts, tSpanFine, opt );
        if contains( curves, 'VEL' )
            c = c + 1;
            allFd{c} = velFd;
        end

        if contains( curves, 'DIS' )
            % calculate the displacement
            disPts = cumtrapz( velPts ) / tNorm;
            disFd = smoothDataFast( disPts, tSpanFine, opt );
            c = c + 1;
            allFd{c} = disFd;
        end

        if contains( curves, 'PWR' )
            % calculate the power
            pwrPts = accPts.*velPts;
            pwrFd = smoothDataFast( pwrPts, tSpanFine, opt );
            c = c + 1;
            allFd{c} = pwrFd;
        end

    end
    
    
end

% -------------------------------------------------
%  Assemble the full array of Fd objects
% -------------------------------------------------
%  Apply warping function, if required

if ~isempty( wFd )
    tSpanWarp = eval_fd( wFd, tSpanFine );
    nCases = size( getcoef(wFd), 2 );
    for i = 2:c
        for j = 1:nCases
            pts = eval_fd( allFd{i}(j), tSpanWarp );
            allFd{c}(j) = smoothDataFast( pts, tSpanFine, opt );
        end
    end
end
    

end
