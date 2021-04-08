% ************************************************************************
% Function: index2logical
% Purpose:  Convert an array of indices to an array of logicals
%
% Parameters:
%       i: index array
%       n: required length of array
%
% Output:
%       b: boolean logical array
%
% ************************************************************************


function b = index2logical( i, n )

template = false( n, 1 );

b = template;
b( i ) = true;

end