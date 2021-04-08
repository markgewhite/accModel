% ************************************************************************
% Function: tblFieldNames
% Purpose:  Define table field names by concatenating a series of
%           strings that will be the common field base name
%           with increments for the number of fields specified
%
% Parameters:
%       n: number of fields
%       subNames: array of field base sub-names
%
% Output:
%       fieldNames: array fo field names
%
% ************************************************************************


function fieldNames = tblFieldNames( n, subNames )

baseName = '';
for i = 1:size( subNames, 2 )
    baseName = strcat( baseName, subNames{i} );
end

fieldNames = strings( n, 1 );
for i = 1:n
    fieldNames(i) = strcat( baseName, num2str( i, '%0.3d' ) );
end

end