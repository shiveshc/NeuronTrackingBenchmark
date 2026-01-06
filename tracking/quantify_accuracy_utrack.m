%%%% function to quantify accuracy for utrack method

function [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_utrack(base_track_gt, frame_track_gt, tracksFinal)

    %%%%% Create a list of track hypothesis. This is the main data
    %%%%% structure for calculating all tracking accuracy metrics.
    %%%%% NOTE - in this version all track hypothesis are already
    %%%%% mapped to gt objs. For some other trackers an additional
    %%%%% step of mapping track hypotheses to gt objs should be
    %%%%% performed before evaluating accuracy
              
    all_track_hyps = struct();
    cnt = 1;
    for n = 1:size(tracksFinal,1)
        track_hyp = [];
        track_hyp_frame = [];
        track_hyp_only_TP = [];
        
        curr_track_start_frame = tracksFinal(n).seqOfEvents(1,1);
        curr_track_length = size(tracksFinal(n).tracksFeatIndxCG,2);
        for t = 1:curr_track_length
            curr_track_frame = curr_track_start_frame + t - 1;
            curr_frame_gt = frame_track_gt{1,curr_track_frame};
            if tracksFinal(n).tracksFeatIndxCG(1,t) == 0 % zeros indicate frames where particles do not exist because of temporary particle disappearance
            else
                curr_track_particle_id = curr_frame_gt(tracksFinal(n).tracksFeatIndxCG(1,t),1);
                track_hyp = [track_hyp,curr_track_particle_id];
                track_hyp_frame = [track_hyp_frame,curr_track_frame];
                if curr_frame_gt(tracksFinal(n).tracksFeatIndxCG(1,t),5) == 1
                    track_hyp_only_TP = [track_hyp_only_TP,curr_track_particle_id];
                else
                    track_hyp_only_TP = [track_hyp_only_TP,0];
                end
            end
        end
        all_track_hyps(cnt).track_hyp = track_hyp;
        all_track_hyps(cnt).track_hyp_frame = track_hyp_frame;
        all_track_hyps(cnt).track_hyp_only_TP = track_hyp_only_TP;
        all_track_hyps(cnt).track_hyp_end = 1;
        cnt = cnt + 1;
    end
    for t = 1:size(frame_track_gt,2)
        curr_frame_gt = frame_track_gt{1,t};
        for n = 1:size(curr_frame_gt,1)
            flag = 0;
            for hyps = 1:size(all_track_hyps,2)
                %%% check if the object is already a part of some track
                curr_t_index = find(t == all_track_hyps(hyps).track_hyp_frame);
                if ~isempty(curr_t_index)
                    if curr_frame_gt(n,1) == all_track_hyps(hyps).track_hyp(1,curr_t_index)
                        flag = 1;
                        break
                    end
                end
            end
            if flag == 0
                all_track_hyps(cnt).track_hyp = curr_frame_gt(n,1);
                all_track_hyps(cnt).track_hyp_frame = t;
                if curr_frame_gt(n,5) == 1
                    all_track_hyps(cnt).track_hyp_only_TP = curr_frame_gt(n,1);
                else
                    all_track_hyps(cnt).track_hyp_only_TP = 0;
                end
                all_track_hyps(cnt).track_hyp_end = 1;
                cnt = cnt + 1;
            end
        end
    end

    

    %%% Tracking metrics based on Kevin Smith paper
    %%% "Evaluating Multi-Object Tracking"
    % identity mapping of each track hyp to gt obj based on
    % majority voting and calculating track purity
    track_purity = [];
    for hyps = 1:size(all_track_hyps,2)
        curr_track_hyp_only_TP = all_track_hyps(hyps).track_hyp_only_TP;
        curr_objs = unique(curr_track_hyp_only_TP);
        curr_objs_cnt = zeros(1,size(curr_objs,2));
        for n = 1:size(curr_objs,2)
            curr_objs_cnt(1,n) = size(find(curr_objs(1,n) == curr_track_hyp_only_TP),2);
        end
        [sort_cnt,sort_index] = sort(curr_objs_cnt,2,'descend');
        GT_match = curr_objs(1,sort_index(1,1));
        if GT_match ~= 0
            track_purity = [track_purity;curr_objs_cnt(1,sort_index(1,1))/size(curr_track_hyp_only_TP,2)];
        end
    end
    mean_track_purity = mean(track_purity);

    % identity mapping of each gt obj to track hyp based on
    % majority voting and calculate obj purity
    gt_obj_hyp_map = zeros(size(base_track_gt,1),size(frame_track_gt,2));
    for n = 1:size(base_track_gt,1)
        curr_gt_obj = base_track_gt(n,1);
        for t = 1:size(frame_track_gt,2)
            for hyps = 1:size(all_track_hyps,2)
                curr_t_index = find(t == all_track_hyps(hyps).track_hyp_frame);
                if ~isempty(curr_t_index)
                    if all_track_hyps(hyps).track_hyp(1,curr_t_index) == curr_gt_obj
                        gt_obj_hyp_map(n,t) = hyps;
                        break
                    end
                end
            end
        end
    end
    obj_purity = [];
    for n = 1:size(gt_obj_hyp_map,1)
        curr_hyp_map_uniq = unique(gt_obj_hyp_map(n,:));
        % note 0 in gt_obj_hyp_map means that there was not hypotheis
        % generated for the gt obj at that t 
        if curr_hyp_map_uniq(1,1) == 0 
            curr_hyp_map_uniq(:,1) = [];
        end
        curr_hyp_map_cnt = zeros(1,size(curr_hyp_map_uniq,2));
        for i = 1:size(curr_hyp_map_uniq,2)
            curr_hyp_map_cnt(1,i) = sum(curr_hyp_map_uniq(1,i) == gt_obj_hyp_map(n,:));
        end
        [sort_cnt,sort_index] = sort(curr_hyp_map_cnt,2,'descend');
        obj_purity = [obj_purity;curr_hyp_map_cnt(1,sort_index(1,1))/sum(curr_hyp_map_cnt)];
    end
    mean_obj_purity = mean(obj_purity);


    %%% CLEAR MOT metrics based on Bernandin paper
    %%% "Multiple Object Tracking Performance Metrics
    %%% and Evaluation in a Smart Room Environment"
    frame_summary = [];
    count_track = 0;
    correct = 0;
    for t = 1:size(frame_track_gt,2)
        count_track = 0;
        correct = 0;
        curr_frame_gt = frame_track_gt{1,t};
        if t == 1
            for n = 1:size(gt_obj_hyp_map,1)
                if ~isempty(find(n == curr_frame_gt(:,1)))
                    count_track = count_track + 1;
                    correct = correct + 1;
                end
            end
        else
            for n = 1:size(gt_obj_hyp_map,1)
                if ~isempty(find(n == curr_frame_gt(:,1)))
                    curr_track_hyp = gt_obj_hyp_map(n,t);
                    last_track_hyp = gt_obj_hyp_map(n,max(find(gt_obj_hyp_map(n,1:t-1) > 0)));
    %               if and(sum(gt_obj_hyp_map(n,1:t-1)) == 0, all_track_hyps(curr_track_hyp).track_hyp_frame(1,1) == t) % this means curr t is the first timepoint when track start for the gt object
                    if sum(gt_obj_hyp_map(n,1:t-1)) == 0 % this means curr t is the first timepoint when track start for the gt object
                        correct = correct + 1;
                    else
                        if curr_track_hyp == last_track_hyp
                            correct = correct + 1;
                        end
                    end
                    count_track = count_track + 1;
                end
            end
        end
        frame_summary = [frame_summary;count_track,correct];
    end
    track_link_accuracy = sum(frame_summary(:,2))/sum(frame_summary(:,1));


    %%% Tracking accuracy metrics from Nevatia paper
    %%% "Tracking of Multiple, Partially Occluded Humans based on
    %%% Static Body Part Detection"
    frags = 0;
    length_1_frags = 0;
    MT = 0;
    ML = 0;
    for n = 1:size(gt_obj_hyp_map,1)
        tracked = 0;
        for t = 2:size(frame_track_gt,2)
            if and(gt_obj_hyp_map(n,t) ~=0, gt_obj_hyp_map(n,t-1) ~= 0)
                if gt_obj_hyp_map(n,t) == gt_obj_hyp_map(n,t-1)
                    tracked = tracked + 1;
                end
            end
        end
        if tracked/(size(frame_track_gt,2)-1) >= 0.8
            MT = MT + 1;
        elseif tracked/(size(frame_track_gt,2)-1) <= 0.2
            ML = ML + 1;
        end

        curr_uniq_track_hyps = unique(gt_obj_hyp_map(n,:));
        if curr_uniq_track_hyps(1,1) == 0
            curr_uniq_track_hyps(:,1) = [];
        end
        for k = 1:size(curr_uniq_track_hyps,2)
            comps = bwconncomp(gt_obj_hyp_map(n,:) == curr_uniq_track_hyps(1,k));
            for c = 1:comps.NumObjects
                frag_length = size(comps.PixelIdxList{1,c},1);
                if frag_length == 1
                    length_1_frags = length_1_frags + 1;
                else
                    frags = frags + 1;
                end
            end
        end
    end
    frags_per_gt = (frags + length_1_frags)/size(gt_obj_hyp_map,1);
end