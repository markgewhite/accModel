% ************************************************************************
% Function: reconstructPredictors
% Purpose:  Re-run FPCA with reconstructed curves based on a 
%           selected components
%
% Parameters:

%
% Output:
%       pSelect: logical array of selected predictors
%
% ************************************************************************

function [ trnX2, valX2 ] = reconstructPredictors( ...
                                trnX, valX, ...
                                fpca, paramsFd, pSelect, opt )

fBasis = getbasis( fpca.meanfd );
tSpan = getbasispar( fBasis );
tSpan = tSpan(1):0.5*(tSpan(end)-tSpan(1))/length(tSpan):tSpan(end);

trnFd = filterFd( table2array(trnX), pSelect, tSpan, paramsFd, fpca );
valFd = filterFd( table2array(valX), pSelect, tSpan, paramsFd, fpca );

fpca2 = pca_fd( trnFd, sum(pSelect), paramsFd, opt.doCentreFunctions );

trnX2 = fpca2.harmscr;
valX2 = pca_fd_score( valFd, fpca2.meanfd, fpca2.harmfd, ...
                        sum(pSelect), opt.doCentreFunctions );


end


function xFd = filterFd( X, pSelect, t, paramsFd, fpca )

[ n, p ] = size( X );

z = zeros( length(t), n );
for i = 1:n
    z( :, i ) = eval_fd( t, fpca.meanfd );
end

for j = 1:p
    if pSelect(j)
        for i = 1:n
            z( :, i ) = z( :, i ) + ...
                        X(i,j)*eval_fd( t, fpca.harmfd(j) );
        end
    end
end

xFd = smooth_basis( t, z, paramsFd );

end
