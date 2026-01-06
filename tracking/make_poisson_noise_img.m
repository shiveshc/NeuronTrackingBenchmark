%%% function to convert double image to uint16, scale according to max
%%% photon count and add posson noise (similar to denoising paper on
%%% biorxiv)

function [scaled_img_fmt, scaled_img_noisy] = make_poisson_noise_img(raw_img, max_pht_cnt, format)

    min_raw = min(min(min(raw_img)));
    max_raw = max(max(max(raw_img)));
    
    scaled_img = 0 + max_pht_cnt*(raw_img - 0)/(max_raw);
    if strcmp(format, 'uint8')
        scaled_img_fmt = uint8(scaled_img);
    else
        scaled_img_fmt = uint16(scaled_img);
    end
    
    scaled_img_noisy = imnoise(scaled_img_fmt, 'poisson');
    scaled_img_noisy = double(scaled_img_noisy) + floor(normrnd(0,1,size(scaled_img_noisy)));
    if strcmp(format, 'uint8')
        scaled_img_noisy = uint8(scaled_img_noisy);
    else
        scaled_img_noisy = uint16(scaled_img_noisy);
    end
    
end