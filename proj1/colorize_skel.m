% CS194-26 (cs219-26): Project 1, starter Matlab code

% name of the input file
imname = 'cathedral.jpg';

% read in the image
fullim = imread(imname);

% convert to double matrix (might want to do this later on to same memory)
fullim = im2double(fullim);

% compute the height of each part (just 1/3 of total)
height = floor(size(fullim,1)/3);
width = floor(size(fullim,2));
% separate color channels
B = fullim(1:height,:);
G = fullim(height+1:height*2,:);
R = fullim(height*2+1:height*3,:);

% Align the images
% Functions that might be useful to you for aligning the images include: 
% "circshift", "sum", and "imresize" (for multiscale)

% crop image by -30 to 30 pixels around border
cropAmount = 19;
Hcrop = height - cropAmount;
Wcrop = width - cropAmount;


Bcropped=B(1+cropAmount:Hcrop,1+cropAmount:Wcrop);
Gcropped=G(1+cropAmount:Hcrop,1+cropAmount:Wcrop);
Rcropped=R(1+cropAmount:Hcrop,1+cropAmount:Wcrop);

offset = 15;

[gx,gy] = align(Gcropped, Bcropped, offset, "SSD");
gNew = circshift(G, [gx, gy]);
[rx,ry] = align(Rcropped, Bcropped, offset, "SSD");
rNew = circshift(R, [rx, ry]);

RGB = cat(3, rNew, gNew, B);
figure, imshow(RGB);


[gx,gy] = align(Gcropped, Bcropped, offset, "NCC");
gNew = circshift(G, [gx, gy]);
[rx,ry] = align(Rcropped, Bcropped, offset, "NCC");
rNew = circshift(R, [rx, ry]);

RGB = cat(3, rNew, gNew, B);
figure, imshow(RGB)




%% imwrite(colorim,['result-' imname]);

function [x, y] = align(img, base, offset, option)
    baseV = base(:);
    displacement = zeros((offset*2));
    baseNorm = baseV/norm(baseV);
    
    for h = 1:(offset*2)
        for w = 1:(offset*2)
            img = circshift(img,1,2);
            if (option == "NCC")
                imgV = img(:);
                imgNorm = imgV/norm(imgV);
                displacement(h, w) = dot(baseNorm, imgNorm);
            else
                displacement(h, w) = sum(sum((base-img).^2));
            end
            
        end
        if h ~= (offset*2)
            img = circshift(img,-offset*2,2);
            img = circshift(img,1,1);
        end
    end
    img = circshift(img,[-offset*2,-offset*2]);
    
    if (option == "NCC")
        [M,I] = max(displacement(:));
    else
        [M,I] = min(displacement(:));
    end
    [x, y] = ind2sub(size(displacement), I);

end
