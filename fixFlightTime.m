% ************************************************************************
% Function: fixFlightTime
% Purpose:  Standardise the flight time of accelerometer signal
%
% Parameters:
%       x: time series
%       tLand: landing time from VGRF in milliseconds
%       tFlight: fixed separation time length
%
% Output:
%       xn: standardised time series
%       tSpan: new time domain
%
% ************************************************************************


function [ xn, tSpan ] = fixFlightTime( x, tLand, tFlight )

dxSmoothWindow = 11; % window for smoothing average (-15,+15)
tLand = fix(tLand/4); % adjust time in ms to indices

tEnd = size( x, 1 ); % length of time series
n = size( x, 2 ); % number of time series
d = size( x, 3 ); % time series dimension (assuming all the same)

% add extra space in readiness using end average
xPad = mean( x( end-9:end, :, : ) );
xn = [ x; xPad.*ones( tFlight, n, d ) ];

% smooth it with a running average
xs = movmean( abs(x), dxSmoothWindow );

% determine how many extra time points to insert
tExtra = tFlight-tLand;
% demarcate the search range
tSearch = min(tLand - 25, tEnd);
for i = 1:n
    % look for where the series falls to a minimum
    [ ~, tStart ] = min( xs( 1:tSearch(i), i) );

    % pad out the end with final average
    xn( :, i, d ) = [ xn( 1:tStart, i, : ); ...
            ones( tExtra(i), 1, d )*xs(tStart,i); ...
            xn( tStart+1:end-tExtra(i), i, : ) ];
end

% trim back the time series up to nearest 10
tSpan = 1:tEnd;
tAdjust = round( max(tSpan) + tFlight - min(tExtra), -1 );
xn = xn( 1:tAdjust, :, : );
tSpan = [ tSpan tSpan(end)+1:tAdjust ];
                            

end
