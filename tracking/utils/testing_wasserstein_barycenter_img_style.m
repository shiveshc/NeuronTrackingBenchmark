%%% function to compute wasserstein baryenters based on "Iterative bregman
%%% projections for regularized transport problems". Note that in this case
%%% we will do an image style like in Peyre code

addpath(genpath('D:\Shivesh\OptimalTransport\tracking\2014-SISC-BregmanOT-master\code\barycenters'))
% precision = [1];
% recall = [0.7087,0.6359,0.5146,0.3932,0.2718];
precision = 0.8;
recall = 0.8;

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
                recall_param = normrnd(recall(1,r),0.056);
%                 precision_param = normrnd(precision(1,p),0.04);
%                 recall_param = recall(1,r);
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
            
            %%% make images from frame_track_gt
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
            discre_1 = 20;
            discre_2 = 40;
            discre_3 = 20;
            imgNNNN = zeros(discre_3,discre_2,discre_1, size(frame_track_gt,2));
            
            for i = 1:size(frame_track_gt,2)
                curr_frame_gt = frame_track_gt{1,i};
                x = (curr_frame_gt(:,2) - min_all_x)/(max_all_x - min_all_x)*(discre_2-4) + 2;
                y = (curr_frame_gt(:,3) - min_all_y)/(max_all_y - min_all_y)*(discre_3-4) + 2;
                z = (curr_frame_gt(:,4) - min_all_z)/(max_all_z - min_all_z)*(discre_1-4) + 2;
                
                x = round(x);
                y = round(y);
                z = round(z);
                
                max_x = max(x);
                max_y = max(y);
                max_z = max(z);
                
                IMG = zeros(discre_3,discre_2,discre_1);
                for n = 1:size(x,1)
                    IMG(sub2ind(size(IMG),z(n,1),x(n,1),y(n,1))) = 1;
                end
                IMG = IMG/sum(sum(sum(IMG)));
                
                imgNNNN(:,:,:,i) = IMG;
            end
            
            R = reshape(imgNNNN,size(imgNNNN,1)*size(imgNNNN,2)*size(imgNNNN,3),size(imgNNNN,4));
            
            [X,Y,Z] = meshgrid(1:size(imgNNNN,1),1:size(imgNNNN,2),1:size(imgNNNN,3));
            p = [X(:),Y(:),Z(:)];
            M = repmat(diag(p*p'),1,size(p,1)) + repmat(diag(p*p')',size(p,1),1) - 2*p*p';
            M = M/median(M(:));
            
            toleranceDifference=1e-4;
            inLoopTolerance=.1;
            lambda=500;
            StartingTrick=1;
            USINGGPU = false;
            t0=1;
            %c1=smoothConjugateDiscreteWassersteinBarycenter(R,M,100000,t0,lambda,USINGGPU,toleranceDifference,StartingTrick);
            cb=bregmanWassersteinBarycenter(R,M,10000,lambda,USINGGPU,toleranceDifference*.0001);
            
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