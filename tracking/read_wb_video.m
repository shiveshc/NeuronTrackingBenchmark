function full_img = read_wb_video(inp_dir, tp_to_read)

%%% read dummy img
img_path = [inp_dir,'\t_',num2str(tp_to_read(1,1))];
file_list = dir(img_path);
num_zplanes = size(file_list,1) - 2;
temp_img = imread([img_path,'\z_1.tif']);
img_width = size(temp_img,2);
img_height = size(temp_img,1);


%%% read all images
full_img = zeros(img_height,img_width,num_zplanes,tp_to_read(1,2) - tp_to_read(1,1) + 1, 'uint16');
for n = 1:size(full_img,4)
    img_path = [inp_dir,'\t_',num2str(tp_to_read(1,1) + n - 1)];
    for z = 1:num_zplanes
        full_img(:,:,z,n) = imread([img_path,'\z_',num2str(z),'.tif']);
    end
end