function GetDronePos
format longE; warning off;
%%file names - change the file format to .txt and change file names to Rinex.txt and Timestamp.txt

% Rinex position file
name1='Rinex.txt';

% Timestamp file
name2='Timestamp.txt';

% Images txt file
name3='Images.txt';

%% READ in position file
    C0 = readtable(name1,'HeaderLines',4);
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
    C0 = readtable(name2);
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
    C0 = readtable(name3,'ReadVariableNames',false);

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
      
      % If the Rinex and Timestamp entries occur at the same time, the camera position correction is applied to the more accurate Rinex coordinates.
      % If the Timestamp entry occurs between two Rinex entries, these points are linearly interpolated between and the estimated displacement is applied to the Rinex coordinates along with the camera correction.
      if cl==0
          TimeStamp(j,7:9)=Rinex(idx,2:4)+[TimeStamp(j,4:5),-TimeStamp(j,6)]/1000;
      else
          TimeStamp(j,7:9)=Rinex(idx,2:4)+(Rinex(idx+cl,2:4)-Rinex(idx,2:4))/(Rinex(idx+cl,5)-Rinex(idx,5))*(Hour-Rinex(idx,5))+[TimeStamp(j,4:5),-TimeStamp(j,6)]/1000;          
      end
    end
    
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
% 
name3=['UAV_camera_coords_' int2str(size(pix4d_data,1)) '.txt'];
    % ID Easting Northing Elevation   
writetable(pix4d_data,name3,'WriteVariableNames',false);
    
end
