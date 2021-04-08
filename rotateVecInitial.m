% ************************************************************************
% Function: rotateVecInitial
% Purpose:  Rotate 3D array to desired orientation
%           based on initial direction
%
% Parameters:
%       x: 3-column array
%       y: required initial orientation
%       n: number of rows to determine orientation
%
% Output:
%       xr: rotated 3-column array
%       a: angle of rotation in degrees
%
% ************************************************************************


function [ xr, a ] = rotateVecInitial( x, y, n )

if nargin < 2
    y = [ 0, 0, 1 ];
end

if nargin < 3
    n = 10;
end

x0 = mean( x(1:n,:), 1 );

a = atan2( norm( cross(x0,y) ), dot(x0,y) )*180/pi;

R = vec2vecrotation( x0, y ); % rotation matrix

xr = (R*x')'; % perform rotation

end