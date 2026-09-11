clc
clear

img = imread('a.jpg');   
gray_img = rgb2gray(img);

[centers, radii] = imfindcircles(gray_img,[20,80],'Sensitivity',0.9);

figure;
imshow(gray_img);
title('Detected Circles');
hold on;
viscircles(centers, radii,'Color','r');

bin = imbinarize(gray_img);

for i = 1:length(radii)
    area = pi * (radii(i)^2);
    fprintf('circle %d : radius = %.2f, area = %.2f\n', i, radii(i), area);

    [x, y] = ndgrid(1:size(gray_img,1), 1:size(gray_img,2));
    mask = (x - centers(i,2)).^2 + (y - centers(i,1)).^2 <= radii(i)^2;

    region = mask & bin;
    region_filled = imfill(region,'holes');

    if ~isequal(region, region_filled)
        fprintf('circle %d has a hole\n', i);
    else
        fprintf('circle %d does not have a hole\n', i);
    end
end
