function result = findVar(T, searchText)
% FINDVAR Find table variables containing a search string.
%   result = findVar(T, searchText)
%   Returns matching variable names and their column indices.
%
%   Example: findVar(temp, 'RH')

I = contains(T.Properties.VariableNames, searchText, 'IgnoreCase', true);

result = table(find(I)', string(T.Properties.VariableNames(I))', ...
    'VariableNames', {'Column', 'Name'});
end
