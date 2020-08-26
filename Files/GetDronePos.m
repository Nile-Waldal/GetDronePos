
%% Image and Timestamp Prep
format longE; warning off;
% BEFORE INITIATING PROGRAM, USER MUST ENSURE RINEX.TXT, TIMESTAMP.TXT IS IN APPROPRIATE DIRECTORY

%Gets folder of matlab script, which should be in images folder if batch file was used
folder=pwd;

%Creates structures with information of images and timestamp.MRK
filenames=dir('*_*_*.jpg');
time=dir('*_Timestamp.MRK');

%Creates tables for image names and timestamp
opts=detectImportOptions(time.name,'FileType','text');
names=cell2table({filenames.name}','VariableNames',{'Names'});
C1=readtable(time.name,opts);


%Preallocates images.txt table
m1=table('Size',[size(names,1),4],'VariableTypes',{'string','double','double','double'});

for i = 1:size(names,1)
    
    % goes through every single name in 1st column
    extract0 = names{i,1} ;
    extract1= extract0{1};
    % counts image file name upwards
    extract = strcat(folder, '\', extract1);                            
    info = imfinfo(extract);
    lat = dms2degrees(info.GPSInfo.GPSLatitude);
    lon = dms2degrees(info.GPSInfo.GPSLongitude);
    alt = info.GPSInfo.GPSAltitude;                                 
    if strcmp(info.GPSInfo.GPSLatitudeRef,'S')
        lat = -1 * lat;
    end
    if strcmp(info.GPSInfo.GPSLongitudeRef,'W')
        lon = -1 * lon;
    end
    
    % creation of images.txt table; 1st column is name
 	m1{i,1} = extract0;                                             
    m1{i,2} = lat;
    m1{i,3} = lon;
    m1{i,4} = alt;
end

%Creates timestamp table with images not in directory excluded
for i=1:size(names,1)
    ent=m1{i,1};
    imname=ent{1};
    id=str2double(imname(10:13));
    idtimestamp=C1{:,1};
    idx=find(idtimestamp==id);
    Row=C1(idx,:);
    TimestampNew(i,:)=Row;
end

%% READ in position file
name1='Rinex.txt';
C0 = readtable(name1,'HeaderLines',5);
Rinex = zeros(size(C0,1),5);
for k=1:size(C0,1)
    % Year
    Rinex(k,1)=C0{k,4};
    % UTM Northing
    Rinex(k,2)=C0{k,30};
    % UTM Easting
    Rinex(k,3)=C0{k,29};
    % Elevation, it should be in the CGVD2013 system
    Rinex(k,4)=C0{k,38};
    % Time in hours since beginning of UTC day
    Rinex(k,5)= (Rinex(k,1)-fix(Rinex(k,1)))*24.0;
end
    
%% READ in TimeStamp file
C0 = TimestampNew;
TimeStamp=zeros(size(C0,1),10);

for i=1:size(C0,1)    
    % ID
    TimeStamp(i,1)=C0{i,1};
    % Seconds after beginning of the GPS week
    TimeStamp(i,2)=C0{i,2};
    % GPS week (continuous from Jan 5. 1980 - the true GPS Week Number count began around midnight on Jan. 5, 1980, with two resets once hitting 1,023)
    WeekNo=C0{i,3};
    WeekNo=WeekNo{1,1};
    TimeStamp(i,3)=str2double(WeekNo(2:end-1));
    % Correction Northing
    NorthCor=C0{i,4};
    NorthCor=NorthCor{1,1};
    TimeStamp(i,4)=str2double(NorthCor(1:end-2));
    % Correction Easting
    EastCor=C0{i,5};
    EastCor=EastCor{1,1};
    TimeStamp(i,5)=str2double(EastCor(1:end-2));
    % Correction Elevation
    ElevCor=C0{i,6};
    ElevCor=ElevCor{1,1};
    TimeStamp(i,6)=str2double(ElevCor(1:end-2));
    % Locations for storing corrected N E Elev
    TimeStamp(i,7)=0;
    TimeStamp(i,8)=0;
    TimeStamp(i,9)=0;
    % Time in hours since beginning of GPS week
    TimeStamp(i,10)=TimeStamp(i,2)/60/60-fix(TimeStamp(i,2)/60/60/24)*24;
end

%% READ Images' name
C0 = m1;

%% READ Stamp Location - GPS continuous week count of 2055 starts on 2019-May-26 (Sunday) UTC
% Under UTC, time jumps every midnight and needs correction
for j1=1:size(TimeStamp,1)-1
    if abs(TimeStamp(j1,10)-TimeStamp(j1+1,10))>23
        TimeStamp(j1+1:end,10)=TimeStamp(j1+1:end,10)+24; 
    end
end

for j=1:size(Rinex,1)-1
    if abs(Rinex(j,5)-Rinex(j+1,5))>23
        Rinex(j+1:end,5)=Rinex(j+1:end,5)+24;
    end
end

% DJI captures images every t second. GPS location is recorded every 0.2s. Assuming constant velocity, timestamp is linearly interpolated.
for j=1:size(TimeStamp,1) 
    Hour=TimeStamp(j,10);
    
    % Finds closest Rinex time to the Timestamp time and determines index of its column.
    [~,idx]=min(abs(Hour-Rinex(:,5)));
    
    % Determines whether Rinex entry is before or after Timestamp entry to determine which point should be taken for the interpolation.
    cl=sign(Hour-Rinex(idx,5));
    
    %Determines the number of points (either side of center) to consider for interpolation.
    points = 2; 
    
    % If the Rinex and Timestamp entries occur at the same time, the camera position correction is applied to the more accurate Rinex coordinates.
    % If the Timestamp entry occurs between two Rinex entries, these points are have a polynomial fit between them and the estimated displacement is applied to the Rinex coordinates along with the camera correction.
    % If the index of the closest Rinex entry is at the beginning or end of
    % the array, no interpolation is done
    % If the index of the closest Rinex entry is one from the end or the
    % beginning, not enough points are present for a polynomial fit, so a
    % linear interpolation is performed.
    if cl==0 || idx==size(Rinex,1) || idx==1
        TimeStamp(j,7:9)=Rinex(idx,2:4)+[TimeStamp(j,4:5),-TimeStamp(j,6)]/1000;
    elseif idx==size(Rinex,1)-points+1 || idx==points
        TimeStamp(j,7:9)=Rinex(idx,2:4)+(Rinex(idx+cl,2:4)-Rinex(idx,2:4))/(Rinex(idx+cl,5)-Rinex(idx,5))*(Hour-Rinex(idx,5))+[TimeStamp(j,4:5),-TimeStamp(j,6)]/1000;
    else
        DataSet = Rinex(idx-points:idx+points,1:5);
        northFit = polyfit(DataSet(:,5),DataSet(:,2),10);
        eastFit = polyfit(DataSet(:,5),DataSet(:,3),10);
        elevFit = polyfit(DataSet(:,5),DataSet(:,4),10);
        
        TimeStamp(j,7) = polyval(northFit,Hour) + TimeStamp(j,4)/1000;                          % ARE THESE VARIABLES USED LATER ON???!!
        TimeStamp(j,8) = polyval(eastFit,Hour) + TimeStamp(j,5)/1000;
        TimeStamp(j,9) = polyval(elevFit,Hour) - TimeStamp(j,6)/1000;          
    end
end

%Graphs for images
hold on;
plot3(TimeStamp(:,8),TimeStamp(:,7),TimeStamp(:,9),'b-x');
title('Drone Path');
xlabel('Easting Coordinates'); 
ylabel('Northing Coordinates');
saveas(gcf,'DronePath.jpg');

pix4d_data=C0;
for j=1:size(C0,1)
    Rows=C0{j,1};
    ImageNoChar=Rows{1};
    ImageNo=str2double(ImageNoChar(10:13));
    d=find(ImageNo==TimeStamp(:,1));
    pix4d_data(j,2)={TimeStamp(d,8)};
    pix4d_data(j,3)={TimeStamp(d,7)};
    pix4d_data(j,4)={TimeStamp(d,9)};
end
name3=['UAV_camera_coords_' int2str(size(pix4d_data,1)) '.txt'];
% ID Easting Northing Elevation   
writetable(pix4d_data,name3,'WriteVariableNames',false);    
