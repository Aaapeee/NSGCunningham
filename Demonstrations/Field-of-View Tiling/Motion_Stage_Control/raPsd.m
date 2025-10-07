function [IntPf] = raPsd(img,~)
% /
% Copyright <2022> University of Illinois Board of Trustees. All Rights Reserved.
% This file is part of <Photonic Resonator Absorption Microscopy>, which is 
% released under specific terms.  See file License.txt file or go to <URL> for 
% full license details.
% 
% Computes and plots radially averaged power spectral density (power
% spectrum) of image IMG with spatial resolution RES.
%
% Weinan Liu, 2022
% /

%% Process image size information
img = img(:, :, 1);
[N, M] = size(img);

%% Compute power spectrum
imgf = fftshift(fft2(img));
imgfp = (abs(imgf)/(N*M)).^2;                                               % Normalize

%% Adjust PSD size
dimMax = max(N,M);
dimMin = min(N,M);
                                                                            % Only consider one half of spectrum (due to symmetry)
if N > M                                                                    % More rows than columns
    imgfp = imgfp(floor(dimMax/2)-floor(dimMin/2)+1:floor(dimMax/2)+floor(dimMin/2), :);                      % Pad columns to match dimensions
elseif N < M                                                                % More columns than rows
    imgfp = imgfp(:, floor(dimMax/2)-floor(dimMin/2)+1:floor(dimMax/2)+floor(dimMin/2));
end

%% Compute radially average power spectrum
[xx,yy]=meshgrid(-dimMin/2:dimMin/2-1, -dimMin/2:dimMin/2-1);
ri=round(abs(xx+1i*yy))+1;
Pf=accumarray(ri(:),imgfp(:),[],@mean);

%% Integral over high frequency regime
IntPf = sum(Pf(31:150));                                                    % (30:end)
