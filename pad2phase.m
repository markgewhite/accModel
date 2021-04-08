% ************************************************************************
% Function: pad2phase
% Purpose:  Pad data to standard length about a dividing point
%
% Parameters:
%       x: time series
%       t0: time points either side of which are time windows
%       t1: first time window length
%       t2: second time window length
%       fixedSeparation: option whether to insert a fixed separation
%
% Output:
%       xn: standardised time series
%       tSpan: new time domain
%
% ************************************************************************


function xn = pad2phase( x, t0, t1, t2 )

n = size( x, 1 ); % number of time series

% divide the time series into two parts either side of t0
x1 = cell( n, 1 );
x2 = cell( n, 1 );
for i = 1:n
    x1{ i } = x{ i }( 1:t0(i), : );
    x2{ i } = flip( x{ i }( t0(i)+1:end, : ), 1 );
end

% standard length backwards from t0
xn1 = aligndata( x1, 'PadStart', 0, t1, 0, true );

% standard length forwards from t0
xn2 = aligndata( x2, 'PadStart', 0, t2-1, 0, true );

% put it together
xn = [ xn1; flip( xn2, 1 ) ];
% tSpan = [ -flip(tSpan1-1) tSpan2 ];

end