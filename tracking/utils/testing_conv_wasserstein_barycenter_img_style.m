%%% function to compute wasserstein baryenters based on "Iterative bregman
%%% projections for regularized transport problems". Note that in this case
%%% we will do an image style like in Peyre code

addpath('D:\Shivesh\OptimalTransport\tracking\2015-SIGGRAPH-convolutional-ot-master\code\convolutional_wasserstein')
addpath('D:\Shivesh\OptimalTransport\tracking\2015-SIGGRAPH-convolutional-ot-master\code\toolbox')

% precision = [1];
% recall = [0.7087,0.6359,0.5146,0.3932,0.2718];
precision = 1;
recall = 1;

results = [];
for p = 1:size(precision,2)
    for r = 1:size(recall,2)
        for v = 1:1
            load('D:\Shivesh\OptimalTransport\annotation\data_neuron_relationship.mat')

            %%% select random 130 cells to be tracked in current video
            curr_to_be_tracked = randperm(size(X_rot,1),size(X_rot,1));
            X_rot = X_rot(curr_to_be_tracked,:);
            Y_rot = Y_rot(curr_to_be_tracked,:);
            Z_rot = Z_rot(curr_to_be_tracked,:);
            total_cells = size(X_rot,1);
            base_track_gt = cat(2,[1:1:total_cells]',X_rot,Y_rot,Z_rot,ones(size(X_rot,1),1));
            id_cnt = max(base_track_gt(:,1));

            num_frames = 100;
            frame_track_gt = {}; % records gt neuron identities for each frame
            for i = 1:num_frames
%                 recall_param = normrnd(recall(1,r),0.056);
%                 precision_param = normrnd(precision(1,p),0.04);
                recall_param = recall(1,r);
                precision_param = precision(1,p);
                curr_track = base_track_gt;

                % add FN
                FN = max(0,round((1-recall_param)*total_cells));
                remove = randperm(total_cells,FN);
                curr_track(remove,:) = [];
                TP = size(curr_track,1);

                % add FP
                FP = max(0,round((1-precision_param)*TP/precision_param));
                x_FP = min(X_rot) + (max(X_rot) - min(X_rot))*rand(FP,1);
                y_FP = min(Y_rot) + (max(Y_rot) - min(Y_rot))*rand(FP,1);
                z_FP = min(Z_rot) + (max(Z_rot) - min(Z_rot))*rand(FP,1);
                curr_track = [curr_track;cat(2,[id_cnt+1:1:id_cnt+FP]',x_FP,y_FP,z_FP,zeros(FP,1))];
                id_cnt = max(curr_track(:,1));

                % add tiny position noise
            %     noise_level = [0.01,0.006,0.0056]; % position noise level 1
                noise_level = [0.01/2,0.006/2,0.0056/2];
                curr_track(:,2) = curr_track(:,2) + noise_level(1,1)*randn(size(curr_track,1),1);
                curr_track(:,3) = curr_track(:,3) + noise_level(1,2)*randn(size(curr_track,1),1);
                curr_track(:,4) = curr_track(:,4) + noise_level(1,3)*randn(size(curr_track,1),1);

                % store curr track
                frame_track_gt{1,i} = curr_track;
            end
            
            %%% define discretization to make images from frame_track_gt
            all_x = [];
            all_y = [];
            all_z = [];
            for i = 1:size(frame_track_gt,2)
                curr_frame_gt = frame_track_gt{1,i};
                all_x = [all_x;curr_frame_gt(:,2)];
                all_y = [all_y;curr_frame_gt(:,3)];
                all_z = [all_z;curr_frame_gt(:,4)];
            end
            min_all_x = min(all_x);
            min_all_y = min(all_y);
            min_all_z = min(all_z);
            max_all_x = max(all_x);
            max_all_y = max(all_y);
            max_all_z = max(all_z);
            
            sample_frame_track_gt = frame_track_gt{1,1};
            sample_pos_x = sample_frame_track_gt(:,2);
            sample_pos_y = sample_frame_track_gt(:,3);
            sample_pos_z = sample_frame_track_gt(:,4);
            sample_pos = sample_frame_track_gt(:,2:4);
            sample_dist_x = sqrt(repmat(diag(sample_pos_x*sample_pos_x'),1,size(sample_pos_x,1)) + repmat(diag(sample_pos_x*sample_pos_x')',size(sample_pos_x,1),1) - 2*sample_pos_x*sample_pos_x');
            sample_dist_y = sqrt(repmat(diag(sample_pos_y*sample_pos_y'),1,size(sample_pos_y,1)) + repmat(diag(sample_pos_y*sample_pos_y')',size(sample_pos_y,1),1) - 2*sample_pos_y*sample_pos_y');
            sample_dist_z = sqrt(repmat(diag(sample_pos_z*sample_pos_z'),1,size(sample_pos_z,1)) + repmat(diag(sample_pos_z*sample_pos_z')',size(sample_pos_z,1),1) - 2*sample_pos_z*sample_pos_z');
            sample_dist = sqrt(repmat(diag(sample_pos*sample_pos'),1,size(sample_pos,1)) + repmat(diag(sample_pos*sample_pos')',size(sample_pos,1),1) - 2*sample_pos*sample_pos');
            sample_dist_x = 1e7*eye(size(sample_dist_x,1)) + sample_dist_x;
            sample_dist_y = 1e7*eye(size(sample_dist_y,1)) + sample_dist_y;
            sample_dist_z = 1e7*eye(size(sample_dist_z,1)) + sample_dist_z;
            sample_dist = 1e7*eye(size(sample_dist,1)) + sample_dist;
            
            temp = cat(3,sample_dist_x,sample_dist_y,sample_dist_z); % for each cell pair find which dimension is maximally separated 
            [max_dist,max_ind] = max(temp,[],3);
            min_dist_x = min(max_dist(find(max_ind == 1))); % for each dimension find minimum distance across cells pairs. This will be used to define discretization rate
            min_dist_y = min(max_dist(find(max_ind == 2)));
            min_dist_z = min(max_dist(find(max_ind == 3)));
%             min_dist_x = min(min(sample_dist_x));
%             min_dist_y = min(min(sample_dist_y));
%             min_dist_z = min(min(sample_dist_z));
            min_dist = min(min(sample_dist));
            
%             discre_1 = ceil(5/min_dist_z*(max_all_z - min_all_z) + 2);
%             discre_2 = ceil(5/min_dist_x*(max_all_x - min_all_x) + 2);
%             discre_3 = ceil(5/min_dist_y*(max_all_y - min_all_y) + 2);
            
            
            discre_1 = 60;
            discre_2 = 100;
            discre_3 = 60;
            
            p = [];
            for i = 1:1
                curr_frame_gt = frame_track_gt{1,i};
                x = (curr_frame_gt(:,2) - min_all_x)/(max_all_x - min_all_x)*(discre_2-4) + 2;
                y = (curr_frame_gt(:,3) - min_all_y)/(max_all_y - min_all_y)*(discre_3-4) + 2;
                z = (curr_frame_gt(:,4) - min_all_z)/(max_all_z - min_all_z)*(discre_1-4) + 2;
                
                x = round(x);
                y = round(y);
                z = round(z);
                
                
                IMG = zeros(discre_1,discre_2,discre_3);
                for n = 1:size(x,1)
                    IMG(sub2ind(size(IMG),z(n,1),x(n,1),y(n,1))) = 1;
                end
                
                IMG = IMG(:);
                IMG = IMG + 1e-7;
                IMG = IMG/sum(IMG);
                
                p = cat(2,p,IMG);
            end
            n = length(IMG);
            areaWeights = ones(n,1)/n;
            
            %% Set up blur
            filterSize = 3; %was 5

            h = fspecial('gaussian',[1 max(imSize)],filterSize);% hsize sigma
            h = h / sum(h);

            imBlur = @(x) imfilter(imfilter(x,h,'replicate'),h','replicate');

            %blurColumn = @(x) reshape(fastBlur(reshape(x,imSize),filterSize),[],1);
            blurColumn = @(x) reshape(imBlur(reshape(x,imSize)),[],1);
            blurAll = @(x) cell2mat(cellfun(blurColumn, num2cell(x,1), 'UniformOutput', false));

            %% Compute barycenter

            averages = cell(1,1);
            barycenters = cell(1,1);
            alpha = ones(1,size(p,2))/size(p,2);

            entropies = -sum(p.*log(p).*repmat(areaWeights,1,size(p,2)));
            minEntropy = min(entropies);
            targetEntropy = minEntropy;

            close all;

            a = sum(bsxfun(@times,p,alpha),2);
            averages{1} = reshape(a,imSize);

            subplot(1,2,1);
            imagesc(averages{1});axis equal;axis off;
            colormap gray

            b = convolutionalBarycenter(p,alpha,areaWeights,blurAll,blurAll,targetEntropy);
            barycenters{1} = reshape(b,imSize);

            subplot(1,2,2);
            imagesc(barycenters{1});axis equal;axis off;
            colormap gray

            drawnow;
           
%             figure
%             for i = 1:size(frame_track_gt,2)
%                 curr_track_gt = frame_track_gt{1,i};
%                 scatter(curr_track_gt(find(curr_track_gt(:,5) == 1),2),curr_track_gt(find(curr_track_gt(:,5) == 1),4),'.g')
%                 hold on
%                 scatter(curr_track_gt(find(curr_track_gt(:,5) == 0),2),curr_track_gt(find(curr_track_gt(:,5) == 0),4),'.b')
%             end
%             scatter(base_track_gt(:,2),base_track_gt(:,4),'.r')

            
        end
    end
end