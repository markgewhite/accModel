% ************************************************************************
% Function: sqdim
% Purpose:  Find the best square dimensions for given input
%           To be used for finding best dimensions of a subplot
%
% Parameter:
%   x: integer
%
% Outputs:
%   rows: best row dimension
%   cols: best col dimension
%
% ************************************************************************


function [ rows, cols ] = sqdim( x )

if x == 1
    cols = 1;
    rows = 1;
    return;
end

a = zeros( x-1, 1 );
b = zeros( x-1, 1 );
r = zeros( x-1, 1 );

for i = 1:x-1
    y = x+i-1;
    [a(i), b(i)] = twofactors(y);
    if a(i) < b(i)
        c = a(i);
        a(i) = b(i);
        b(i) = c;
    end
    r(i) = a(i)-b(i)+a(i)*b(i)-x;
end

best = find( r==min(r), 1 );
cols = a( best );
rows = b( best );

end

