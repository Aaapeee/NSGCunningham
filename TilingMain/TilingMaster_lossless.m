function  Image_Tiled = TilingMaster_lossless()
%% Aim for tiling images generated from APRAM
% Author: Weinan Liu
% Version: 11-30-2023

% close all
%% Initialization
n_i = 3;                                    % images along one row

%% x Tiling
for i = 1:n_i
    m = 0;
    n = 0;
    a = imread([int2str(1+n_i*(i-1)) '_bgr.png']);
    a = a(:,:,1);

    for j = 2:1:n_i
        b = imread([int2str(j+n_i*(i-1)) '_bgr.png']);
        b = b(:,:,1);
        [m, n, a] = TilingImages_x(a, b, j, m, n);      % i: number of images in processing
    end
    Image_Tiled = a;
    filename = strcat('C:\Users\liuwe\PhD study\Projects\AutoPRAM\Images\LargeFOV\LOSSLESS\10122023_3by3 10min\',num2str(i),'_xtile.mat');
    save(filename,'a');
    figure;
    imshow(Image_Tiled,[],'border','tight');
    saveas(gcf,strcat('C:\Users\liuwe\PhD study\Projects\AutoPRAM\Images\LargeFOV\LOSSLESS\10122023_3by3 10min\',num2str(i),'_xtile.png'),'png');
end

%% y Tiling - Watch out the TilingImages_y function - yDis_ori value
close all
m = 0;
n = 0;
% a = imread(['D:\PhD study\Projects\AutoPRAM\LargeFOV\Tiled\' int2str(1) '_xtile.tiff']);
fa = matfile(strcat('C:\Users\liuwe\PhD study\Projects\AutoPRAM\Images\LargeFOV\LOSSLESS\10122023_3by3 10min\',num2str(1),'_xtile.mat'));
a = fa.a;
% a = a(:,:,1);

for j = 2:1:n_i
        fa = matfile(['C:\Users\liuwe\PhD study\Projects\AutoPRAM\Images\LargeFOV\LOSSLESS\10122023_3by3 10min\' int2str(j) '_xtile.mat']);
        b = fa.a;
        diffx = length(a(:,1))-length(b(:,1));
        if diffx >= 0
            a = a(diffx+1:end,:);
        else
            b = b(1:end+diffx,:);
        end
%         a = a(diffx+1:end,:);
        [m, n, a] = TilingImages_y(a, b, j, m, n, diffx);      % i: number of images in processing
end
Image_Tiled = a;
filename = strcat('C:\Users\liuwe\PhD study\Projects\AutoPRAM\Images\LargeFOV\LOSSLESS\10122023_3by3 10min\',num2str(i),'_BgrTiled.mat');
save(filename,'a');
figure;
imshow(Image_Tiled,[],'border','tight');
saveas(gcf,strcat(num2str(1),'_BgrTiled.png'),'png');

