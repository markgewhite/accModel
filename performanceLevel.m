% ************************************************************************
% Function: performanceLevel
% Purpose:  Determine performance level from ranking
%
% Parameters:
%       Y: performance
%       S: subject ID
%       N: number of levels
%
% Output:
%       L: performance level by case
%
% ************************************************************************

function L = performanceLevel( Y, S, N )

S = mod( S, 100 );
Sid = unique( S );
n = length( Sid );

Ymean = zeros( n, 1 );
for s = 1:n
    Ymean(s) = mean( Y( S==Sid(s) ) );
end

[ ~, Srank ] = sort( Ymean, 'ascend' );

Lsize = fix( n/N );
L = zeros( length(Y), 1 );
for s = 1:n
    L( S==Sid(Srank(s)) ) = fix((s-1)/Lsize)+1;
end

end
    

