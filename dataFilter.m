% ************************************************************************
% Function: dataFilter
% Purpose:  Define a filter for the data
%
% Parameters:
%       data: data structure
%       opt: data options
%
% Output:
%       f: filter
%
% ************************************************************************


function f = dataFilter( data, opt )

f = true( length( data.outcome ), 1 );

% sample size
if opt.doReduceSample
    opt.method = opt.reducedSampleMethod; % put it in correct structure
    opt.kFolds = 0;
    f = partitionData( data.outcome, data.subject, opt );
end

% jump type
switch opt.arms
    case 'No Arms'
        f = f & ~data.withArms;
    case 'With Arms'
        f = f & data.withArms;
end

% sex
switch opt.sex
    case 'Male'
        f = f & data.sex=={'Male'};
    case 'Female'
        f = f & data.sex=={'Female'};
end

% performance level
switch opt.perfLevel
    case 'Low'
        f = f & data.perfLevel==1;
    case 'Intermediate'
        f = f & data.perfLevel==2;
    case 'High'
        f = f & data.perfLevel==3;
end

    
end
