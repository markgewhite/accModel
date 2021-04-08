% ************************************************************************
% Function: vec2vecrotation
% Purpose:  Calculate the rotation matrix in 3D that would rotate the
%           the first vector into the second.
%           Based on Kuba Ober's derivation and code
%           https://math.stackexchange.com/a/897677
%
% Parameters:
%   v1: first vector
%   v2: second vector
%
% Output:
%   R: rotation matrix
%
% ************************************************************************


function R = vec2vecrotation( v1, v2 )

% transpose the vectors for the following calculations
a = v1';
b = v2';

% 2D rotation matrix in the plane formed by a and b
G = [ dot(a,b)          -norm(cross(a,b))   0; ...
      norm(cross(a,b))  dot(a,b)            0; ...
      0                 0                   1];

% basis change matrix
F = [ a ... 
      (b-dot(a,b)*a)/norm(b-dot(a,b)*a) ...
      cross(b,a) ];

% rotation matrix
R = F*G/F; % previously F*G*inv(F)

end

