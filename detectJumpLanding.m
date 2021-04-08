% ************************************************************************
% Function: detectJumLanding
% Purpose:  Detect the jump landing from the signal alone
%
% Parameters:
%       x: discrete series
%       opt: options
%
% Output:
%       idxLanding: detected landing index
%       idxImpact: detect impact index
%       rmse: error with true landing index
%
% ************************************************************************


function [ idxLanding, idxImpact, rmse, constraint ] = ...
                    detectJumpLanding( signal, idxTakeoff, landing, opt )

nCases = size( signal, 1 ); % number of time series
idxLanding = zeros( nCases, 1 ); % practical
idxImpact = zeros( nCases, 1 ); % alternative
idxCrit = idxTakeoff+fix(0.25*landing)+1; % criterion

for i = 1:nCases

    % work with the resultant (shorthand)
    r = sqrt( sum( signal{i}.^2, 2) );
    
    % smooth the signal using a moving average
    r = movmean( r, opt.nSmooth*2+1 );
    
    % detect the peak landing impact
    [ pkSpike, idxSpike ] = findpeaks( r, ...
                                'MinPeakHeight', opt.freefallThreshold );
    % valid each candidates
    % before each there must be a verifiable period of freefall
    nCandidates = length( idxSpike );
    idxCandidate = zeros( nCandidates, 1 );
    rFreefall = zeros( nCandidates, 1 );
    for j = 1:nCandidates
        % find the first point when the r falls below a threshold
        % working backwards from the peak impact
        if any(r( max(idxSpike(j)-opt.maxSpikeWidth,1) : idxSpike(j) ) ...
                                    < opt.freefallThreshold)
            % accept the candidate
            idxCandidate(j) = find( ...
                    r( 1:idxSpike(j)) < opt.freefallThreshold, 1, 'last' );
            % find the mean prior to this point over a set period
            rFreefall(j) = mean( r( max(idxCandidate(j)-opt.freefallRange,1) ...
                                : idxCandidate(j) ) );
        end
    end
    % remove candidates that did not meet criteria
    retained = idxCandidate > 0;
    nCandidates = sum( retained );
    if nCandidates  == 0
        % none selected
        constraint = 1;
        rmse = 100;
        return;
    end
    idxCandidate = idxCandidate( retained );
    rFreefall = rFreefall( retained );
    pkSpike = pkSpike( retained );
    idxSpike = idxSpike( retained );
    
    % the best candidate is the one with the highest peak-to-lull ratio
    [ ~, best ] = max( pkSpike./rFreefall );
    
    % record the impact spike
    idxImpact(i) = idxSpike( best );
    
    % use the nearest apply fixed bias offset
    idxLanding(i) = idxCandidate( best ) + opt.idxOffset;

    if false
        % convert indices to times
        tSpan = ((1:length(r)) - idxTakeoff(i))*4;
        tSpike = (idxSpike - idxTakeoff(i))*4;
        tImpact = (idxImpact(i) - idxTakeoff(i))*4;
        tCandidate = (idxCandidate - idxTakeoff(i))*4;
        tFreefallRange = (idxCandidate - opt.freefallRange ...
                                                     - idxTakeoff(i))*4;
        tCrit = (idxCrit(i) - idxTakeoff(i))*4;
        tLanding = (idxLanding(i) - idxTakeoff(i))*4;
        
        figure(2);
        clf;
        
        pRef(1) = plot( tSpan, r, '-', 'LineWidth', 2, ...
                            'DisplayName', 'Resultant' );
        hold on; 
        plot( [tSpan(1), tSpan(end)], ...
                    [opt.freefallThreshold, opt.freefallThreshold], ...
                    'k:', 'LineWidth', 1 );
        
        plot( tSpike, r(idxSpike), 'ko', ...
                            'LineWidth', 1, 'MarkerSize', 10 );
        plot( tImpact, r(idxImpact(i)), 'ko', ...
                            'LineWidth', 2.5, 'MarkerSize', 12 );
        plot( tLanding, r(idxLanding(i)), 'ko', ...
                            'LineWidth', 2, 'MarkerSize', 12 );

        for j = 1:nCandidates
            pRef(2) = fill( [tFreefallRange(j), tFreefallRange(j), ...
                             tCandidate(j), tCandidate(j)], ...
                               [0, opt.freefallThreshold, ...
                                opt.freefallThreshold, 0], 'k', ...
                               'EdgeColor', [0.5 0.5 0.5], ...
                               'FaceAlpha', 0.05, ...
                               'DisplayName', 'Freefall Range');
        end
        
        pRef(3) = plot( [tCrit, tCrit], [0, 5], 'k-', ...
                        'LineWidth', 1.5, 'DisplayName', 'True Takeoff' );
        pRef(4) = plot( [tLanding, tLanding], [0, 5], 'k--', ...
                        'LineWidth', 1, 'DisplayName', 'Est. Takeoff' );
        
        hold off;
        ylim( [0,5] );
        ylabel( 'Acceleration (g)' );
        xlim( [0, 1000] );
        xlabel( 'Time (ms)' );

        legend( pRef, 'Location', 'Best' );
        pause;
    end
    

end

rmse = sqrt( sum( (idxLanding-idxCrit).^2, 1 )/ nCases );
constraint = -1;

end


