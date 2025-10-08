%%
% ShowAPRAM: convert mat file into jpg image file. 
% Make sure to use correct name of the images, use "ctrl+R" to commment the
% "close all" command, so the generated images will stay on the window. Use
% "ctrl+T" to uncomment

name_of_path ='C:\Users\liuwe\PhD study\Projects\AutoPRAM\Images\LargeFOV\';
name_of_folder ='Tiling_manu';
name_of_time ='Dried';

m = 5;                                                                      % number of images along one side
for i = 1 : m*m
dir = load(strcat(name_of_path, '\', name_of_folder, '\', name_of_time, '_', num2str(i), '_cap.mat'));

se = strel('disk',15);                      
tophatFiltered = imtophat(imcomplement(dir.img),se);
I_bgr = imcomplement(tophatFiltered);                                       % BG removed image

figure;
a = imshow(I_bgr,'border','tight');
caxis([40000 65535]);
saveas(gcf,strcat(num2str(i),'_bgr.png'),'png')
end

close all