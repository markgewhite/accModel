% ************************************************************************
% Function: findACClandmarks
% Purpose:  Locate landmarks for a ACC set of curves
% 
%
% Parameters:
%       tSpan: timespan for the GRF series
%       accRaw: raw acceleration data points
%       opt: options structure including:
%           doCurvePlots: flag whether to plot registration curves
%       opt.set: landmarks structure including:
%           .start: jump initiation
%           .min: VGRF minima
%           .cross: Net VGRF crossing point
%           .max: first VGRF maxima before take-off
%
% Output:
%       landmarks: where the landmarks are located in time (means & cases)
%
% ************************************************************************


function landmarks = findACClandmarks( accRaw, tSpan, tTakeoff, tLanding, opt )

% setup the fine mesh time span
densityFactor = 4;
tSpanFine = tSpan(1) : (tSpan(2)-tSpan(1))/densityFactor : tSpan(end);

% convert the landing times into indices
idx0 = tLanding-tSpan(1);

if size( accRaw, 3) ~= 1
    % convert to resultant if 3D
    accRaw = sqrt( sum( accRaw.^2, 3 ) );
end

% convert time series data into smooth functions
basis = create_bspline_basis(   [tSpan(1), tSpan(end)], ...
                                opt.nBasis, ...
                                opt.basisOrder );
accFdPar = fdPar( basis, opt.penaltyOrder, opt.lambda );
accFd = smooth_basis( tSpan, accRaw, accFdPar );

% re-evaluate the points using the smooth function
% take off so the crossing point really is zero
acc = eval_fd( tSpanFine, accFd ) - 1;

% calculate the derivatives using differential operators
accD1Fd = deriv( accFd, 1 );
accD2Fd = deriv( accFd, 2 );
accD1 = eval_fd( tSpanFine, accD1Fd );
accD2 = eval_fd( tSpanFine, accD2Fd );


% calculate the power curves (add back 1)
vel = cumtrapz( acc );
pwr = (acc+1).*vel;
    
n = size( acc, 2 ); % number of jumps

% initialise
tPwrMax1 = zeros( n, 1 );
tPwrMax2 = zeros( n, 1 );
tAccD1Max = zeros( n, 1 );

for i = 1:n
     
    % find the power maxima after the landing estimate
    % returning their index positions and prominences
    [ ~, idxPwr ] = findpeaks( pwr( idx0(i):end, i ), ...
                                            'MinPeakProminence', 100 );
    if isempty( idxPwr )
        % compromise and remove the minimum prominence requirement
        [ ~, idxPwr ] = findpeaks( pwr( idx0(i):end, i ) );
    end
    % select the first peak regardless
    idx2 = idxPwr(1) + idx0(i) - 1;
    tPwrMax2( i ) = tSpanFine( idx2 );
    
    % find the first power maxima before the landing estimate
    [ ~, idxPwr, ~, promPwr ] = findpeaks( fliplr(pwr( 1:idx0(i), i )'), ...
                                            'MinPeakProminence', 100 );
    if isempty( idxPwr )
        [ ~, idxPwr, ~, promPwr ] = ...
                                findpeaks( fliplr(pwr( 1:idx0(i), i )') );
    end
    % sort based on a combined measure of prominence and proximity
    [ ~, orderID ] = sort( promPwr./idxPwr, 'Descend' );
    % use the one at the top of the list
    idx1 = idx0(i) - idxPwr(orderID(1)) + 1;
    tPwrMax1( i ) = tSpanFine( idx1 );
   
    % find ACCD1 maximum between these maxima (tPwrMax1 & tPwrMax2)
    [ ~, idx3 ] = max(accD1( idx1:idx2, i ));
    tAccD1Max( i ) = tSpanFine( idx3+idx1-1 );

end
   
% take means
tPwrMax1Mean = mean( tPwrMax1 );
tAccD1MaxMean = mean( tAccD1Max );
tPwrMax2Mean = mean( tPwrMax2 );
tTakeoffMean = mean( tTakeoff );
tLandingMean = mean( tLanding );

% assemble return array structure
landmarks.mean = 0;
landmarks.case = zeros( n, 1 );

if opt.(opt.setApplied).pwrMax1
    landmarks.mean = [ landmarks.mean, tPwrMax1Mean ];
    landmarks.case = [ landmarks.case, tPwrMax1 ];
end
if opt.(opt.setApplied).takeoff
    landmarks.mean = [ landmarks.mean, tTakeoffMean ];
    landmarks.case = [ landmarks.case, tTakeoff ];
end
if opt.(opt.setApplied).landing
    landmarks.mean = [ landmarks.mean, tLandingMean ];
    landmarks.case = [ landmarks.case, tLanding ];
end
if opt.(opt.setApplied).accd1Max
    landmarks.mean = [ landmarks.mean, tAccD1MaxMean ];
    landmarks.case = [ landmarks.case, tAccD1Max ];
end
if opt.(opt.setApplied).pwrMax2
    landmarks.mean = [ landmarks.mean, tPwrMax2Mean ];
    landmarks.case = [ landmarks.case, tPwrMax2 ];
end

landmarks.mean(1) = [];
landmarks.case(:,1) = [];


% display registration points
if opt.doCurvePlots
    jumps = randperm( n, 30 );
    for i = jumps
        subplot(5,1,1);
        plot( tSpanFine, acc(:,i), [tSpanFine(1),tSpanFine(end)], [0,0], 'b--' );
        hold on;
        
        plot( [tPwrMax1(i), tPwrMax1(i)], [-2,10], 'k-');
        plot( [tPwrMax2(i), tPwrMax2(i)], [-2,10], 'k-');

        hold off;
        title(['Jump ',num2str(i)]);
        
        subplot(5,1,2);
        plot( tSpanFine, accD1(:,i), [tSpanFine(1),tSpanFine(end)], [0,0], 'b--');
        grid on;
        subplot(5,1,3);
        plot( tSpanFine, accD2(:,i), [tSpanFine(1),tSpanFine(end)], [0,0], 'b--');
        grid on;
        subplot(5,1,4);
        plot( tSpanFine, vel(:,i), [tSpanFine(1),tSpanFine(end)], [0,0], 'b--');
        grid on;
        subplot(5,1,5);
        plot( tSpanFine, pwr(:,i), [tSpanFine(1),tSpanFine(end)], [0,0], 'b--');
        grid on;
        pause;
    end
end

end


