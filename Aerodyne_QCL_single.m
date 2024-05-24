%% prep
clc
clear
% close all hidden2

%%  INFO
%conversion of the aerodyne quantum cascade laser (single) measuring COS
%from .stc and .str to .mat files for further processing.
%Handles the SPEfile text column as well as files after crashes of the
%tdl wintel software, when some columns are missing in the last line
%this Version is for choosing files manually

%% run
tic

%% check which data has been processed already

%% load data
%choose files
cf = pwd;
[FileName,PathName] = uigetfile('*.stc','Select STCs of interest','MultiSelect','on');

if iscell(FileName)
else
    FileName = cellstr(FileName);
end

%split the dataset into days and export them
mkdir ./../MAT_RAW
cd ../MAT_RAW %change directory to folder
mkdir str %create folder
mkdir stc %create folder
cd(cf)
%another prep, needs to start after folder change
mkdir('textcreator_str') %create folder where we rename our files so readtable can read it
mkdir('textcreator_stc') %create folder where we rename our files so readtable can read it
%create the txt files to read them with readtable
f = waitbar(0,'Processing');%progress bar
for k = 1:size(FileName,2) %loop over filenames for STC and STR
    waitbar(k/size(FileName,2));
    singleFN = FileName{k};  %inputfilename
    singleoutFN = strcat(singleFN(1:end-3),'txt'); %replace file extension with .txt
    inFFN = [PathName, singleFN]; %inputfilename
    outFFN = ['.\textcreator_str\',singleoutFN]; %outputfilename
    copyfile(inFFN, outFFN);   %copy files to temporary txt folder
    stc = readtable(outFFN); %import the actual file - if problems arise, use detectImportOptions !
    if size(stc,1) == 0 %if we have an empty file ->
        continue %skip it and continue with next file
    end
    %starttime - correction aka matlabtime conversion
    fid = fopen(outFFN); %file identifier to read out header
    a = textscan(fid,'%s','Delimiter','\n'); %read file
    a = a{1,1}; %open the loaded cell
    fclose(fid); %close file    
    timeext = strsplit(a{1,1},' '); %split times in header
    deli = timeext{1}(3); %extract delimiter of datetime in header
    deli = strcat('mm',deli,'dd',deli,'yyyy'); %create string as mask to convert datestr to datenum
    startdate = datenum(timeext{1},deli); %convert startdate to datenum
    starttime = datenum(timeext{2},'HH:MM:SS'); %convert starttime to datenum
    starttime = starttime - floor(starttime); % get time only, dismiss date
    startdate = startdate + starttime; %combine starttime and startdate
    start_igor = str2num(timeext{4}); %convert igortime string to number
    stc.time = startdate + (stc.time-start_igor)./(3600*24); %convert and correct Timevector    
    stc.SPEFile = NaN(size(stc.time,1),1); % The SPE column can contains filenames, not further needed, but causing problems when concatenating   
    %READ STR
    FileName2 = strrep(FileName,'.stc','.str'); %replace fileextension STC with STR
    singleFN = FileName2{k};  %inputfilename
    singleoutFN = strcat(singleFN(1:end-3),'txt'); %remplace file extension with .txt
    inFFN = [PathName, singleFN]; %inputfilename
    outFFN = ['.\textcreator_stc\',singleoutFN]; %outputfilename
    copyfile(inFFN, outFFN);   %copy files to temporary txt folder
    opts = detectImportOptions(outFFN);
    str = readtable(outFFN); %import the actual file
    if size(str,1) == 0 %if we have an empty file ->
        continue %skip it and continue with next file
    end
    %starttime - correction aka matlabtime conversion
    fid = fopen(outFFN); %file identifier to read out header
    a = textscan(fid,'%s','Delimiter','\n'); %read file
    a = a{1,1}; %open the loaded cell
    fclose(fid); %close file    
    timeext = strsplit(a{1,1},' '); %split times in header
    deli = timeext{1}(3); %extract delimiter of datetime in header.
    deli = strcat('mm',deli,'dd',deli,'yyyy'); %create string as mask to convert datestr to davenum23
    startdate = datenum(timeext{1},deli); %convert startdate to datenum
    starttime = datenum(timeext{2},'HH:MM:SS'); %convert starttime to datenum
    starttime = starttime - floor(starttime); % what is this for??
    startdate = startdate + starttime; %combine starttime and startdate
    start_igor = str2num(timeext{4}); %convert igortime string to number
    scal = strsplit(timeext{6},{':',','}); scal{1} = 'time';%extract scalars and replace SPEC with time for first column
    C = unique(scal,'stable'); %find unque values (sometimes we have double COS,CO2,..)
    %these loops rename the header - in case we have dublicate entries
    new = scal; %copy original vector
    for i = 1:size(C,2) %loop over the unique values
        idx = find(strcmp(C{i}, scal));  %search for values that match in the original vector and logical to linear index        
        for j = 2:length(idx) %loop over duplicate index
            new{idx(j)} = [scal{idx(j)}, '_', num2str(j)]; %add consecutive numbers to the duplicate scalars
        end %end loop over duplicates
    end %end loop over unique values
    scal = new; %rename the original header
    scal = strrep(scal,'OCS','COS'); %definitely the most important part of the script. COS4ever!
    str.Properties.VariableNames(1:size(scal,2)) = scal; %and set variablenames - leave in the empty column at the end, shouldn't bother us
    str(:,size(scal,2)+1:end) = []; %delete all additional columns that aren't in the header of the str
    str.time = startdate + (str.time-start_igor)./(3600*24); %convert and correct Timevector
    str.SPEFile = NaN(size(str.time,1),1); % The SPE column can contains filenames, not further needed, but causing problems when concatenating
    
    %if file saving was interrupted due to sudden shutdown of tdlwintel,
    %not whole lines are filled (also date might wrong in last line)
    if ismissing(str(end,end-1)) %if not all the data was saved and program was killed (line not full), last entry is always nan
        str(end,:) = [];
    end
    if ismissing(stc(end,end)) %if not all the data was saved and program was killed (line not full)
        stc(end,:) = [];
    end
    
    % remove rows that are just in stc or str    
    if stc.time(end) > str.time(end) %within a second
        datestr(stc.time(end))
        datestr(str.time(end))
        D = find(ismember(datenum_round_off(stc.time,'second'),datenum_round_off(str.time(end),'second')));
        stc = stc(1:D,:);
    end
    
    %save uncorrected strs and stcs as matfiles
    fileout = strrep(singleFN,'str','mat');
    data1r = str; data2r = stc;    
    save(['../MAT_RAW/str/' fileout],'data1r'); save(['../MAT_RAW/stc/' fileout],'data2r');
    clear data1 data2 str stc
end

%% clean up
delete('./textcreator_str/*.txt'); %delete all created txt files to remove the folder
delete('./textcreator_stc/*.txt'); %delete all created txt files to remove the folder
%sometimes permission problems - figure out why!!!!
rmdir textcreator_str %remove the textcreator folder
rmdir textcreator_stc %remove the textcreator folder

%end
toc 
close(f)
