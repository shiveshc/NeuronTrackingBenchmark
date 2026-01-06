%%%% function to apply Nerve data association strategy to tracking

function compare_methods_NERVE(precision, recall, num)
rng shuffle
addpath(genpath('D:\Shivesh\OptimalTransport\tracking\NeRVEclustering-master'))

for p = 1:size(precision,2)
    for r = 1:size(recall,2)
        for vid = 1:1
            load('D:\Shivesh\OptimalTransport\annotation\data_neuron_relationship.mat')
%             load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/data_neuron_relationship.mat')

            %%% select random 130 cells to be tracked in current video
            curr_to_be_tracked = randperm(size(X_rot,1),50);
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
            
            
            %%% create pointStats - main data structure input to NERVE
            pointStats = struct();
            for i = 1:size(frame_track_gt,2)
                curr_frame_track_gt = frame_track_gt{1,i}; 
                
                pointStats(i).stackIdx = i;
                pointStats(i).straightPoints = curr_frame_track_gt(:,2:4);
                pointStats(i).rawPoints = curr_frame_track_gt(:,2:4);
                pointStats(i).pointIdx = [1:1:size(curr_frame_track_gt,1)]';
                pointStats(i).Rintensities = zeros(size(curr_frame_track_gt,1),1);
                pointStats(i).Volume = zeros(size(curr_frame_track_gt,1),1);
            end
            num_ref = 5;
            ref_idx = round(linspace(1,size(pointStats,2),num_ref));
            PS_ref = pointStats(ref_idx);
            
            
            
            %%% start NERVE
            startIdx=1;
            nGroups=2;
            offset=0;
            doGroups=1; 
            clusterWormTracker_mod([],startIdx,nGroups,pointStats,PS_ref)
        end
    end
end
