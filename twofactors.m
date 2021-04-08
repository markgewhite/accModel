% ************************************************************************
% Function: twofactors
% Purpose:  Finds the two factors that are closest  
%
% Parameter:
%   x: integer to factor
%
% Outputs:
%   a: lower factor
%   b: higher factor
%
% ************************************************************************


function [a,b] = twofactors(x)

f = factor(x);
n = length(f);
mid = ceil(n/2);
p = perms(f);

set1 = prod(p(:,1:mid),2);
set2 = x./set1;
valid = set2>=set1;
if any(valid)
    a = max(set1(valid));
    b = min(set2(valid));
else
    a = max(set2(~valid));
    b = min(set1(~valid));
end

end

