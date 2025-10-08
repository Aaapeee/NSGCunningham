function  Image_Tiled = TilingMaster()
%% Aim for tiling images generated from APRAM
% Author: Weinan Liu
% Version: 11-30-2022

close all
%% Initialization
n_i = 5;                                    % images along one row

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
    figure;
    imshow(Image_Tiled,[],'border','tight');
    caxis([110 255]);
    saveas(gcf,strcat('D:\PhD Study\Projects\AutoPRAM\LargeFOV\Tiling_manu\Tiling_Demo\',num2str(i),'_xtile.png'),'png');
%     exportgraphics(gcf,strcat('D:\PhDstudy\Projects\AutoPRAM\LargeFOV\Tiling_manu\',num2str(i),'_xtile.png'),'Resolution',300)
end

%% y Tiling
close all
m = 0;
n = 0;
a = imread(['D:\PhD Study\Projects\AutoPRAM\LargeFOV\Tiling_manu\Tiling_Demo\' int2str(1) '_xtile.png']);
a = a(:,:,1);

for j = 2:1:n_i
        b = imread(['D:\PhD Study\Projects\AutoPRAM\LargeFOV\Tiling_manu\Tiling_Demo\' int2str(j) '_xtile.png']);
        b = b(:,:,1);
        diffx = length(a(:,1))-length(b(:,1));
        if diffx >= 0
            a = a(diffx+1:end,:);
        else
            b = b(1:end+diffx,:);
        end

        [m, n, a] = TilingImages_y(a, b, j, m, n, diffx);      % i: number of images in processing
end
Image_Tiled = a;
figure;
imshow(Image_Tiled,[],'border','tight');
exportgraphics(gcf,strcat(num2str(1012),'bgr_tile.png'),'Resolution',300);
