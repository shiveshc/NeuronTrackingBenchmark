%%%% function to quantify accuracy for sequential methods

function [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks)

    %%%%% Create a list of track hypothesis. This is the main data
    %%%%% structure for calculating all tracking accuracy metrics.
    %%%%% NOTE - in this version all object hypothesis are already
    %%%%% mapped to gt objs. For some other trackers an additional
    %%%%% step of mapping object hypotheses to gt objs should be
    %%%%% performed before bulding tracks and evaluating accuracy
    all_track_hyps = struct();
    cnt = 1;
    for t = 1:size(tracks,2)
        curr_frame_gt = frame_track_gt{1,t};
        obj_list = [];
        if ~isempty(fieldnames(all_track_hyps))
            for hyps = 1:size(all_track_hyps,2)
                %%% make a list of objs through which track_hyps
                %%% were passing at this t
                curr_t_index = find(t == all_track_hyps(hyps).track_hyp_frame);
                if ~isempty(curr_t_index)
                    obj_list = [obj_list;all_track_hyps(hyps).track_hyp(1,curr_t_index)];
                end
            end
        end

        for n = 1:size(curr_frame_gt,1)

            %%% check if curr obj was part of any previous
            %%% track hyps at this t
            flag = 0;
            if ~isempty(find(curr_frame_gt(n,1) == obj_list))
                flag = 1;
            end

            if ~flag
                track_hyp = [];
                track_hyp_frame = [];
                track_hyp_only_TP = [];
                track_hyp_end = 0;

                track_hyp = [track_hyp,curr_frame_gt(n,1)];
                track_hyp_frame = [track_hyp_frame,t];
                if curr_frame_gt(n,5) == 1
                    track_hyp_only_TP = [track_hyp_only_TP,curr_frame_gt(n,1)];
                else
                    track_hyp_only_TP = [track_hyp_only_TP,0];
                end
                prev_match = n;

                for next_t = t+1:size(tracks,2)
                    next_track = tracks{1,next_t};
                    next_frame_gt = frame_track_gt{1,next_t};
                    next_match = find(next_track == prev_match);
                    if isempty(next_match)
                        track_hyp_end = 1;
                        break
                    else
                        track_hyp = [track_hyp,next_frame_gt(next_match,1)];
                        track_hyp_frame = [track_hyp_frame,next_t];
                        if next_frame_gt(next_match,5) == 1
                            track_hyp_only_TP = [track_hyp_only_TP,next_frame_gt(next_match,1)];
                        else
                            track_hyp_only_TP = [track_hyp_only_TP,0];
                        end
                        prev_match = next_match;
                    end
                end
                all_track_hyps(cnt).track_hyp = track_hyp;
                all_track_hyps(cnt).track_hyp_frame = track_hyp_frame;
                all_track_hyps(cnt).track_hyp_only_TP = track_hyp_only_TP;
                all_track_hyps(cnt).track_hyp_end = track_hyp_end;
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
    gt_obj_hyp_map = zeros(size(base_track_gt,1),size(tracks,2));
    for n = 1:size(base_track_gt,1)
        curr_gt_obj = base_track_gt(n,1);
        for t = 1:size(tracks,2)
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
    for t = 1:size(tracks,2)
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
        for t = 2:size(tracks,2)
            if and(gt_obj_hyp_map(n,t) ~=0, gt_obj_hyp_map(n,t-1) ~= 0)
                if gt_obj_hyp_map(n,t) == gt_obj_hyp_map(n,t-1)
                    tracked = tracked + 1;
                end
            end
        end
        if tracked/(size(tracks,2)-1) >= 0.8
            MT = MT + 1;
        elseif tracked/(size(tracks,2)-1) <= 0.2
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