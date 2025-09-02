function [np_c,centroid] = PRAM_NPCountONLY_T_F_C_MSER(img_dir)

% The function will return the estimated count of NPs in a PRAM image under
% 50x
% Variables Deinition:
% np_c: count of NP
% OI: Overlap image
% imgP_dir: PRAM image directory
% imgB_dir: Corresponding background image directory
% mask: binary mask 2D array, if not specified, the default mask will be a
% single line mask in the center along the y axis (except for the center point)
%
% Date: 02-17-22
% Author: Weinan Liu

close all
%% Image processing parameters
Contrast_f = 0.005;           % Contrast factor, default 0.005
Threshold_rec = 20E-2;        % Threshold of binaryzation, default 0.05, smaller would count more
Threshold_flt = 15;           % Threshold of filter: size of noisy spots, default 9
R_NP = 20;                    % Radius of marker of nanoparticles, default 3
noise_d = 6;                  % Neiborhood dimension of noises

%% Input image
dir = imread([img_dir '.png']);
I_ori = dir(:,:,1);

%% Removing background
se = strel('disk',15);                  
tophatFiltered = imtophat(imcomplement(I_ori),se);
I_bgr = imcomplement(tophatFiltered);   % BG removed image

%% Filtering and adding mask
ori_image = I_bgr;
[m1, n1] = size(ori_image);
if ~exist('mask', 'var')
    mask = ones(m1, n1);
    if rem(n1, 2) == 0
        mask(:, n1/2+1) = 0;
    else
        mask(:,(n1-1)/2+1) = 0;
    end
end

%% Remove strips 
fft_image = fftshift(fft2(ori_image));
ori_image = abs((ifft2(mask.*fft_image)));

I = mat2gray(255-ori_image);
I = wiener2(I, [noise_d noise_d]);
se2 = strel('disk',1);
I = imdilate(imcomplement(I), se2);
I = imcomplement(I);

%% Contrast enhancement

I_bgr_ce = adapthisteq(I, 'ClipLimit', Contrast_f);    % ,'Distribution','uniform'


%% MSER

if ~exist('thres', 'var')
    thres = 0.1;
end
if ~exist('orientation', 'var')
    orientation = 0;
end
if ~exist('area_max', 'var')
    area_max = 300;
end
if ~exist('area_min', 'var')
    area_min = 50;
end
if ~exist('eccentricity', 'var')
    eccentricity = 0.0;
end


%% Feature Detection via MSER
[detectPoints, mserCC] = detectMSERFeatures(I, 'ThresholdDelta', thres, 'MaxAreaVariation', 0.25);
% Region properties defined
stats = regionprops('table',mserCC, I, 'Orientation', 'Area', 'Eccentricity', 'Centroid', 'MeanIntensity',...
    'Circularity', 'EulerNumber', 'EquivDiameter');
orientationIdx = (stats.Orientation < -orientation)|(stats.Orientation > orientation);
circularityIdx = (stats.Circularity > 0.75);                                % default 0.9, significant!!
areaIdx = (stats.Area < area_max)&(stats.Area > area_min);
eccentricityIdx = (stats.Eccentricity > eccentricity);
intensityIdx = (stats.MeanIntensity < (1-Threshold_rec));                   % mean(ori_image(:))  significant!
EulerNumberIdx = (stats.EulerNumber > 0);                                   % significant!!
EquivDiameterIdx = ((stats.EquivDiameter < 20) & (stats.EquivDiameter > 0));
detectedRegions = detectPoints(orientationIdx&eccentricityIdx&areaIdx&intensityIdx&circularityIdx&EulerNumberIdx&EquivDiameterIdx);  % 

if detectedRegions.Count < 2
    np_c = 0;
    figure;
    imshow(I, [])
    hold on
    text = int2str(np_c);
    title(['Count: ' text],'FontSize',16);

else
% Remove overlapped region
detectedSub = cell2mat(detectedRegions.PixelList(:));
detectedIdx = sub2ind([m1 n1], detectedSub(:, 2), detectedSub(:, 1));
detectedIdx_uniq = unique(detectedIdx);

% Create binary mask
bw_MSER = zeros(m1, n1);
bw_MSER(detectedIdx_uniq) = 1;
% calculate contrast
image_contrast = max(I_bgr_ce(:)) - min(I_bgr_ce(:));

%% Final result presentation
OI = imoverlay(I, bw_MSER, 'r');
np_c = bwconncomp(bw_MSER).NumObjects;


%% modified in v2.1 - find out the centroid, radii of circles around it, and the coordinate of each particle
BW_log = logical(bw_MSER);
stats = regionprops('table',BW_log,'Centroid',...
            'MajorAxisLength','MinorAxisLength');
centers = stats.Centroid;
centroid = cat(1,stats.Centroid);
diameters = R_NP*ones(length(centroid(:,1)),1);             % mean([stats.MajorAxisLength stats.MinorAxisLength],2);
radii = diameters/2;

end

%% debug code - can delete
% figure; 
% viscircles(centers,radii,'color','r','linewidth',1);
% set(gca,'xtick',[],'ytick',[]);
% set(gca, 'YDir','reverse');
% axis([0 n1 0 m1])
% daspect([1 1 1]);
% box on
