% ************************************************************************
% Function: rotate
% Purpose:  Perform a 3D rotation about a specified axis over a 
%           series of points
%
% Parameters:
%   p: 3D points in a series
%   a: angle in radians
%   d: dimension for rotation
%
% Output:
%   rp: rotated 3D series
%
% ************************************************************************


function rp = rotate( p, a, d )

n = size(p,1);

% define the rotation matrix
switch d
    case 1 % x axis rotation
        R = [   1,          0,          0; ...
                0,          cos(a),     -sin(a); ...
                0,          sin(a),     cos(a) ];       
    case 2 % y axis rotation
        R = [   cos(a),     0,          sin(a); ...
                0,          1,          0; ...
               -sin(a),     0,          cos(a) ];
    case 3 % z axis rotation
        R = [   cos(a),     -sin(a),    0; ...
                sin(a),     cos(a),     0; ...
                0,          0,          1 ];
    otherwise
        error(message('Invalid dimension index'))
end

% perform the rotation across the points
rp = zeros(n,3);
for i = 1:n
    rp(i,:) = R*p(i,:)';
end

end
