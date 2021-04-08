% ************************************************************************
% Function: pca_fd_score
% Purpose:  Calculate the FPC scores for an exsting FPC basis
%           This code has been extracted from Ramsay's pca_fd function
%           and modified accordingly
%
% Parameters:
%       fdobj: data as a functional data object
%       meanfd: mean curve as a functional data object
%       harmfd: FPC basis
%       nharm: number of retained components in PCA
%       doCentreFd: whether to centre functions
%
% Output:
%       harmscr: FPC scores
%
% ************************************************************************


function harmscr = pca_fd_score( fdobj, meanfd, harmfd, nharm, doCentreFd )

fdbasis  = getbasis( fdobj );

coef   = getcoef(fdobj);
coefd  = size(coef);
nrep   = coefd(2);
ndim   = length(coefd);

if ndim == 3
    nvar  = coefd(3);
else
    nvar = 1;
end

% centre the data about the mean
%onebas = ones(1, nrep);
%for j = 1:nvar
%    coefmean = mean(coef(:,:,j),2);
%    coef(:,:,j) = coef(:,:,j) - coefmean * onebas;
%end

%centerfd.coef     = coef;
%centerfd.basisobj = fdbasis;
%centerfd.fdnames  = fdnames;

%fdobj = class(centerfd, 'fd');

if doCentreFd
    fdobj = fdobj - meanfd;
end

%  set up harmscr

if nvar == 1
    harmscr = inprod(fdobj, harmfd);
else
    harmscr       = zeros(nrep, nharm, nvar);
    coefarray     = getcoef(fdobj);
    harmcoefarray = getcoef(harmfd);
    for j=1:nvar
        coefj     = squeeze(coefarray(:,:,j));
        harmcoefj = squeeze(harmcoefarray(:,:,j));
        fdobjj    = fd(coefj, fdbasis);
        harmfdj   = fd(harmcoefj, fdbasis);
        harmscr(:,:,j) = inprod(fdobjj,harmfdj);
    end
end


end