function [np_c,centroid] = DiffCountONLY_R_O_MSERb(img_dir, Threshold_rec)
%%
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
% Date: 08-30-22
% Author: Weinan Liu

% close all
%% Image processing parameters
Contrast_f = 0.005;           % Contrast factor, default 0.005
Threshold_flt = 15;           % Threshold of filter: size of noisy spots, default 9
R_NP = 20;                    % Radius of marker of nanoparticles, default 3
noise_d = 12;                 % Neiborhood dimension of noises

%% Input image
dir = imread([img_dir '.png']);
I_ori = dir(:,:,1);


% Pre-processing - noise filtering
I = mat2gray(255 - I_ori);
I = wiener2(I, [noise_d noise_d]);


%% Opening
[m1, n1] = size(I);
se2 = strel('disk',3);
I = imopen(imcomplement(I), se2);
I = imcomplement(I);

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
    area_min = 100;
end
if ~exist('eccentricity', 'var')
    eccentricity = 0.0;
end


%% Feature Detection via MSER
[detectPoints, mserCC] = detectMSERFeatures(I, 'ThresholdDelta', thres, 'MaxAreaVariation', 0.4);
% Region properties defined
stats = regionprops('table',mserCC, I, 'Orientation', 'Area', 'Eccentricity', 'Centroid', 'MeanIntensity',...
    'Circularity', 'EulerNumber', 'EquivDiameter');
orientationIdx = (stats.Orientation < -orientation)|(stats.Orientation > orientation);
circularityIdx = (stats.Circularity > 0.7);                                                 % default 0.9, significant!!
areaIdx = (stats.Area < area_max)&(stats.Area > area_min);
eccentricityIdx = (stats.Eccentricity > eccentricity);
intensityIdx = (stats.MeanIntensity < (mean(I(:))-Threshold_rec*mean(I(:))-0.00));          %  mean(ori_image(:))  significant!
EulerNumberIdx = (stats.EulerNumber > 0);                                                   % significant!!
EquivDiameterIdx = ((stats.EquivDiameter < 20) & (stats.EquivDiameter > 0));
detectedRegions = detectPoints(orientationIdx&eccentricityIdx&areaIdx&intensityIdx&circularityIdx&EulerNumberIdx&EquivDiameterIdx);  % 

if detectedRegions.Count < 2
    np_c = 0;
    centroid = 0;
else
% Remove overlapped region
detectedSub = cell2mat(detectedRegions.PixelList(:));
detectedIdx = sub2ind([m1 n1], detectedSub(:, 2), detectedSub(:, 1));
detectedIdx_uniq = unique(detectedIdx);

% Create binary mask
bw_MSER = zeros(m1, n1);
bw_MSER(detectedIdx_uniq) = 1;

%% Final result presentation
OI = imoverlay(I, bw_MSER, 'r');
np_c = bwconncomp(bw_MSER).NumObjects;


%% modified in v2.1 - find out the centroid, radii of circles around it, and the coordinate of each particle
BW_log = logical(bw_MSER);
stats = regionprops('table',BW_log,'Centroid',...
            'MajorAxisLength','MinorAxisLength');
centers = stats.Centroid;
centroid = cat(1,stats.Centroid);
diameters = R_NP*ones(length(centroid(:,1)),1); % mean([stats.MajorAxisLength stats.MinorAxisLength],2);
radii = diameters/2;
end
%% debug code - can delete 
% figure;
% % imshow(i_OT, []);
% imshow(255-I, []);
% daspect([1 1 1]);
% 
% 
% figure; 
% viscircles(centers,radii,'color','r','linewidth',1);
% set(gca,'xtick',[],'ytick',[]);
% set(gca, 'YDir','reverse');
% axis([0 n1 0 m1])
% daspect([1 1 1]);
% box on
