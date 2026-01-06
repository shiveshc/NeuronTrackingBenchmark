%%%% function to compare different tracking methods on synthetic data
%%%% CRF based tracking

function compare_methods_synthetic_tracking_gw_eot(precision,recall,num)
% precision = [0.6];
% recall = [0.6];
% precision = 1;
% recall = 1;
% param_p = [0.6];
% param_r = [0.6];
% 
% results = [];
% for param = 1:size(param_p,2)
%     precision = param_p(1,param);
%     recall = param_r(1,param);
for p = 1:size(precision,2)
    for r = 1:size(recall,2)
        for v = 1:50
%             load('D:\Shivesh\OptimalTransport\annotation\data_neuron_relationship.mat')
            load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/data_neuron_relationship.mat')

            %%% select random 130 cells to be tracked in current video
            curr_to_be_tracked = randperm(size(X_rot,1),130);
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
                precision_param = normrnd(precision(1,p),0.04);
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

            % %%% write movie
            % writerObj = VideoWriter('D:\Shivesh\OptimalTransport\tracking\synth_video_P0_R0.avi'); % Name it.
            % writerObj.FrameRate = 10; % How many frames per second.
            % open(writerObj);
            % figure,
            % for i = 1:num_frames
            %     scatter(base_track_gt(:,2),base_track_gt(:,4),'.r')
            %     hold on
            %     curr_track = frame_track_gt{1,i};
            %     scatter(curr_track(:,2),curr_track(:,4),'.b')  
            %     frame = getframe(gcf);
            %     writeVideo(writerObj, frame);
            %     cla()
            % end
            % close(writerObj)

            %%% gw_eot based matching
            tracks = {};
            tic
            for i = 2:size(frame_track_gt,2)
                source = frame_track_gt{1,i-1};
                source = source(:,2:4);
                [PA_matrix_src,LR_matrix_src,DV_matrix_src] = make_pos_relation_mat(source);

                target = frame_track_gt{1,i};
                target = target(:,2:4);
                [PA_matrix,LR_matrix,DV_matrix] = make_pos_relation_mat(target);
                
                [curr_labels, lambda_PA, lambda_LR, lambda_DV, lambda_angle, alpha] = gw_eot_track_v2(PA_matrix_src, LR_matrix_src, DV_matrix_src, PA_matrix, LR_matrix, DV_matrix, source, target, [1,1,1,1]);
                    
                % handle duplicate matches
                uniq_match = unique(curr_labels);
                for n = 1:size(uniq_match,1)
                    curr_match = uniq_match(n,1);
                    curr_match_index = find(curr_labels == curr_match);

                    if size(curr_match_index,1) > 1
                        curr_target = target(curr_match_index,:);
                        curr_source = source(curr_match,:);
                        dist_curr_target_to_source = repmat(diag(curr_target*curr_target'),1,size(curr_source,1)) + repmat(diag(curr_source*curr_source')',size(curr_target,1),1) - 2*curr_target*curr_source';
                        [sort_dist,sort_index] = sort(dist_curr_target_to_source,'ascend');
                        curr_labels(curr_match_index(sort_index(2:end,:),:),:) = 0;
                    end
                end
                
                tracks{1,i} = curr_labels;
            end
            curr_runtime = toc;

%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks);
%             results = [results;v,precision(1,p),recall(1,r),precision_param,recall_param,lambda_PA,lambda_LR,lambda_DV,lambda_angle,alpha,noise_level,curr_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
            
            results_temp = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks);
            results_temp = add_var_to_struct(results_temp,precision(1,p),recall(1,r),precision_param,recall_param,lambda_PA,lambda_LR,lambda_DV,lambda_angle,alpha,noise_level,curr_runtime);
            if isempty(fieldnames(results)); results = results_temp; else; results = [results;results_temp]; end
            
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_gw_eot_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results')
            
        end
    end
end
end