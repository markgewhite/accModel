% ************************************************************************
% Function: compareFPCAPartitions
% Purpose:  Compare FPCA partitions using a projection matrix
%
% Parameters:
%       pca1: 1st PCA data structure
%       pca2: 2nd PCA data structure
%
% Output:
%       Plots and text
%
% ************************************************************************

function compareFPCAPartitions( pca1, pca2 )

P = harmfd_projection_fast( pca1.harmfd, pca2.harmfd );

pcaBasis = getbasis( pca1.meanfd );
tRange = getbasisrange( pcaBasis );
tSpan = getbasispar( pcaBasis );
tFine = tRange(1):0.1*(tSpan(2)-tSpan(1)):tRange(2);

y1 = [ eval_fd( tFine, pca1.meanfd ) eval_fd( tFine, pca1.harmfd )];
y2 = [ eval_fd( tFine, pca2.meanfd ) eval_fd( tFine, pca2.harmfd )];

nComp = size( P, 2 ); % same for both
d = size( P, 3 ); % same for both

[ figRows, figCols ] = twofactors( nComp+1 );

for i = 1:d

    Q = P( :, :, i, i );

    fpcVar = diag( Q ).^2;
    disp(['FPC Partitioning Variance = (' ...
                num2str(i) ',' num2str(i) ') = ' ...
                num2str( fpcVar', '%1.3f ')]);

    clf;
    for k = 0:nComp
        subplot( figRows, figCols, k+1 );
        hold on; 
        if k == 0
            title('Mean');
        else
            title(['FPC' num2str(k)]);
        end
        plot( tFine, y1(:,k+1,i), 'k', 'LineWidth', 1 );
        plot( tFine, y2(:,k+1,i), 'b', 'LineWidth', 1 );
        hold off;
        xlabel('Time (ms)');
        ylabel('Acceleration (g)');
    end              
    pause;
        
end

end