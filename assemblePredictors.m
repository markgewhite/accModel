% ************************************************************************
% Function: assemblePredictors
% Purpose:  Construct a superset of predictors based on sets of 
%           predictors comprising FPC scores generated from a
%           collection of associated curves.
%
% Parameters:
%       dataFd: cell array for FD objects, each a curve
%       paramsFd: functional data parameters
%       trainSelect: logical array identifying training cases
%       testSelect: logical array identifying testing cases
%       opt: options for FDA
%
% Output:
%       predTrain: predictors as FPC scores for training
%       predTest: predictors as FPC scores for testing
%       fpca: FPCA data structure for reference
%
% ************************************************************************


function [ predTrain, predTest, fpca ] = assemblePredictors( ...
                dataFd, warpFd, paramsFd, trainSelect, testSelect, opt )

nSets = length( dataFd ); % number of sets

if exist( 'opt.rotation', 'var' )
    opt.doVarimax = (opt.rotation==1);
end

doWarp = ~isempty( warpFd ); % include FPC scores from time warping?

% use the coefficient matrix to obtain details data dimensions
% assume the first data object is the same as the rest
coef = getcoef( dataFd{1} );
coefDim = size( coef );
if length( coefDim ) == 3
    nDim = coefDim( 3 );
else
    nDim = 1;
end
fpca = cell( nDim, 1 );
    
% allocate space for the predictor arrays
nTrain = length(find( trainSelect ));
nTest = length(find( testSelect ));
nComp = opt.nRetainedComp;
nCompWarp = opt.nRetainedCompWarp * doWarp;

nBlock = nComp*nDim + nCompWarp;

predTrain = zeros( nTrain, nSets*nBlock );
predTest = zeros( nTest, nSets*nBlock );
predNames = strings( nSets*nBlock, 1 );

for i = 1:nSets

    doWarp = (doWarp && i==nSets); % last time only
    
    if opt.doFPCApartitioning

        trainFd = dataFd{i}( trainSelect );

        % determine the FPCs based on the training data
        
        % amplitude FPCs
        fpca{i} = pca_fd2( trainFd, nComp, paramsFd, opt.doCentreFunctions );

        if opt.doFPCApartitioningComparison
            % for comparison, generate FPCs for full dataset
            pca_full = pca_fd2( dataFd{i}, nComp,   ...
                                    paramsFd, opt.doCentreFunctions );
            compareFPCAPartitions( fpca{i}, pca_full );
        end
        
        if opt.doVarimax
            fpca{i} = varmx_pca( fpca{i} );
        end
        
        if doWarp
            % temporal FPCs
            trainWFd = warpFd( trainSelect );           
            pcaWarp = pca_fd2( trainWFd, nCompWarp, paramsFd, opt.doCentreFunctions );
            if opt.doVarimax
                pcaWarp = varmx_pca( pcaWarp );
            end
            trainScores = [ fpca{i}.harmscr pcaWarp.harmscr ];
        
        else    
            trainScores = fpca{i}.harmscr;
        end

        pStart = nBlock*(i-1)+1;
        pEnd = nBlock*i;

        % extract the FPC scores for the training data
        predTrain( :, pStart:pEnd ) = reshape( ...
                                        trainScores, ...
                                        nTrain, nBlock );                           

        % determine the FPC scores for the test data
        % using the training FPCs
        
        if any( testSelect )
            testFd = dataFd{i}( testSelect );
            testScoresAmpl = pca_fd_score( testFd, fpca{i}.meanfd, fpca{i}.harmfd, ...
                                            nComp, opt.doCentreFunctions );

            if doWarp
                testWFd = warpFd( testSelect );
                testScoresTemp = pca_fd_score( testWFd, pcaWarp.meanfd, pcaWarp.harmfd, ...
                                            nCompWarp, opt.doCentreFunctions );
                testScores = [ testScoresAmpl testScoresTemp ];
            else
                testScores = testScoresAmpl;
            end

            predTest( :, pStart:pEnd ) = reshape( ...
                                            testScores, ...
                                            nTest, nBlock );
        end

    else
    
        % determine the FPCs based on all the data
        
        % amplitude FPCs
        fpca{i} = pca_fd2( dataFd{i}, nComp, paramsFd, opt.doCentreFunctions );
        if opt.doVarimax
            fpca{i} = varmx_pca( fpca{i} );
        end
        
        if doWarp
            % temporal FPCs
            pcaWarp = pca_fd2( warpFd, nCompWarp, paramsFd, opt.doCentreFunctions );
            if opt.doVarimax
                pcaWarp = varmx_pca( pcaWarp );
            end
            scores = [ fpca{i}.harmscr pcaWarp.harmscr ];
        else
            scores = fpca{i}.harmscr;
        end
        
        pStart = nBlock*(i-1)+1;
        pEnd = nBlock*i;

        % extract the FPC scores for the training data
        predTrain( :, pStart:pEnd ) = reshape( ...
                                scores( trainSelect, :, : ), ...
                                nTrain, nBlock );                               

        % determine the FPC scores for the test data
        % using the training FPCs
        
        if any( testSelect )
            predTest( :, pStart:pEnd ) = reshape( ...
                                scores( testSelect, :, : ), ...
                                nTest, nBlock );
        end
        
        if opt.doPlotComponents
            plotSignalComponents( fpca{i} );
        end

    end
    
    % assign generic names       
    if doWarp
        predNames( pStart: pEnd-nCompWarp ) = ...
                    tblFieldNames( nBlock-nCompWarp, ...
                                    {[ num2str(i) 'FPCampl' ]} );
        predNames( pEnd-nCompWarp+1: pEnd ) = ...
                    tblFieldNames( nCompWarp, ...
                                    {[ num2str(i) 'FPCtemp' ]} );
    else
        predNames( pStart: pEnd ) = ...
                    tblFieldNames( nBlock, ...
                                    {[ num2str(i) 'FPC' ]} );
    end   
    
end
    
    
% create the tables
predTrain = array2table( predTrain );
predTest = array2table( predTest );

predTrain.Properties.VariableNames = predNames;
predTest.Properties.VariableNames = predNames;


end

