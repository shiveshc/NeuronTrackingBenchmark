%%% function to convert double image to uint16, scale according to max
%%% photon count and add posson noise (similar to denoising paper on
%%% biorxiv)

function [scaled_img_fmt, scaled_img_noisy] = make_poisson_noise_vid(raw_vid, max_pht_cnt, format)

    min_raw = [];
    max_raw = [];
    for t = 1:size(raw_vid, 4)
        min_raw = [min_raw; min(min(min(raw_vid(:, :, :, t))))];
        max_raw = [max_raw; max(max(max(raw_vid(:, :, :, t))))];
    end
    
    min_all = min(min_raw);
    max_all = max(max_raw);
    
    scaled_img_fmt = zeros(size(raw_vid));
    scaled_img_noisy = zeros(size(raw_vid));
    for t = 1:size(scaled_img_noisy, 4)
        scaled_img = 0 + max_pht_cnt*(raw_vid(:, :, :, t) - 0)/(max_all);
        scaled_img_fmt(:, :, :, t) = scaled_img;
        
        if strcmp(format, 'uint8')
            scaled_img = uint8(scaled_img);
        else
            scaled_img = uint16(scaled_img);
        end
        scaled_img = imnoise(scaled_img, 'poisson');
        scaled_img_noisy(:, :, :, t) = double(scaled_img) + floor(normrnd(0,1,size(scaled_img)));
    end
    if strcmp(format, 'uint8')
        scaled_img_fmt = uint8(scaled_img_fmt);
        scaled_img_noisy = uint8(scaled_img_noisy);
    else
        scaled_img_fmt = uint16(scaled_img_fmt);
        scaled_img_noisy = uint16(scaled_img_noisy);
    end
    
end