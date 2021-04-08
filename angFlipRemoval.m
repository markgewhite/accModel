% ************************************************************************
% Function: angFlipRemoval
% Purpose:  Remove 2pi discontinuities in angle time series
%
% Parameters:
%       a: 1-dimensional angle series
%
% Output:
%       a: corrected angle series
%
% ************************************************************************


function a = angFlipRemoval( a )

threshold = 1.5*pi;

da = diff( a );
t = find( abs( da ) > threshold, 2 )+1;
while length(t) == 2
    a( t(1):t(2)-1 ) = a( t(1):t(2)-1 )-sign( da(t(1)-1) )*2*pi;
    da = diff( a );
    t = find( abs( da ) > threshold, 2 )+1;
end
    
end