function [M, N, Image_Final] = TilingImages_x(a, b, f, M, N)
%% 
% Author: Weinan Liu, 
% Version: 11-30-2022
%% Initialization
xDis_ori = 80;
yDis_ori = 45;

% xCrop_ori = xDis_ori;

%% find out the ideal overlap
%  calculate x+-2, y+-20 area
mx = 30;                    % x variation, default: 20
sx = 2;                     % x step, default: 1
my = 26;                     % y variation
sy = 2;                     % y step
m1 = a(end-xDis_ori+1:end,yDis_ori+1:end);
m2 = b(1:xDis_ori,1:(end-(f-1)*yDis_ori-N));          % have to introduce an N because a is croped more
k  = abs(sum(m1(:)-m2(:))/length(m1(:)));             % zeros((mx/sx*2+1)*(my/sy*2+1),1);
m = 0;
n = 0;
for i = -mx:sx:mx
    for j = -my:sy:my
        xDis = xDis_ori+i;
        yDis = yDis_ori+j;
        m1 = a(end-xDis+1:end,yDis+1:end);
        m2 = b(1:xDis,1:end-yDis-(f-2)*yDis_ori-N);
        k1 = abs(sum(m1(:)-m2(:))/length(m1(:)));
        if k1<k
            k=k1;
            m = i;           % m,n are the ideal sub number
            n = j;
        end
    end
end

xDis = xDis_ori+m;
yDis = yDis_ori+n;
yCrop = yDis+N;
%% generate a transition matrix
% zy = -(1/(length(a(1,:))-yCrop))*(1:length(a(1,:))-yCrop)+1;
zx = -(1/xDis)*(1:xDis)+1;
zxr= -(1/xDis)*(0:xDis-1)+1;
% maty = meshgrid(zy,1:xDis);
% [~,matx] = meshgrid(1:length(a(1,:))-yCrop,zx);
[~,matx] = meshgrid(1:length(b(1,:))-(f-2)*yDis_ori-yCrop,zx);
[~,matxr] = meshgrid(1:length(b(1,:))-(f-2)*yDis_ori-yCrop,zxr);
% mat_weight = matx.*maty;
% mat_weightr = rot90(mat_weight,2);
matxr = flipud(matxr);

%% Image matrix assembling
% aa = a(end-xDis+1:end,yDis+1:end);
a_medium = double(a(end-xDis+1:end,yDis+1:end)).*matx;               % .*matx
ImageMedium = a_medium + double(b(1:xDis,1:(end-(f-2)*yDis_ori-yCrop))).*matxr;        % 
ImageTop    = a(1:end-xDis,yDis+1:end);
ImageBottom = b(xDis+1:end,1:(end-(f-2)*yDis_ori-yCrop));
Image_Final = [ImageTop; ImageMedium; ImageBottom];

% a(end-xDis+1:end,yDis+1:end) = 
M = M + m;
N = N + n;
end