function save_whole_brain_video(full_img, save_name)

% addpath('D:\Shivesh\Denoising')

if exist(save_name,'dir')
else
    mkdir(save_name)
end
    
for t = 1:size(full_img,4)
    curr_img = full_img(:,:,:,t);
    curr_tp_dir_name = [save_name,'/t_',num2str(t)];
    if exist(curr_tp_dir_name,'dir')
        rmdir(curr_tp_dir_name)
    end
    mkdir(curr_tp_dir_name)
    for z = 1:size(curr_img,3)
        indexed_img_to_tiff(curr_img(:,:,z),[],[curr_tp_dir_name,'/z_',num2str(z),'.tif'])
    end
end
end
        
        