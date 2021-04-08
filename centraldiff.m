% ************************************************************************
% Function: centraldiff
% Purpose:  Differentiate a dataset with central difference
%
% Parameter:
%   x: data in vector form
%
% ************************************************************************


function dx = centraldiff( x )

dx = zeros( size(x) );

for i = 2:size(x,1)-1
    dx(i,:) = x(i+1,:)-x(i-1,:);
end
dx = dx/2;

dx(1,:) = x(2,:)-x(1,:);
dx(end,:) = x(end,:)-x(end-1,:);

end