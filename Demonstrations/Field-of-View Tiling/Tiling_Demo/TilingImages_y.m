function [M, N, Image_Final] = TilingImages_y(a, b, f, M, N, diffx)
%% 
% Author: Weinan Liu, 
% Version: 11-30-2022
%% Initialization
xDis_ori = 10;
yDis_ori =5;

%% find out the ideal overlap
%  calculate x+-2, y+-20 area
my = 5;                     % x variation, default: 20
sy = 1;                     % x step, default: 1
mx = 10;                    % y variation
sx = 1;                     % y step
m1 = a(xDis_ori+1:end,1:yDis_ori);
m2 = b(1:length(xDis_ori+1:end),end-yDis_ori+1:end);          % have to introduce an N because a is croped more

k  = abs(sum(m1(:)-m2(:))/length(m1(:)));             % zeros((mx/sx*2+1)*(my/sy*2+1),1);
m = 0;
n = 0;
for i = -mx:sx:mx
    for j = -my:sy:my
        xDis = xDis_ori+i;
        yDis = yDis_ori+j;
        m1 = a(xDis+1:end,1:yDis);
        m2 = b(1:length(xDis+1:end),end-yDis+1:end);
        
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
if diffx >= 0
    xCrop = xDis+M;
else
    xCrop = xDis+M+diffx;
end
%% generate a transition matrix
zy = -(1/yDis)*(1:yDis)+1;
zyr = -(1/yDis)*(0:yDis-1)+1;
[maty,~] = meshgrid(zy,1:length(a(xDis+1:end,1)));              % 1:length(b(:,1))-(f-2)*xDis_ori-xCrop
[matyr,~] = meshgrid(zyr,1:length(a(xDis+1:end,1)));   
matyr = fliplr(matyr);

%% Image matrix assembling
% aa = a(end-xDis+1:end,yDis+1:end);
a_medium = double(a(xDis+1:end,1:yDis)).*matyr;               % .*matx
% mm = double(b(1:xDis,1:end-yDis-(f-2)*yDis_ori)-N);
ImageMedium = a_medium + double(b(1:length(xDis+1:end),end-yDis+1:end)).*maty;        % 
ImageFront    = a(xDis+1:end,yDis+1:end);
ImageBack = b(1:length(xDis+1:end),1:end - yDis);
Image_Final = [ImageBack ImageMedium ImageFront];

% a(end-xDis+1:end,yDis+1:end) = 
M = M + m;
N = N + n;
end