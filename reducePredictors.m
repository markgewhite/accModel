% ************************************************************************
% Function: reducePredictors
% Purpose:  Use a data reduction technique to reduce the number
%           of predictors which is setup on the training data
%           and then applied to the validation data
%
% Parameters:
%       xTrain: training predictors
%       xValid: validation predictors
%
% Output:
%       zTrn: reduced training predictors
%       zVal: reduced validation predictors
%
% ************************************************************************

function [ zTrn, zVal ] = reducePredictors( xTrn, xVal, opt )

p = opt.nRetainedCompPCA;
xTrn = table2array( xTrn );
xVal = table2array( xVal );

switch opt.method
    
    case 'PCA'
        [ coeffTrn, zTrn ] = pca( xTrn, 'NumComponents', p );
        if size( zTrn, 2 ) < p
            zTrn = [ zTrn zeros( size(zTrn,1), zTrn-size(zTrn,2) ) ];
        end
        
        zVal = xVal*coeffTrn;
        
    case 'SPCA'
        
        xTrn = xTrn';
        xTrnMean = mean( xTrn, 2 );
        xTrnRecentred = xTrn-xTrnMean;
        [U, S, V] = svd( xTrnRecentred );
        d = diag( S );
        U = U( :, 1:p );
        d = d( 1:p );
        scaling = sum( abs(U)./d' );
        zTrn = xTrnRecentred'*U./(scaling'.*d)';
        
        xVal = xVal';
        xValMean = mean( xVal, 2 );
        xValRecentred = xVal-xValMean;
        zVal = xValRecentred'*U./(scaling'.*d)';
       
end

% convert back to tables
zTrn = array2table( zTrn );
zVal = array2table( zVal );

zNames =  tblFieldNames( p, {'PCA'} );
zTrn.Properties.VariableNames = zNames;
zVal.Properties.VariableNames = zNames;

end

