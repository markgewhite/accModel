% ************************************************************************
% Function: registerCurves
% Purpose:  Perform landmark registration on curves
%
% Parameters:
%       xFd: smooth continuous functions
%       xFdParams: associated parameters
%       opt: options
%
% Output:
%
%
% ************************************************************************

function [ xFdLM, wFd ] = registerCurves( xFd, ...
                                          tSpan, ...
                                          landmarks, opt )

%  Set up a simple monomial basis for landmark registration

wBasis = create_bspline_basis( ...
                        [tSpan(1),tSpan(end)], ...
                        opt.nBasis, ...
                        opt.basisOrder, ...
                        [tSpan(1) landmarks.mean tSpan(end)] );

wFd    = fd( zeros( opt.nBasis, 1 ), wBasis );
wFdPar = fdPar( wFd, 1, opt.wLambda );

% call the landmark registration routine
[ xFdLM, wFd ] = landmarkreg( xFd, ...
                            landmarks.case,...
                            landmarks.mean, ...
                            wFdPar, ...
                            true, ...
                            opt.yLambda );

end

