%%%% function to compare different tracking methods on synthetic data
%%%% all frame to base frame

precision = [0.75:0.05:1];
recall = [0.75:0.05:1];
% precision = 1;
% recall = 0.75;

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

%             %%% write movie
%             writerObj = VideoWriter('D:\Shivesh\OptimalTransport\tracking\synth_video_P0_R0_v3.avi'); % Name it.
%             writerObj.FrameRate = 10; % How many frames per second.
%             open(writerObj);
%             figure,
%             for i = 1:num_frames
%                 scatter(base_track_gt(:,2),base_track_gt(:,4),'.r')
%                 hold on
%                 curr_track = frame_track_gt{1,i};
% %                 scatter(curr_track(curr_track(:,5)==1,2),curr_track(curr_track(:,5)==1,4),'.b')  
% %                 scatter(curr_track(curr_track(:,5)==0,2),curr_track(curr_track(:,5)==0,4),'.g')  
%                 frame = getframe(gcf);
%                 writeVideo(writerObj, frame);
%                 cla()
%             end
%             close(writerObj)

            %%% registration based matching
            addpath(genpath('D:\Shivesh\OptimalTransport\CPD2'))
            % registration parameters
            opt.method='nonrigid'; % use nonrigid registration
            opt.beta=1;            % the width of Gaussian kernel (smoothness)
            opt.lambda=3;          % regularization weight

            opt.viz=0;              % DON't show every iteration
            opt.outliers=0.3;       % Noise weight
            opt.fgt=0;              % do not use FGT (default)
            opt.normalize=1;        % normalize to unit variance and zero mean before registering (default)
            opt.corresp=1;          % compute correspondence vector at the end of registration (not being estimated by default)

            opt.max_it=100;         % max number of iterations
            opt.tol=1e-10;          % tolerance
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            tracks = {};
            tic;
            for i = 1:size(frame_track_gt,2)
                source = base_track_gt;
                source = source(:,2:4);

                target = frame_track_gt{1,i};
                target = target(:,2:4);

                [Transform,C] = cpd_register(source, target, opt);

                % handle duplicate matches
                uniq_match = unique(C);
                for n = 1:size(uniq_match,1)
                    curr_match = uniq_match(n,1);
                    curr_match_index = find(C == curr_match);

                    if size(curr_match_index,1) > 1
                        curr_target = target(curr_match_index,:);
                        curr_source = source(curr_match,:);
                        dist_curr_target_to_source = repmat(diag(curr_target*curr_target'),1,size(curr_source,1)) + repmat(diag(curr_source*curr_source')',size(curr_target,1),1) - 2*curr_target*curr_source';
                        [sort_dist,sort_index] = sort(dist_curr_target_to_source,'ascend');
                        C(curr_match_index(sort_index(2:end,:),:),:) = 0;
                    end
                end

                tracks{1,i} = C;
            end
            curr_runtime = toc;
            
            [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks);
            
            results = [results;v,precision(1,p),recall(1,r),precision_param,recall_param,curr_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
        end
    end
end



    

