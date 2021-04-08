% ************************************************************************
% Function: smoothDataFast
% Purpose:  Smooth a dataset using functional data analysis
%           without checks
%
% Parameters:
%       x: the dataset in question
%       t: time vector
%       opt: options
%
% Output:
%       xFd: smoothed functional data object
%       xFdPar: parameters of the functional data object
%
% ************************************************************************


function [ xFd, xFdPar ] = smoothDataFast( x, t, opt )

basis = create_bspline_basis(   [t(1) , t(end)], ...
                                opt.nBasis, ...
                                opt.basisOrder );

xFdPar = fdPar( basis, opt.penaltyOrder, opt.lambda ); 

xFd = smooth_basis( t, x, xFdPar );


end