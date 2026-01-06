% function compare_methods_utrack(precision, recall, num)
rng shuffle
addpath(genpath('D:\Shivesh\OptimalTransport\tracking\u-track-master'))

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
            
            
            %%% create movieInfo - main data structure input to tracking
            %%% code
            movieInfo = struct();
            for i = 1:size(frame_track_gt,2)
                curr_frame_track_gt = frame_track_gt{1,i}; 
                
                movieInfo(i,1).xCoord = cat(2,curr_frame_track_gt(:,2),zeros(size(curr_frame_track_gt,1),1));
                movieInfo(i,1).yCoord = cat(2,curr_frame_track_gt(:,3),zeros(size(curr_frame_track_gt,1),1));
                movieInfo(i,1).zCoord = cat(2,curr_frame_track_gt(:,4),zeros(size(curr_frame_track_gt,1),1));
                movieInfo(i,1).amp = cat(2,ones(size(curr_frame_track_gt,1),1),zeros(size(curr_frame_track_gt,1),1));
            end
            
            
            
            %%% start utrack
            tic
            scriptTrackGeneral;
            curr_runtime = toc;
            load('D:\Shivesh\OptimalTransport\tracking\Results\utrack\tracksTest.mat')
%             [tracedFeatureInfo, trackedFeatureIndx] = convStruct2MatNoMS(tracksFinal);
            
            
            %%% calculate accuracy
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_utrack(base_track_gt, frame_track_gt, tracksFinal);
%             results = [results;vid,precision(1,p),recall(1,r),precision_param,recall_param,curr_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
            
            results_temp = quantify_accuracy_utrack_v2(base_track_gt, frame_track_gt, tracksFinal);
            results_temp = add_var_to_struct(results_temp,precision(1,p),recall(1,r),precision_param,recall_param,curr_runtime);
            if isempty(fieldnames(results)); results = results_temp; else; results = [results;results_temp]; end
            
            clear costMatrices gapCloseParam kalmanFunctions kalmanInfoLink tracksFinal
        end
    end
end
end