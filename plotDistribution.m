% ************************************************************************
% Function: plotDistribution
% Purpose:  Present one or a series of histograms showing the 
%           distribution of a variable
%
% Parameters:
%       x: array or table of variables in question
%       names: titles for the plots
%       onHold: whether to leave plots with 'hold on'
%
% Output:
%       Plots
%
% ************************************************************************

function plotDistribution( x, names, onHold )

% how many variables in the array
n = size( x, 2 );

[rows, cols] = sqdim( n );

for i = 1:n
    subplot( rows, cols, i );
    histogram( x(:,i), 10 );
    if ~isempty( names )
        title( names(i) );
    end
    if onHold
        hold on;
    end
end

end