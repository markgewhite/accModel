% ************************************************************************
% Function: signalFDA
% Purpose:  Convert the time series data into smooth functions
%
% Parameters:
%       x: discrete series
%       opt: options
%       doTruncation: whether to truncate at take-off
%
% Output:
%       xFd: smooth continuous functions
%       xFdParams: associated parameters
%       df: degrees of freedom
%       gcv: generalised cross validation measure
%
% ************************************************************************

function [ xFd, xFdPar, df, gcv ] = signalFDA( x, tSpan, opt )

basis = create_bspline_basis( [tSpan(1), tSpan(end)], opt.nBasis, opt.basisOrder );

xFdPar = fdPar( basis, opt.penaltyOrder, opt.lambda ); 

nSets = length( x );
xFd = cell( nSets, 1 );
df = zeros( nSets, 1 );
gcv = zeros( nSets, 1 );

for i = 1:nSets
    [ xFd{i}, df(i), gcvi ] = smooth_basis( tSpan, x{i}, xFdPar );
    gcv(i) = sum( gcvi, 'all' );
end

end


