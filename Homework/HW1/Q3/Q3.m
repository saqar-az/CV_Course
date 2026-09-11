clc
clear

img = imread('cameraman.png'); 
img = im2gray(img); 

sobel = edge(img,'sobel');
prewitt = edge(img,'prewitt');
roberts = edge(img,'roberts');
canny = edge(img,'canny');        

figure;
subplot(2,2,1),
imshow(sobel),
title('Sobel');
subplot(2,2,2),
imshow(prewitt),
title('Prewitt');
subplot(2,2,3),
imshow(roberts),
title('Roberts');
subplot(2,2,4),
imshow(canny),
title('Canny');


