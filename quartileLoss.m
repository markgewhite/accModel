% ************************************************************************
% Function: quartileLoss
% Purpose:  Calculate the loss for each quartile
%
%
% Parameters:
%       Y: true outcome values
%       Yhat: predicted outcome values
%
% Output:
%       loss: 4-element vector
%
% ************************************************************************

function loss = quartileLoss( Y, Yhat )

[ ~, orderID ] = sort( Y, 'Ascend' );

quarterN = fix( length(Y)/4 );

q1ID = orderID( 1:quarterN );
q2ID = orderID( quarterN+1:2*quarterN );
q3ID = orderID( 2*quarterN+1:3*quarterN );
q4ID = orderID( 3*quarterN+1:end );

loss(1) = sqrt( sum((Yhat(q1ID)-Y(q1ID)).^2) / length( q1ID ) );
loss(2) = sqrt( sum((Yhat(q2ID)-Y(q2ID)).^2) / length( q2ID ) );
loss(3) = sqrt( sum((Yhat(q3ID)-Y(q3ID)).^2) / length( q3ID ) );
loss(4) = sqrt( sum((Yhat(q4ID)-Y(q4ID)).^2) / length( q4ID ) );
                    
end