function Main_AutoPRAM_f(name_of_path,name_of_folder,name_of_time)
% Autoscan+autofocus programming for the Thorlabs KDC101 with Kinesis in MATLAB, with Z812B, Z825B stages.
% /
% Copyright <2022> University of Illinois Board of Trustees. All Rights Reserved.
% This file is part of <Photonic Resonator Absorption Microscopy>, which is 
% released under specific terms.  See file License.txt file or go to <URL> for 
% full license details.
% 
% Version 2.0
% Date: 04-04-22
% Author: Weinan Liu
% /
tic
close all;
%Load assemblies
NET.addAssembly('C:\Program Files\Thorlabs\Kinesis\Thorlabs.MotionControl.DeviceManagerCLI.dll');
NET.addAssembly('C:\Program Files\Thorlabs\Kinesis\Thorlabs.MotionControl.GenericMotorCLI.dll');
NET.addAssembly('C:\Program Files\Thorlabs\Kinesis\Thorlabs.MotionControl.KCube.DCServoCLI.dll');

%Initialize Device List
import Thorlabs.MotionControl.DeviceManagerCLI.*
import Thorlabs.MotionControl.GenericMotorCLI.*
import Thorlabs.MotionControl.KCube.DCServoCLI.*

%Initialize Device List
DeviceManagerCLI.BuildDeviceList();
DeviceManagerCLI.GetDeviceListSize();

%Should change the serial number below to the one being used.
serial_num_z='27261132';
serial_num_x='27262061';
serial_num_y='27262083';
timeout_val=60000;

%Set up device and configuration
device_z = KCubeDCServo.CreateKCubeDCServo(serial_num_z);
device_z.Connect(serial_num_z);
device_z.WaitForSettingsInitialized(5000);

device_x = KCubeDCServo.CreateKCubeDCServo(serial_num_x);
device_x.Connect(serial_num_x);
device_x.WaitForSettingsInitialized(5000);

device_y = KCubeDCServo.CreateKCubeDCServo(serial_num_y);
device_y.Connect(serial_num_y);
device_y.WaitForSettingsInitialized(5000);


%% configure Z stage
motorSettings_z = device_z.LoadMotorConfiguration(serial_num_z);
motorSettings_z.DeviceSettingsName = 'Z812B';
% update the RealToDeviceUnit converter
motorSettings_z.UpdateCurrentConfiguration();

% push the settings down to device_z
MotorDeviceSettings_z = device_z.MotorDeviceSettings;
device_z.SetSettings(MotorDeviceSettings_z, true, false);
device_z.StartPolling(250);

%% configure X stage
motorSettings_x = device_x.LoadMotorConfiguration(serial_num_x);
motorSettings_x.DeviceSettingsName = 'Z812B';
% update the RealToDeviceUnit converter
motorSettings_x.UpdateCurrentConfiguration();

% push the settings down to device_x
MotorDeviceSettings_x = device_x.MotorDeviceSettings;
device_x.SetSettings(MotorDeviceSettings_x, true, false);
device_x.StartPolling(250);

%% configure Y stage
motorSettings_y = device_y.LoadMotorConfiguration(serial_num_y);
motorSettings_y.DeviceSettingsName = 'Z812B';
% update the RealToDeviceUnit converter
motorSettings_y.UpdateCurrentConfiguration();

% push the settings down to device_y
MotorDeviceSettings_y = device_y.MotorDeviceSettings;
device_y.SetSettings(MotorDeviceSettings_y, true, false);
device_y.StartPolling(250);

pause(0.5); % wait to make sure device is enabled


%% displacement intialization

ol = 0.1;                                   % overlapping ratio; 0.1 = 10% overlapping
xAdjust = 0.231*(1-ol);
yAdjust = 0.145*(1-ol);

n_i = 5;                                    % number of images along one edge
x_step = (1:n_i)*xAdjust;
y_step = (1:n_i)*yAdjust;

% z_c = 0.3;                                % z axis wiggling cooling time (second)
%% image preset
vid = videoinput('pointgrey',1,'F7_Mono16_1920x1200_Mode0');
step = 0.002;
pos = System.Decimal.ToDouble(device_z.Position);
posx = System.Decimal.ToDouble(device_x.Position);
posy = System.Decimal.ToDouble(device_y.Position);
mkdir(name_of_path,name_of_folder);

%% start autoscan
for idx = 1:length(x_step)
    for idy = 1:length(y_step)
%   record and input image 
img = getsnapshot(vid);
[IntPf0] = raPsd(img,2);

%   Move to: unit mm
device_z.MoveTo(pos + step, timeout_val);
%   pause(z_c);
pos = System.Decimal.ToDouble(device_z.Position);

% record and input image 
img = getsnapshot(vid);
[IntPf1] = raPsd(img,2);

if IntPf1 > IntPf0
    while IntPf1 > IntPf0
        IntPf0 = IntPf1;
        device_z.MoveTo(pos + step, timeout_val);
%         pause(z_c);
        pos = System.Decimal.ToDouble(device_z.Position);
%         record and input image 
        img = getsnapshot(vid);
        [IntPf1] = raPsd(img,2);
    end
elseif IntPf1 < IntPf0
    device_z.MoveTo(pos - step, timeout_val);
%         pause(z_c);
    pos = System.Decimal.ToDouble(device_z.Position);
    while IntPf1 < IntPf0
        IntPf1 = IntPf0;
        device_z.MoveTo(pos - step, timeout_val);
%         pause(z_c);
        pos = System.Decimal.ToDouble(device_z.Position);
%         record and input image 
        img = getsnapshot(vid);
        [IntPf0] = raPsd(img,2);
    end
end

%Check Position
pos = System.Decimal.ToDouble(device_z.Position);
fprintf('The motor position is %d.\n',pos);

    filename = strcat(name_of_path, '\', name_of_folder, '\', name_of_time, '_', num2str(n_i*(idx-1)+idy), '_cap.mat');
    save(filename,"img");

%     figure;
%     imshow(img,[])
%     saveas(gcf,strcat(name_of_path, '\', name_of_folder, '\', name_of_time, '_', num2str(n_i*(idx-1)+idy), '_cap.jpg'),'jpg')
% tic
    device_y.MoveTo(posy + idy * yAdjust, timeout_val);
% toc
%     pause(0.5);
% %     avoid wiggling
    end
    device_y.MoveTo(posy, timeout_val);
    device_x.MoveTo(posx + idx * xAdjust, timeout_val);
    
%     pause(0.5);
% %     avoid wiggling
end

device_z.StopPolling()
device_z.Disconnect()
device_x.StopPolling()
device_x.Disconnect()
device_y.StopPolling()
device_y.Disconnect()
toc
