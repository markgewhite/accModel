% ************************************************************************
% Function: getTimeSpanFd
% Purpose:  Get the FD object's time span
%
% Parameters:
%       fd: smooth continuous function
%       tFactor: factor changing the time interval
%
% Output:
%       t: timespan
%
% ************************************************************************

function tSpan = getTimeSpanFd( fd, tFactor )

if nargin == 1
    tFactor = 1;
end

basis = getbasis( fd );
tSpan = getbasispar( basis );
tRange = getbasisrange( basis );
tInterval = (tRange(2)-tRange(1))/length(tSpan)*tFactor;

tSpan = tRange(1):tInterval:tRange(2);

end