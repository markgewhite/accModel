% ************************************************************************
% Function: augCaseRotation
% Purpose:  Augment a given case using random rotation
%
% Parameters:
%       x: 3-column array
%       opt: options for rotation
%
% Output:
%       xr: new rotated array
%
% ************************************************************************


function xr = augCaseRotation( x, opt )

if opt.doGlobal
    % find initial orientation, averaged over 10 points
    x0 = mean( x(1:10,:), 1 );
    
    % set desired vertical alignment
    v = [ -1 0 0 ];

    % rotate into vertical alignment
    R = vec2vecrotation( x0, v );
    x = (R*x')';
end

% generate random rotation angles about zero with specified SD
ang = normrnd( 0, opt.angSD )*pi/180;

xr = rotate( x, ang, opt.axisR );
if opt.doGlobal
    xr = (inv(R)*xr')';
end
    
end