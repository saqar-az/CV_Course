clc
clear

img = imread('baboon.png');
gray_img = rgb2gray(img);

noisy_img = imnoise(gray_img,'gaussian', 0, 5/255);

kernel = fspecial('average', [3 3]);
tic;
mean_img = imfilter(noisy_img, kernel, 'replicate');
mean_time = toc;

tic;
nlm_img = imnlmfilt(noisy_img); 
nlm_time = toc;

mse_mean = immse(mean_img, gray_img);
psnr_mean = psnr(mean_img, gray_img);

mse_nlm = immse(nlm_img, gray_img);
psnr_nlm = psnr(nlm_img, gray_img);

figure;
subplot(2,2,1); 
imshow(gray_img); 
title('gray pic')
subplot(2,2,2); 
imshow(noisy_img); 
title('noisy pic')
subplot(2,2,3); 
imshow(mean_img); 
title('mean');
subplot(2,2,4); 
imshow(nlm_img); 
title('NLM');

fprintf('mean');
fprintf('MSE = %.4f , PSNR = %.4f dB , Time = %.4f sec\n', mse_mean, psnr_mean, mean_time);
fprintf('NLM');
fprintf('MSE = %.4f , PSNR = %.4f dB , Time = %.4f sec\n', mse_nlm, psnr_nlm, nlm_time);
