% function compare_methods_cinda(precision, recall, num)
rng shuffle
addpath(genpath('D:\Shivesh\OptimalTransport\tracking\CINDA-master'))

param = [0.9, 0.8, 0.7, 0.6];
results = [];

for param_p = 1:size(param,2)
    precision = param(1,param_p);
    recall = param(1,param_p);
for p = 1:size(precision,2)
    for r = 1:size(recall,2)
        for vid = 1:50
            load('D:\Shivesh\OptimalTransport\annotation\data_neuron_relationship.mat')
%             load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/data_neuron_relationship.mat')

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
%                 recall_param = recall;
%                 precision_param = precision;
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
            
            
            %%% create inputs for mcc2mot.m, see user manual for
            %%% description.
            
            % make ids, detection_arcs and transition_arcs for all objects
            cnt = 0;
            ids = [];
            detection_arcs = [];
            transition_arcs = [];
            C_en = 0;
            C_ex = -log(precision*(1-recall) + (1-precision)*1);
            C_i = -log(precision/(1-precision));
            for i = 1:size(frame_track_gt,2)-1
                curr_frame_gt = frame_track_gt{1,i};
                next_frame_gt = frame_track_gt{1,i+1};
                curr_num_objs = size(curr_frame_gt,1);
                next_num_objs = size(next_frame_gt,1);
                
                curr_ids = cnt + [1:1:curr_num_objs]';
                cnt = cnt + size(curr_frame_gt,1);
                next_ids = cnt + [1:1:next_num_objs]';
                ids = [ids;cat(2,curr_frame_gt(:,1),repmat(i,curr_num_objs,1),curr_ids)];

                
                detection_arcs = [detection_arcs;curr_ids,repmat([C_en, C_ex, C_i],curr_num_objs,1)];
                
                
                curr_dets = curr_frame_gt(:,2:4);
                next_dets = next_frame_gt(:,2:4);
                transition_cost = sqrt(repmat(diag(curr_dets*curr_dets'),1,next_num_objs) + repmat(diag(next_dets*next_dets')',curr_num_objs,1) - 2*curr_dets*next_dets');
                curr_id_mat = repmat(curr_ids,1,next_num_objs);
                next_id_mat = repmat(next_ids',curr_num_objs,1);
                transition_arcs = [transition_arcs;curr_id_mat(:),next_id_mat(:),transition_cost(:)];
            end
            ids = [ids;cat(2,next_frame_gt(:,1),repmat(i+1,next_num_objs,1),next_ids)];    
            detection_arcs = [detection_arcs;next_ids,repmat([C_en, C_ex, C_i],next_num_objs,1)];
            
            
            
            %%% start cinda
            tic
            [trajectories, costs] = mcc4mot(detection_arcs,transition_arcs);
            curr_runtime = toc;
%             cost_s = sanity_check(detection_arcs, transition_arcs, trajectories);
            
            %%% calculate accuracy
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_cinda(base_track_gt, frame_track_gt, trajectories, ids);
%             results = [results;vid,precision(1,p),recall(1,r),precision_param,recall_param,curr_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
            
            results_temp = quantify_accuracy_cinda_v2(base_track_gt, frame_track_gt, trajectories, ids);
            results_temp = add_var_to_struct(results_temp,precision(1,p),recall(1,r),precision_param,recall_param,curr_runtime);
            if isempty(fieldnames(results)); results = results_temp; else; results = [results;results_temp]; end
            
        end
    end
end
end