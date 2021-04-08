% ************************************************************************
% Function: twice
% Purpose:  Repeat each point twice in a vector
%
% Parameters:
%       x 
%
% Output:
%       x2
%
% ************************************************************************

function xdbl = twice( x, offset )

if nargin == 1
    offset = 0;
end

x1 = zeros( 1, 2*numel(x) );
x2 = zeros( 1, 2*numel(x) );
x1( 1:2:end-1 ) = x - offset;                
x2( 2:2:end ) = x + offset;
xdbl = x1+x2;
        
end