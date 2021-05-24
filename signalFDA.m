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

basisOrder = str2double( opt.basisOrderAndPenalty(1) );
penaltyOrder = str2double( opt.basisOrderAndPenalty(3) );

basis = create_bspline_basis( [tSpan(1), tSpan(end)], ...
                                opt.nBasis, basisOrder );

xFdPar = fdPar( basis, penaltyOrder, opt.lambda ); 

nSets = length( x );
xFd = cell( nSets, 1 );
df = zeros( nSets, 1 );
gcv = zeros( nSets, 1 );

for i = 1:nSets
    [ xFd{i}, df(i), gcvi ] = smooth_basis( tSpan, x{i}, xFdPar );
    gcv(i) = sum( gcvi, 'all' );
end

end


