%%%% function to compare different tracking methods on synthetic data
%%%% Charles' tracking code

addpath(genpath('D:\Shivesh\OptimalTransport\CPD2'))

precision = [0.6];
recall = [0.6];

results = [];
for p = 1:size(precision,2)
    for r = 1:size(recall,2)
        for v = 1:50
            load('D:\Shivesh\OptimalTransport\annotation\data_neuron_relationship.mat')

            %%% select random 130 cells to be tracked in current video
            curr_to_be_tracked = randperm(size(X_rot,1),130);
            X_rot = X_rot(curr_to_be_tracked,:);
            Y_rot = Y_rot(curr_to_be_tracked,:);
            Z_rot = Z_rot(curr_to_be_tracked,:);
            total_cells = size(X_rot,1);
            base_track_gt = cat(2,[1:1:total_cells]',X_rot,Y_rot,Z_rot,ones(size(X_rot,1),1));


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
                curr_track = [curr_track;cat(2,[size(X_rot,1)+1:1:size(X_rot,1)+FP]',x_FP,y_FP,z_FP,zeros(FP,1))];

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

            %%% charles' code based matching
            tic
            allCenters = cell(1,size(frame_track_gt,2));
            numObjFound = zeros(size(frame_track_gt,2),1);
            for i = 1:size(frame_track_gt,2)
                dummy = struct();
                curr_track = frame_track_gt{1,i};
                for n = 1:size(curr_track,1)
                    dummy(n).Area = [];
                    dummy(n).Centroid = curr_track(n,2:4);
                    dummy(n).PixelList = [];
                end
                allCenters{1,i} = dummy;
                numObjFound(i,1) = size(curr_track,1);
            end
            [numObj,refFrame] = min(numObjFound);
            skipCells = [];
            writeVideoBool = false;
            [allCenters,regCenters,guesses,discrepancies] = trackSegmentedCells_for_syn_data('dummy',[],allCenters,[],refFrame,skipCells,writeVideoBool);
            curr_runtime = toc;
            
            
            [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_charles(base_track_gt, frame_track_gt, allCenters);
                       
            results = [results;v,precision(1,p),recall(1,r),precision_param,recall_param,curr_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
        end
    end
end