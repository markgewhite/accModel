% ************************************************************************
% Function: harmfd_projection_fast
% Purpose:  Project one set of harmonic functional data objects
%           onto another using the inner product
%           Using streamlined processing - not inprod
%
% Parameters:
%       fd1: original harmonic fd
%       fd2: target harmonic fd for the original to projected onto
%
% Output:
%       P: matrix of coefficients describing the projection
%
% ************************************************************************

function P = harmfd_projection_fast( fd1, fd2 )

% determine the number of components for each
n1 = size( getcoef(fd1), 2 );
n2 = size( getcoef(fd2), 2 );

% get bases and determine integration limits
basis1 = getbasis(fd1);
basis2 = getbasis(fd2);
tRange = getbasisrange( basis1 ); % same for fd2

% compare respective time spans
t1 = getbasispar( basis1 );
t2 = getbasispar( basis2 );

% use fine time span for integration based on finest time span
dt = 0.1*min( t1(2)-t1(1), t2(2)-t2(1) );
tFine = tRange(1):dt:tRange(2);

% get a set of points for each harmonic
y1 = eval_fd( tFine, fd1 );
y2 = eval_fd( tFine, fd2 );

% get the number of dimenions for each
d1 = size( y1, 3 );
d2 = size( y2, 3 );

% get the magnitudes squared for the projection
m2 = zeros( n2, d1 );
for jd = 1:d2
    for j = 1:n2
        m2( j, jd ) = trapz( y2(:,j,jd).*y2(:,j,jd) )*dt;
    end
end
    
P = zeros( n1, n2, d1, d2 );
for id = 1:d1
    for i = 1:n1
        for jd = 1:d2
            for j = 1:n2
                P( i, j, id, jd ) = trapz( y1(:,i,id).*y2(:,j,jd) )*dt ...
                                                                /m2(j,jd);
            end
        end
    end
end

P = squeeze( P );

end

