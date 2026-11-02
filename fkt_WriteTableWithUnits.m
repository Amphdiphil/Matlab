function [] = fkt_WriteTableWithUnits(TableToWtrite, FileName)
%fkt_WriteTableWithUnits
% To write tables with names and units of columns and row names
[RowNum, ColNum]=size(TableToWtrite);
HeaderRow=cell(1,ColNum);
% HeaderRow{1,1}='Rows';
TableToSave=cell2table(cell(RowNum+1, ColNum));
for iCol=1:ColNum
    HeaderRow{1,iCol}=TableToWtrite.Properties.VariableUnits{iCol};
end
TableToSave{1,:}=HeaderRow;
% TableToSave{2:end,1}=TableToWtrite.Properties.RowNames(:);
TableToSave{2:end,1:end}=table2cell(TableToWtrite(:,:));
TableToSave.Properties.VariableNames = TableToWtrite.Properties.VariableNames;
writetable(TableToSave,FileName,'WriteVariableNames',true,'Delimiter','\t','Encoding', 'UTF-8');
end