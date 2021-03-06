% CS194-26 (cs219-26): Project 3
% David Dominguez Hooper 24828373

close all; % closes all figures

% PART 1.1: Warmup

% name of the input file
imname = char("./1.1_fire.jpg");

sharpenImage(imname);

% PART 1.2: Hybrid Images

% read images and convert to single format
imname = ["1.2_man.jpg", "1.2_harry.jpg", "1.2_earth.jpg", "1.2_mars.jpg", "1.2_dog.jpg", "1.2_wolf.jpg"];

i = 1;

while i < length(imname)
    im12 = process(imname{i}, imname{i+1});   
    i = i + 2;
end


% PART 1.3: Gaussian and Laplacian Stacks
stack_images = ["1.3_gala.jpg", "1.2_man_1.2_harry_color_hybrid.jpg", "1.2_earth_1.2_mars_color_hybrid.jpg"];

% number of pyramid levels (you may use more or fewer, as needed)
N = 5; 
for i = 1:length(stack_images)
    name = stack_images{i};
    % %% Compute and display Gaussian and Laplacian Pyramids (you need to supply this function)
    im = im2double(imread(name));
    [laplacians, gaussians] = pyramids(im, N, [1 1]);
    for j = 1:length(laplacians)
        imwrite(mat2gray(laplacians{j}), [name(1:end-4)   '_lap'  int2str(j)  '.jpg']);
        imwrite(gaussians{j}, [name(1:end-4)  '_gas'  int2str(j)   '.jpg']);
    end

end

% PART 1.4: Multiresolution Blending
b_pics = ["apple.jpg", "orange.jpg", "mask_ao.jpg"];
th_pics = ["trump.jpg", "hillary.jpg", "mask_ao.jpg"];
pb_pics = ["trey_s.jpg", "daph_s.jpg", "trey_s_mask.jpg"];


b_chan = blend(char(b_pics{1}), char(b_pics{2}), char(b_pics{3}));
imB = cat(3, b_chan{1}, b_chan{2}, b_chan{3});
imwrite(imB,'oraple.jpg');

th_chan = blend(char(th_pics{1}), char(th_pics{2}), char(th_pics{3}));
imB = cat(3, th_chan{1}, th_chan{2}, th_chan{3});
imwrite(imB,'trullary.jpg');

pb_chan = blend(char(pb_pics{1}), char(pb_pics{2}), char(pb_pics{3}));
impB = cat(3, pb_chan{1}, pb_chan{2}, pb_chan{3});
imwrite(impB,'trey_daph.jpg');

% PART 2: Toy Problem and Poisson Blending
DO_TOY = true;
DO_BLEND = true;
DO_MIXED  = true;
DO_COLOR2GRAY = false;

if DO_TOY 
    name = 'toy_problem.png';
    toyim = im2double(imread(name)); 
    % im_out should be approximately the same as toyim
    im_out = toy_reconstruct(toyim);
    imwrite(im_out,[name(1:end-4)  '_reconstructed.png']);
    disp(['Error: ' num2str(sqrt(sum(toyim(:)-im_out(:))))])
end

if DO_BLEND
    close all;
    im_background = imresize(im2double(imread('daph.jpg')), 0.5, 'bilinear');
    im_object = imresize(im2double(imread('trey_s.jpg')), 0.5, 'bilinear');
    
    % get source region mask from the user
    objmask = getMask(im_object);
    

    % align im_s and mask_s with im_background
    [im_s, mask_s] = alignSource(im_object, objmask, im_background);

    
    imwrite(im_s, 'im_s_trey.jpg');
    imwrite(mask_s, 'mask_s_trey.jpg');   
    
    % blend
    im_blend = poissonBlend(im_s, mask_s, im_background);
    imwrite(im_blend,'blended_trey.jpg');
    figure(4), hold off, imshow(im_blend)
end

if DO_MIXED
    % read images
    close all;
    im_background = imresize(im2double(imread('daph.jpg')), 0.5, 'bilinear');
    im_object = imresize(im2double(imread('trey_s.jpg')), 0.5, 'bilinear');
    
    % get source region mask from the user
    objmask = getMask(im_object);
    

    % align im_s and mask_s with im_background
    [im_s, mask_s] = alignSource(im_object, objmask, im_background);

    
    imwrite(im_s, 'im_b_s.jpg');
    imwrite(mask_s, 'mask_b_s.jpg');
    % blend
    im_blend = mixedBlend(im_s, mask_s, im_background);
    imwrite(im_blend,'blended_mixed.jpg');
    figure(3), hold off, imshow(im_blend);
end

if DO_COLOR2GRAY
    im_rgb = im2double(imread('./samples/colorBlindTest35.png'));
    im_gr = color2gray(im_rgb);
    figure(4), hold off, imagesc(im_gr), axis image, colormap gray
end

function im_out = toy_reconstruct(s)
    
    [imh, imw, ~] = size(s); 
    im2var = zeros(imh, imw); 
    HxW = imh*imw;
    im2var(1:HxW) = 1:HxW;
    
    e = 0;
    rows = (2*HxW)+1;
    
    A = sparse([], [], [], rows, HxW);
    b = zeros(rows, 1);
    
    for x=1:imw-1
        for y = 1:imh
            e = e+1; 
            
            A(e, im2var(y,x+1)) = 1; 
            A(e, im2var(y,x)) = -1;  
            b(e) = s(y,x+1)-s(y,x);
        end
    end
    
    for x=1:imw
        for y = 1:imh-1
            e = e+1;
            
            A(e, im2var(y+1,x)) = 1; 
            A(e, im2var(y,x)) = -1; 
            b(e) = s(y+1,x)-s(y,x); 
        end
    end   
    
    e = e+1; 
    
    A(e, im2var(1,1))=1; 
    b(e) = s(1,1); 
    
    v = A\b;
    im_out = mat2gray(reshape(v,[imh, imw]));
end

function im_blend = poissonBlend(im_s, mask_s, im_background)
    [imh, imw, nb] = size(im_s); 
    im2var = zeros(imh, imw); 
    HxW = imh*imw;
    im2var(1:HxW) = 1:HxW;
    
    A = sparse([], [], [], HxW, HxW);
    b = zeros(HxW, 3);
    
    e = 0;
    for x=1:imw
        for y = 1:imh
            e = e+1;
            if mask_s(y, x) == 0
                A(e, im2var(y,x)) = 1; 
                b(e, 1) = im_background(y, x, 1);
                b(e, 2) = im_background(y, x, 2);
                b(e, 3) = im_background(y, x, 3);
            else
                A(e, im2var(y,x-1)) = -1; 
                A(e, im2var(y-1,x)) = -1; 
                A(e, im2var(y+1,x)) = -1; 
                A(e, im2var(y,x+1)) = -1; 

                A(e, im2var(y,x)) = 4; 
                b(e, 1) = 4*im_s(y, x, 1) - im_s(y, x-1, 1) - im_s(y-1, x, 1) - im_s(y+1, x, 1) - im_s(y, x+1, 1);
                b(e, 2) = 4*im_s(y, x, 2) - im_s(y, x-1, 2) - im_s(y-1, x, 2) - im_s(y+1, x, 2) - im_s(y, x+1, 2);
                b(e, 3) = 4*im_s(y, x, 3) - im_s(y, x-1, 3) - im_s(y-1, x, 3) - im_s(y+1, x, 3) - im_s(y, x+1, 3);
            end 
        end
    end 
    dims = [imh, imw];
    r = reshape(A\b(:, 1), dims);
    g = reshape(A\b(:, 2), dims);
    b = reshape(A\b(:, 3), dims);
    
    im_blend = cat(3, r, g, b);
end

function im_blend = mixedBlend(im_s, mask_s, im_background)
    [imh, imw, nb] = size(im_s); 
    im2var = zeros(imh, imw); 
    HxW = imh*imw;
    im2var(1:HxW) = 1:HxW;
    
    A = sparse([], [], [], HxW, HxW);
    b = zeros(HxW, 3);
    
    e = 0;
    for x=1:imw
        for y = 1:imh
            e = e+1;
            if mask_s(y, x) == 0
                A(e, im2var(y,x)) = 1; 
                b(e, 1) = im_background(y, x, 1);
                b(e, 2) = im_background(y, x, 2);
                b(e, 3) = im_background(y, x, 3);
            else
                A(e, im2var(y,x-1)) = -1; 
                A(e, im2var(y-1,x)) = -1; 
                A(e, im2var(y+1,x)) = -1; 
                A(e, im2var(y,x+1)) = -1; 
                
                
                A(e, im2var(y,x)) = 4; 
                
                
                for k = 1:3
                    x_1 = im_s(y, x, k) - im_s(y, x-1, k);
                    t_1 = im_background(y, x, k)-im_background(y, x-1, k);
                    if abs(x_1) > abs(t_1)
                        b(e, k) = b(e, k) + x_1;
                    else
                        b(e, k) = b(e, k) + t_1;
                    end

                    x_2 = im_s(y, x, k) - im_s(y-1, x, k);
                    t_2 = im_background(y, x, k)-im_background(y-1, x, k);
                    if abs(x_2) > abs(t_2)
                        b(e, k) = b(e, k) + x_2;
                    else
                        b(e, k) = b(e, k) + t_2;
                    end

                    x_3 = im_s(y, x, k) - im_s(y+1, x, k);
                    t_3 = im_background(y, x, k)-im_background(y+1, x, k);
                    if abs(x_3) > abs(t_3)
                        b(e, k) = b(e, k) + x_3;
                    else
                        b(e, k) = b(e, k) + t_3;
                    end

                    x_4 = im_s(y, x, k) - im_s(y, x+1, k);
                    t_4 = im_background(y, x, k)-im_background(y, x+1, k);
                    if abs(x_4) > abs(t_4)
                        b(e, k) = b(e, k) + x_4;
                    else
                        b(e, k) = b(e, k) + t_4;
                    end
                end
            end 
        end
    end 
    dims = [imh, imw];
    r = reshape(A\b(:, 1), dims);
    g = reshape(A\b(:, 2), dims);
    b = reshape(A\b(:, 3), dims);
    
    im_blend = cat(3, r, g, b);
end


