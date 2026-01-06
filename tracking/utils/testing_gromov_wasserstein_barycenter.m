%%% function to compute fused gromov wasserstein baryenters based on 
%%% modification of "Fast Computation of Wasserstein Barycenters" paper

% precision = [1];
% recall = [0.7087,0.6359,0.5146,0.3932,0.2718];
precision = 1;
recall = 0.8;
rng(42)
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
            
%             figure
%             for i = 1:size(frame_track_gt,2)
%                 curr_track_gt = frame_track_gt{1,i};
%                 scatter(curr_track_gt(find(curr_track_gt(:,5) == 1),2),curr_track_gt(find(curr_track_gt(:,5) == 1),4),'.g')
%                 hold on
%                 scatter(curr_track_gt(find(curr_track_gt(:,5) == 0),2),curr_track_gt(find(curr_track_gt(:,5) == 0),4),'.b')
%             end
%             scatter(base_track_gt(:,2),base_track_gt(:,4),'.r')

            %%%% compute barycenter
            size_count = zeros(1,size(frame_track_gt,2));
            Y = {};
            for i = 1:size(frame_track_gt,2)
                size_count(1,i) = size(frame_track_gt{1,i},1);
                Y_i = frame_track_gt{1,i};
                Y_i = Y_i(:,2:4);
                Y{1,i} = Y_i;
            end
            [sort_size,sort_index] = sort(size_count,'descend');
            
            % start algo 2
            X = Y{1,sort_index(1,1)};
            X = X';
            [PA_matrix,LR_matrix,DV_matrix] = make_pos_relation_mat(X');
            C = cat(3,PA_matrix,LR_matrix,DV_matrix);
            a = 1/size(X,2)*ones(size(X,2),1);
            Y(:,sort_index(1,1)) = [];
            theta = 0.5;
            max_iter = 10;
            iter = 1;
            while iter < max_iter
%                 T_star = {};
%                 alpha_star = [];
%                 loss = [];
%                 for i = 1:size(Y,2)
%                     Y_i = Y{1,i};
%                     Y_i = Y_i';
%                     b_i = 1/size(Y_i,2)*ones(size(Y_i,2),1);
%                     M_i = repmat(diag(X'*X),1,size(Y_i,2)) + repmat(diag(Y_i'*Y_i)',size(X,2),1) - 2*X'*Y_i;
%                     [T_i,alpha_i,loss_i] = wass_algo3(a,b_i,M_i,iter);
%                     T_star{1,i} = T_i;
%                     alpha_star = [alpha_star,alpha_i];
%                     loss = [loss,loss_i];
%                 end
%                 a = wass_algo1(alpha_star);
                
                T_star = {};
                alpha_star = [];
                loss = [];
                for i = 1:size(Y,2)
                    Y_i = Y{1,i};
                    Y_i = Y_i';
                    [PA_matrix,LR_matrix,DV_matrix] = make_pos_relation_mat(Y_i');
                    C_prime = cat(3,PA_matrix,LR_matrix,DV_matrix);
                    b_i = 1/size(Y_i,2)*ones(size(Y_i,2),1);
                    M_i = repmat(diag(X'*X),1,size(Y_i,2)) + repmat(diag(Y_i'*Y_i)',size(X,2),1) - 2*X'*Y_i;
                    [T_i,alpha_i,loss_i] = gromov_wass_algo3(a,b_i,M_i,C,C_prime,iter);
%                     plot_match(X,Y_i,T_i)
                    T_star{1,i} = T_i;
                    alpha_star = [alpha_star,alpha_i];
                    loss = [loss,loss_i];
                end
                temp = 0;
                for i = 1:size(Y,2)
                    temp = temp + Y{1,i}'*T_star{1,i}';
                end
                X_new = (1-theta)*X + theta*1/size(Y,2)*temp*diag(1./a);
                
                plot_wass_bary(X,X_new,Y,mean(loss))
                
                X = X_new;
                [PA_matrix,LR_matrix,DV_matrix] = make_pos_relation_mat(X');
                C = cat(3,PA_matrix,LR_matrix,DV_matrix);
                
                iter = iter + 1;
            end
        end
    end
end