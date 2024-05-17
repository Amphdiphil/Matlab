%% info 
% extract data from the profiwetter.ch page
%% prep
clc
clear all
close all
%% hardcoded input
H.d = 1:100; % index for loading the daily max temp %35/36:43
H.p = 8; %there will always be 8 temperature values (panels)
%% load
url = 'https://profiwetter.ch/mos_11120.svg';
filename = 'downloaded_image.svg';
websave(filename, url);
pause(5)
svgText = fileread(filename);

%extract max Temp
lines = splitlines(svgText);
lines = string(lines);
% lines = cell2table(lines);

%find temperature section
T = find(contains(lines(:,1),'<!-- Temperatur (°C) -->'));%position before max temp
f = strcat('<g id="text_',string(H.d),'">');
f = find(contains(lines(:,1),f));%position before max temp

%get rid of all entries before max and min temp
f(f<=T) = [];
fnight = f(H.p+1:H.p+H.p); f = f(1:H.p);
f = f+1; %max temp of following day
fnight = fnight+1; %min temp
mT = lines(f);
nightT = lines(fnight);

% Use regex to clean the strings by removing everything except numbers and decimal points
mT = regexprep(mT, '[^\d.]+', ''); %cleand strings
nightT = regexprep(nightT, '[^\d.]+', ''); %cleand strings
nightT = [NaN;nightT]; %its always the following night
nightT = nightT(1:end-1); %remove the empty one
mT = [mT,nightT];%combine day and night max and min

% Convert the cleaned strings to an array of doubles
mT = array2table(str2double(mT),'VariableNames',{'Ta','Tan'}); %air temp
mT.d = datetime(today+[0:1:size(mT,1)-1]','ConvertFrom','datenum'); %day

if exist('ProfiTemp.mat')
    nT = mT; %new temp
    load("ProfiTemp.mat") %load mT -> old temp;
    %just for adding a new variable to an "old" table
    % mT.Tan = NaN(size(mT,1),1);
    % mT = mT(:, [1 3 2]);
    [~,f] = intersect(nT.d,mT.d); %find days that will get an update
    [~,fo] = intersect(mT.d,nT.d); %find days that will get an update
    mTb = mT; %backup
    mT(fo,:) = nT(f,:); %update the day
    %except for the night of the first day -> we don't want to replace value with nan
    pnan = max(find(isnan(mT.Tan))); %position of the last nan (today)
    mT.Tan(pnan) = mTb.Tan(pnan); 
    nT(f,:) = []; %remove the days so we can add the rest to the bottom
    mT = [mT;nT];
    clear nT
end
save('ProfiTemp.mat','mT'); %export
