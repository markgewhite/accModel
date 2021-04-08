% ************************************************************************
% Function: FPCAfeatures
% Purpose:  Extract FPCA features from discrete data set
%           This is a streamlined version with no checks
%           It assumes a unit size time step
%
% Parameters:
%       x: discrete series
%       t0: time points either side of which are time windows
%       opt: options
%
% Output:
%       features: functional component scores 
%
% ************************************************************************


function [ features, totvar, df, gcv ] = FPCAfeatures( x, t0, opt )

n = size( x, 1 ); % number of time series

% divide the time series into two parts either side of t0
x1 = cell( n, 1 );
x2 = cell( n, 1 );
for i = 1:n
    x1{ i } = x{ i }( 1:t0(i), : );
    x2{ i } = flip( x{ i }( t0(i)+1:end, : ), 1 );
end

if opt.doFixedLength
    % standard lengths
    [ xn, tSpan ] = aligndata( x1, 'PadStart',  ...
                                opt.tNorm, opt.tLength1, 0, true );
    nb = opt.nBasis;
else
    % pad series about the take-off point
    [ xn, tSpan ] = pad2phase( x, t0, opt.tLength1, opt.tLength2 ); 
    
    if opt.doFixedSeparation
        [ xn2, tSpan2 ] = fixFlightTime( xn( opt.tLength1+1:end, : ), ...
                                        opt.fixedSeparation );
        xn = [ xn(1:opt.tLength1,:); xn2 ];
        tSpan = [ tSpan(1:opt.tLength1) tSpan2 ];
    end
                            
    nb = max( ceil(opt.nBasisDensity * length( tSpan )), ...
                opt.retainedComponents );
end

if opt.do3dTransform
    for i = 1:n           
        [ xn(:,i,1), xn(:,i,2), xn(:,i,3) ] = ...
            opt.transformFunction( xn(:,i,3), xn(:,i,1), xn(:,i,2) );
        if opt.doDiscontinuityCorrection
            xn(:,i,1) = angFlipRemoval( xn(:,i,1) );
            xn(:,i,2) = angFlipRemoval( xn(:,i,2) );
        end
    end
end

if opt.doPriorRotation
    a = zeros( n, 1 );
    for i = 1:n
        [xn( :, i, : ), a(i) ] = rotateVecInitial( squeeze(xn( :, i, :)), ...
                                            opt.initOrientation, 10 );
    end
    disp(['Prior rotation mean angle = ' num2str( mean( abs(a))  ) ' deg']);
end

if opt.doRandomRotation
    for i = 1:n
        a = normrnd( 0, opt.angleSD );
        xn( :, i, : ) = rotate( squeeze(xn( :, i, :)), ...
                                            a, opt.doRandomDimension );
    end
end
        

% perform Functional Data Analysis

basis = create_bspline_basis( [tSpan(1), tSpan(end)], nb, opt.basisOrder );

xFdPar = fdPar( basis, opt.penaltyOrder, opt.lambda ); 

[ xFd, df, gcvi ] = smooth_basis( tSpan, xn, xFdPar );
gcv = sum( gcvi, 'all' );

pca = pca_fd( xFd, opt.retainedComponents, xFdPar );
disp(['Explained variance = ' num2str( sum(pca.varprop) )]);

if opt.doShowComponents
    plot_pca_fd( pca );
end

features = pca.harmscr;
totvar = sum( pca.varprop );

end


