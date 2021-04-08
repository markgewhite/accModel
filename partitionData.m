% ************************************************************************
% Function: partitionData
% Purpose:  Partition augmented data
%
% Parameters:
%       y: response (vector)
%       s: subject ID (vector)
%       opt: options
%
% Output:
%       trnSelect: array selecting training data
%       valSelect: array selecting validation data
%       tstSelect : array selecting testing data
%
% ************************************************************************


function [ trnSelect, valSelect, tstSelect ] = partitionData( y, s, opt )

n = size( y, 1 );

if opt.doControlRandomisation
    randomState = rng; % preserve current randomiser state
    rng( opt.randomSeed ); % reset seed for random number generator
end

switch opt.method
    
    case 'KFold'

        trnSelect = false( size(y,1), opt.kFolds );
        valSelect = false( size(y,1), opt.kFolds );
        tstSelect = [];
        
        % partition the original data into training and testing samples
        partitionedCases = cvpartition( y, ...
                                        'kfold', opt.kFolds, ...
                                        'Stratify', false );

        for i = 1:opt.kFolds
            % extract the logical array of testing and training
            trnSelect( :, i ) = partitionedCases.training( i );
            valSelect( :, i ) = partitionedCases.test( i );
        end
        
    case 'MonteCarlo'
        
        % Monte Carlo cross validation by trial
        % partitions for each fold are independent, folds overlap
        % sampling is without replacement
        % no duplicates within a fold, but across folds
                
        trnSelect = false( size(y,1), opt.iterations );
        valSelect = false( size(y,1), opt.iterations );
        tstSelect = [];
        
        nTrain = fix( (1-1/opt.kFolds)*n);
        allCases = 1:n;
        for i = 1:opt.iterations
            cases = logical( sum( ...
                    (allCases == randsample( n, nTrain, false )) ));
            trnSelect( :, i ) = cases;
            valSelect( :, i ) = ~cases;
        end
        
    case 'Bootstrap'
        
        % Bootstrap partitioning 
        % partitions for each fold are independent, folds overlap
        % sampling is with replacement
        % duplicates within a fold and across folds
        
        trnSelect = zeros( size(y,1), opt.iterations );
        valSelect = zeros( size(y,1), opt.iterations );
        tstSelect = [];
        
        allCaseIDs = 1:n;
        for i = 1:opt.iterations
            trnCaseIDs = randsample( n, n, true );
            valCaseIDs = setdiff( allCaseIDs, trnCaseIDs );
            trnSelect( :, i ) = trnCaseIDs;
            valSelect( 1:length(valCaseIDs), i ) = valCaseIDs;
        end
        
 
    case 'KFoldSubject'

        trnSelect = false( size(y,1), opt.iterations );
        valSelect = false( size(y,1), opt.iterations );
        tstSelect = [];
        
        % identify unique subjects
        sID = unique( s );
        
        for i = 1:opt.iterations/opt.kFolds
            % for each repeat of k-fold
            
            % partition based on subjects
            partitionedSubjects = cvpartition( sID, ...
                                            'kfold', opt.kFolds, ...
                                            'Stratify', false );

            for k = 1:opt.kFolds
                % extract the logical array of testing and training
                trnSelect( :, (i-1)*opt.kFolds+k ) = ismember( s, ...
                                        sID(partitionedSubjects.training(k)) );
                valSelect( :, (i-1)*opt.kFolds+k ) = ismember( s, ...
                                        sID(partitionedSubjects.test(k)) );
            end
        end


    case 'MonteCarloSubject'
        
        % Monte Carlo cross validation by subject
        % partitions for each fold are independent, folds overlap
        % sampling is without replacement
        % no duplicates within a fold, but across folds
               
        trnSelect = false( size(y,1), opt.iterations );
        valSelect = false( size(y,1), opt.iterations );
        tstSelect = [];
        
        % identify unique subjects
        sID = unique( s );
        nSubjects = length( sID );
        
        nTrain = fix( (1-1/opt.kFolds)*nSubjects);
        for i = 1:opt.iterations
            subjects = sID(randsample( nSubjects, nTrain, false ));
            trnSelect( :, i ) = ismember( s, subjects);
            valSelect( :, i ) = ~trnSelect( :, i );
        end
        
        
    case 'BootstrapSubject'

        % Bootstrap partitioning by subject with leave one out
        % partitions for each fold are independent, folds overlap
        % sampling is with replacement
        % duplicates within a fold and across folds

        trnSelect = zeros( size(y,1), opt.iterations );
        valSelect = zeros( size(y,1), opt.iterations );
        tstSelect = [];
        
        % identify unique subjects
        sID = unique( s );
        nSubjects = length( sID );
        allCaseIDs = 1:n;
        for i = 1:opt.iterations
            trnSubjectIDs = sID( randsample( nSubjects, nSubjects-1, true ) );
            trnCaseIDs = [];
            for j = 1:length( trnSubjectIDs )
                trnCaseIDs = [ trnCaseIDs; find( s==trnSubjectIDs(j) ) ]; %#ok<AGROW>
            end
            % trnCaseIDs = unique(trnCaseIDs);
            valCaseIDs = setdiff( allCaseIDs, trnCaseIDs );
            trnSelect( 1:length(trnCaseIDs), i ) = trnCaseIDs;
            valSelect( 1:length(valCaseIDs), i ) = valCaseIDs;
        end 
        
        
    case 'LeaveOut'
        % partition the original data into training, validation and testing samples
        
        trnSelect = false( size(y,1), opt.kFolds );
        valSelect = false( size(y,1), opt.kFolds );
        tstSelect = false( size(y,1), opt.kFolds );
        
        for i = 1:opt.kFolds

            [ trnID, vaID, tstID ] = ...
                        dividerand( n, ...
                                opt.split(1), opt.split(2), opt.split(3) );
            trnSelect( :, i ) = index2logical( trnID, n );
            valSelect( :, i ) = index2logical( vaID, n );
            tstSelect( :, i ) = index2logical( tstID, n );

        end

        
    case 'LeaveOneOut'
        
        trnSelect = false( size(y,1), opt.kFolds );
        valSelect = false( size(y,1), opt.kFolds );
        tstSelect = [];
        
        % partition leaving one test case out each time
        partitionedCases = cvpartition( y, 'LeaveOut' );

        for i = 1:length( y )
            % extract the logical array of testing and training
            trnSelect( :, i ) = partitionedCases.training(i);
            valSelect( :, i ) = partitionedCases.test(i);
        end
        
        
     case 'LeaveOneOutSubject'

        trnSelect = false( size(y,1), opt.kFolds );
        valSelect = false( size(y,1), opt.kFolds );
        tstSelect = [];
         
        % identify unique subjects
        sID = unique( s );
        
        % partition based on subjects
        partitionedSubjects = cvpartition( sID, 'LeaveOut' );

        for i = 1:length( sID )
            % extract the logical array of testing and training
            trnSelect( :, i ) = ismember( s, ...
                                    sID(partitionedSubjects.training(i)) );
            valSelect( :, i ) = ismember( s, ...
                                    sID(partitionedSubjects.test(i)) );
        end

        
    case 'ReduceSubject'
        
        % Reduce the number of subjects at random
        % to simulate a smaller original sample
        % This is a single iteration operation with no validation set
               
        valSelect = [];
        tstSelect = [];
        
        % identify unique subjects
        sID = unique( s );
        nSubjects = length( sID );
        
        subjects = sID(randsample( nSubjects, opt.reducedSize, false ));
        trnSelect = ismember( s, subjects);
    
    
    case 'ReduceThinSubject'
        
        % Reduce the number of subjects at random
        % and thin out the number of samples per subject
        % This is a single iteration operation with no validation set
               
        valSelect = [];
        tstSelect = [];
        
        % identify unique subjects
        sID = unique( s );
        nSubjects = length( sID );
        
        subjects = sID(randsample( nSubjects, opt.reducedSize, false ));
        trnSelect = ismember( s, subjects);
        
        for i = 1:length( subjects )
            subjectSamples = find( subjects(i)==s );
            thinnedSamples = randsample( subjectSamples, ...
                         min([ opt.reducedSamplesPerSubject ...
                                length( subjectSamples ) ]) );
            trnSelect( setdiff(subjectSamples, thinnedSamples) ) = false;
        end
        
        
    case 'Subset'
        % control the subsets from which training and testing data
        % are taken from - which need not be the same
        
        trnSelect = false( size(y,1), opt.kFolds );
        valSelect = false( size(y,1), opt.kFolds );
        tstSelect = [];
              
        % find sorte the data in ascedning order of performance (response)
        y1 = sort( y );
        halfway = round( length( y1 )/2, 0 );
        
        switch opt.trainSubset
            case 'Full'
                trnMinID = 1;
                trnMaxID = n;
            case 'BottomHalf'
                trnMinID = 1;
                trnMaxID = halfway;
            case 'TopHalf'
                trnMinID = halfway+1;
                trnMaxID = n;
        end
        
        switch opt.testSubset
            case 'Full'
                tstMinID = 1;
                tstMaxID = n;
            case 'BottomHalf'
                tstMinID = 1;
                tstMaxID = halfway;
            case 'TopHalf'
                tstMinID = halfway+1;
                tstMaxID = n;
        end
        
        disp(['Subset partitioning. Training = ' opt.trainSubset ...
                '; Testing = ' opt.testSubset ]);
        
        for i = 1:opt.kFolds

            [ trnID1, tstID1 ] = dividerand( n, opt.split(1), opt.split(3) );
            trnID1 = trnID1( trnID1>=trnMinID & trnID1<=trnMaxID )';
            tstID1 = tstID1( tstID1>=tstMinID & tstID1<=tstMaxID )';
            
            trnID0 = zeros( length(trnID1), 1 );
            for j = 1:length(trnID1)
                trnID0(j) = find( y == y1( trnID1(j) ) );
            end
            tstID0 = zeros( length(tstID1), 1 );
            for j = 1:length(tstID1)
                tstID0(j) = find( y == y1( tstID1(j) ) );
            end
            
            trnSelect( :, i ) = index2logical( trnID0, n );          
            valSelect( :, i ) = index2logical( tstID0, n );        

        end


end

% invert the selections if desired/needed
if ~isfield( opt, 'doInversion' )
    opt.doInversion = false;
end
if opt.kFolds == 1 || opt.doInversion
    % swap
    temp = trnSelect;
    trnSelect = valSelect;
    valSelect = temp;
end

if opt.doControlRandomisation
    rng( randomState ); % restore random generator state
end
    
end