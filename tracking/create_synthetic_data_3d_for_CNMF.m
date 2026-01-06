%%%% function to create synthetic data for cell segmentation

function create_synthetic_data_3d_for_CNMF(speckle_noise_var, background_intensity, num)
rng shuffle
rng shuffle

%%% load atlas
% load('D:\Shivesh\OptimalTransport\annotation\data_neuron_relationship.mat')
load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/data_neuron_relationship.mat')


%%% select neurons
keep_neurons_from_atlas = randperm(size(X_rot,1),130);
X = X_rot(keep_neurons_from_atlas,:);
Y = Y_rot(keep_neurons_from_atlas,:);
Z = Z_rot(keep_neurons_from_atlas,:);

%%% assign each cell a base signal to background ratio
possible_SnB_ratios = [0.01:0.01:5];
cell_SnB = possible_SnB_ratios(:,randi(size(possible_SnB_ratios,2),1,size(X,1)));


%%% other image parameters
% speckle_noise_var = 0:0.001:0.01;
% speckle_noise_var = 0.02;
% background_intensity = 0.5 + 0.005*randn();
% background_intensity = 0.2;


%%% scale cell coordinates to a 512-by-512-by-30 image
X_sc = 20 + (512-40)*(X - min(X))/(max(X) - min(X));        % rescale x to 20 to 492 pixels
Z_sc = 512*(Z - min(Z))/(max(X) - min(X));                  % rescale z with 2 times x scaling
Z_sc = Z_sc - mean(Z_sc) + 256;                             % center z coords to 256
Y_sc = 1 + (29-1)*(Y - min(Y))/(max(Y) - min(Y));           % rescale y to 1 to 29 pixels


% create img
img = zeros(512,512,30);
[X,Y,Z] = meshgrid(1:size(img,1),1:size(img,2),1:size(img,3));
coor = [X(:),Y(:),Z(:)];
temp = zeros(size(img));

% create cells (spatial components)
cell_struct = struct();
cell_cnt = 1;
stack_cnt = 1;
img_cnt = 1;
for k = 1:size(X_sc,1)
    % poition of cell
    mu = [X_sc(k),Z_sc(k),Y_sc(k)];

    % 3D covariance matrix
    theta1 = 2*pi*rand(1,1);
    U = [cos(theta1),sin(theta1),0;-sin(theta1),cos(theta1),0;0,0,1];
    r_min = 11;
    r_max = 16;
    sigma = [r_min+(r_max - r_min)*rand(),0,0;0,r_min+(r_max - r_min)*rand(),0;0,0,1+3*rand()];
    cov_mat = U'*sigma*U;

    % intensity
    base_SnB = cell_SnB(k);
    
    % store
    cell_struct(cell_cnt).mu = mu;
    cell_struct(cell_cnt).cov_mat = cov_mat;
    cell_struct(cell_cnt).SnB = base_SnB;
    cell_struct(cell_cnt).stack = stack_cnt;
    cell_struct(cell_cnt).stack_size = [size(img,1),size(img,2),size(img,3)];
    cell_cnt = cell_cnt + 1;
end
            
            
%%% create image video with real calcium imaging data
num_tp_in_video = 100;
ca_signal = zeros(size(cell_struct,2),num_tp_in_video);

% prepare ca imaging data
ca_signal = assign_activity_using_experimental_data(cell_struct, Neuron_head, keep_neurons_from_atlas, num_tp_in_video, randi(5), 0);
for k = 1:size(cell_struct,2)
    cell_struct(k).gt_signal = ca_signal(k,:);
end
            
% signal genration for each neuron is defined as follows. Let Fo be image
% background intensity. Then, each cell's base background intensity is
% defined as Fo + Fo*SnB_i. Then on top of that a normalized calcium imaging
% signal S_i (that stores deltaF/F) is added. Thus, each cell's signal becomes
% F_i = (Fo + Fo*SnB_i)(1+S_i). You can veryify that -  
% mean(F_i) = Fo + Fo*SnB_i because mean(S_i) = 0, thus
% (F_i - mean(F_i))/mean(F_i) = S_i. To create calcium signal F_i, Fo is
% added outside the loop (to prevent duplication).

noisy_vid = zeros([size(img),num_tp_in_video]);
gt_vid = zeros([size(img),num_tp_in_video]);
for t = 1:num_tp_in_video
    tic
    curr_frame = zeros*ones(size(img));
    for i = 1:size(cell_struct,2)
        curr_mu = cell_struct(i).mu;
        curr_cov_mat = cell_struct(i).cov_mat;
        y = mvnpdf(coor,curr_mu,curr_cov_mat);
        y_mu = mvnpdf(curr_mu,curr_mu,curr_cov_mat);
        y_scaled = y/y_mu*(background_intensity*cell_struct(i).SnB*(1+ca_signal(i,t)) + background_intensity*ca_signal(i,t));

        curr_frame = curr_frame + reshape(y_scaled,size(img,1),size(img,2),size(img,3));

    end
    toc
    
    
%     tic
%     all_mu = zeros(size(cell_struct,2),3);
%     all_sigma = zeros(3,3,size(cell_struct,2));
%     mix_p = zeros(size(cell_struct,2),1);
%     for i = 1:size(cell_struct,2)
%         all_mu(i,:) = cell_struct(i).mu;
%         all_sigma(:,:,i) = cell_struct(i).cov_mat;
%         y_mu = mvnpdf(all_mu(i,:), all_mu(i,:), all_sigma(:,:,i));
%         mix_p(i,:) = 1/y_mu*(background_intensity*cell_struct(i).SnB*(1+ca_signal(i,t)) + background_intensity*ca_signal(i,t));
%     end
%     gm = gmdistribution(all_mu,all_sigma,mix_p');
%     curr_frame = pdf(gm,coor);
%     curr_frame = reshape(curr_frame,size(img,1),size(img,2),size(img,3));
%     toc
    
    
    curr_frame_with_background = curr_frame + background_intensity*ones(size(img));
    curr_frame_with_background_norm = mat2gray(curr_frame_with_background);
    curr_frame_with_noise = imnoise(curr_frame_with_background,'speckle',speckle_noise_var);
    curr_frame_with_noise_norm = mat2gray(curr_frame_with_noise);
    noisy_vid(:,:,:,t) = curr_frame_with_noise;
    gt_vid(:,:,:,t) = curr_frame_with_background;
end

% save_name = ['D:\Shivesh\OptimalTransport\tracking\data_for_CNMF\vid_',num2str(speckle_noise_var),'_',num2str(background_intensity),'_',num2str(num)];
save_name = ['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/data_for_CNMF/vid_',num2str(speckle_noise_var),'_',num2str(background_intensity),'_',num2str(num)];
if exist(save_name,'dir')
else
    mkdir(save_name)
end 

save_whole_brain_video(noisy_vid,[save_name,'/noisy_vid'])
save_whole_brain_video(gt_vid,[save_name,'/gt_vid'])

save([save_name,'/cell_struct.mat'],'cell_struct')


