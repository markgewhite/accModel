% ************************************************************************
% Function: outputDistributions
% Purpose:  Generate distributions of 
%           outcome, FPC scores and squared errors
%
%
% Parameters:
%       results: combined outer fold data structure
%
% Output:
%       distributions
%
% ************************************************************************

function [ Xp, Yp, Ep ] = outputDistributions( results )

% peak power
Y = 0:0.2:80;
yPDF = fitdist( results.trnY, 'Kernel', 'Kernel', 'Normal' );
Yp = pdf( yPDF, Y );
Yp = Yp./sum(Yp);

% FPCs
X = -20:0.1:20;
nFPC = size( results.trnX, 2 );
Xp = zeros( length(X), nFPC );
for i = 1:nFPC
    xPDF = fitdist( results.trnX(:,i), 'Kernel', 'Kernel', 'Normal' );
    Xp(:,i) = pdf( xPDF, X );
    Xp(:,i) = Xp(:,i)./sum(Xp(:,i));
end

% errors
rmse = sqrt( results.sqerr );
E = 0:0.02:8;
ePDF = fitdist( rmse, 'Kernel', 'Kernel', 'Normal' );
Ep = pdf( ePDF, E );
Ep = Ep./sum(Ep);

% re-scale
Yp = Yp'*100;
Xp = Xp*100;
Ep = Ep'*100;                  

end
