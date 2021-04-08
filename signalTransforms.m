% ************************************************************************
% Function: signalTransforms
% Purpose:  Perform length normalisation and other transforms 
%           on the raw signal and other transformations.
%
% Parameters:
%       x: discrete series
%       syncID: indices splitting the series between pre and post
%       tLanding: landing time from VGRF used for fixing flight time
%       opt: options
%
% Output:
%       xn: transformed data series
%       tSpan: associated time series
%
% ************************************************************************


function [ normdata, tSpan ] = signalTransforms( datasets, syncID, tLand, opt )

if iscell( datasets )
    isMultiSet = true;
    nSets = length( datasets );
    normdata = cell( nSets, 1 );
else
    isMultiSet = false;
    nSets = 1;
end
    
for j = 1:nSets

    if isMultiSet
        x = datasets{ j };
    else
        x = datasets;
    end
    nCases = size( x, 1 ); % number of time series
    
    % use the resultant if required
    if opt.useResultant
        for i = 1:nCases
            x{ i } = sqrt( sum( x{ i }.^2, 2 ) );
        end
    end

    % divide the time series into two parts either side of t0
    x1 = cell( nCases, 1 );
    x2 = cell( nCases, 1 );
    for i = 1:nCases
        x1{ i } = x{ i }( 1:syncID(i), : );
        x2{ i } = flip( x{ i }( syncID(i)+1:end, : ), 1 );
    end

    if opt.tLength2 == 0
        % standard lengths
        tSpan = -opt.tLength1 : 1/opt.tFreq : 0;
        xn = aligndata( x1, 'PadStart',  ...
                            opt.tFreq, opt.maxLength, 0, true );

    else
        % pad series about the take-off point
        tSpan = -opt.tLength1 : 1/opt.tFreq : opt.tLength2;
        xn = pad2phase( x, syncID, opt.maxLength1, opt.maxLength2 ); 

        if opt.doFixedSeparation && size(xn,1) > opt.maxLength1
            [ xn2, tSpan2 ] = fixFlightTime( xn( opt.maxLength1+1:end, : ), ...
                                            tLand, ...
                                            opt.fixedSeparation );
            xn = [ xn(1:opt.maxLength1,:); xn2 ];
            tSpan = [ tSpan(1:opt.maxLength1) tSpan2 ];
        end

    end

    if opt.do3dTransform
        for i = 1:nCases           
            [ xn(:,i,1), xn(:,i,2), xn(:,i,3) ] = ...
                opt.transformFunction( xn(:,i,3), xn(:,i,1), xn(:,i,2) );
            if opt.doDiscontinuityCorrection
                xn(:,i,1) = angFlipRemoval( xn(:,i,1) );
                xn(:,i,2) = angFlipRemoval( xn(:,i,2) );
            end
        end
    end

    if opt.doPriorRotation
        a = zeros( nCases, 1 );
        for i = 1:nCases
            [xn( :, i, : ), a(i) ] = rotateVecInitial( squeeze(xn( :, i, :)), ...
                                                opt.initOrientation, 10 );
        end
        disp(['Prior rotation mean angle = ' num2str( mean( abs(a))  ) ' deg']);
    end

    if opt.doRandomRotation
        for i = 1:nCases
            a = normrnd( 0, opt.angleSD );
            xn( :, i, : ) = rotate( squeeze(xn( :, i, :)), ...
                                                a, opt.doRandomDimension );
        end
    end
    
    if isMultiSet
        normdata{j} = xn;
    else
        normdata = xn;
    end
        
end

end


