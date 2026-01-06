%%%% old tracking accuracy metrics code. 
%%%% New code is more standardised and uses track hypothesis list data
%%%% structure.

%%% CLEAR MOT metrics based on Bernandin paper
%%% "Multiple Object Tracking Performance Metrics
%%% and Evaluation in a Smart Room Environment"
frame_summary = [];
for i = 1:size(tracks,2)
    correct = 0;
    count_track = 0;
    if i == 1 % first frame                  
        curr_frame_gt = frame_track_gt{1,i};
        curr_track_TP = curr_frame_gt(curr_frame_gt(:,5) == 1,:);
        curr_track_TP_id = curr_frame_gt(curr_frame_gt(:,5) == 1,1);

        %%% since new tracks begin at all object in frame 1 all
        %%% are correct
        count_track = size(curr_track_TP,1);
        correct = count_track;

        objs_that_have_tracks = unique(curr_track_TP_id);
    else
        curr_frame_gt = frame_track_gt{1,i};
        curr_track = tracks{1,i};
        curr_track_TP = curr_track(curr_frame_gt(:,5) == 1,:);
        curr_track_TP_id = curr_frame_gt(curr_frame_gt(:,5) == 1,1);

        prev_frame_gt = frame_track_gt{1,i-1};

        for n = 1:size(curr_track_TP,1)
            curr_TP_id = curr_track_TP_id(n,1);

            if curr_track_TP(n,1) == 0 % a new track begins at the object
                %%% check if this is the first track of the object
                %%% or if the object has been tracked before. If
                %%% not then no IDswitch error else IDswitch error
                if isempty(find(curr_TP_id == objs_that_have_tracks))
                    correct = correct + 1;
                end
            else
                if curr_TP_id == prev_frame_gt(curr_track_TP(n,1),1)
                    correct = correct + 1;
                end
            end
            count_track = count_track + 1;
        end

        objs_that_have_tracks = unique([objs_that_have_tracks;curr_track_TP_id]);
    end
    frame_summary = [frame_summary;[count_track,correct]];
end
track_link_accuracy = sum(frame_summary(:,2))/sum(frame_summary(:,1));

%%% tracking accuracy metrics from Nevatia paper
%%% "Tracking of Multiple, Partially Occluded Humans based on
%%% Static Body Part Detection"
gt_objects = base_track_gt(:,1);
MT = 0;
ML = 0;
gt_obj_frag_map_edge = zeros(size(gt_objects,1),size(tracks,2)); % counts fragments if consecutive times are joined
gt_obj_frag_map_node = zeros(size(gt_objects,1),size(tracks,2)); % counts single tp fragments (consecutive times are not joined)
for n = 1:size(gt_objects,1)
    tracked = 0;
    for i = 2:size(tracks,2)
        curr_frame_gt = frame_track_gt{1,i};
        curr_track = tracks{1,i};

        prev_frame_gt = frame_track_gt{1,i-1};

        if and(~isempty(find(gt_objects(n,1) == curr_frame_gt(:,1))),~isempty(find(gt_objects(n,1) == prev_frame_gt(:,1))))
            gt_object_index = find(gt_objects(n,1) == curr_frame_gt(:,1));
            if curr_track(gt_object_index,1) == 0 % no track hyp for the gt obj in curr frame
            elseif gt_objects(n,1) == prev_frame_gt(curr_track(gt_object_index,1),1)
                tracked = tracked + 1;
            end
        end
    end
    if tracked/(size(tracks,2)-1) >= 0.8
        MT = MT + 1;
    elseif tracked/(size(tracks,2)-1) <= 0.2
        ML = ML + 1;
    end

    for i = 1:size(tracks,2)
        if i == 1
            gt_obj_frag_map_edge(n,i) = 0;

            curr_frame_gt = frame_track_gt{1,i};
            curr_frame_obj_index = find(gt_objects(n,1) == curr_frame_gt(:,1));

            if ~isempty(curr_frame_obj_index)
                next_frame_gt = frame_track_gt{1,i+1};
                next_frame_obj_index = find(gt_objects(n,1) == next_frame_gt(:,1));
                next_track = tracks{1,i+1};
                if isempty(next_frame_obj_index)
                    gt_obj_frag_map_node(n,i) = 1;
                elseif next_track(next_frame_obj_index,1) == 0
                    gt_obj_frag_map_node(n,i) = 1;
                elseif curr_frame_gt(next_track(next_frame_obj_index,1),1) ~= gt_objects(n,1)
                    gt_obj_frag_map_node(n,i) = 1;
                end
            end
        elseif i == size(tracks,2)
            curr_frame_gt = frame_track_gt{1,i};
            curr_frame_obj_index = find(gt_objects(n,1) == curr_frame_gt(:,1));

            if ~isempty(curr_frame_obj_index)
                prev_frame_gt = frame_track_gt{1,i-1};
                prev_frame_obj_index = find(gt_objects(n,1) == prev_frame_gt(:,1));
                curr_track = tracks{1,i};
                if isempty(prev_frame_obj_index)
                    gt_obj_frag_map_node(n,i) = 1;
                elseif curr_track(curr_frame_obj_index,1) == 0
                    gt_obj_frag_map_node(n,i) = 1;
                elseif prev_frame_gt(curr_track(curr_frame_obj_index,1),1) ~= gt_objects(n,1)
                    gt_obj_frag_map_node(n,i) = 1;
                end

                if ~isempty(prev_frame_obj_index)
                    if curr_track(curr_frame_obj_index,1) == 0
                    elseif gt_objects(n,1) == prev_frame_gt(curr_track(curr_frame_obj_index,1),1)
                        gt_obj_frag_map_edge(n,i) = 1;
                    end
                end
            end
        else
            curr_frame_gt = frame_track_gt{1,i};
            curr_track = tracks{1,i};
            curr_frame_obj_index = find(gt_objects(n,1) == curr_frame_gt(:,1));

            if ~isempty(curr_frame_obj_index)

                prev_cond = 0;
                prev_frame_gt = frame_track_gt{1,i-1};
                prev_frame_obj_index = find(gt_objects(n,1) == prev_frame_gt(:,1));
                if isempty(prev_frame_obj_index)
                    prev_cond = 1;
                elseif curr_track(curr_frame_obj_index,1) == 0
                    prev_cond = 1;
                elseif prev_frame_gt(curr_track(curr_frame_obj_index,1),1) ~= gt_objects(n,1)
                    prev_cond = 1;
                end
                next_cond = 0;
                next_frame_gt = frame_track_gt{1,i+1};
                next_frame_obj_index = find(gt_objects(n,1) == next_frame_gt(:,1));
                next_track = tracks{1,i+1};
                if isempty(next_frame_obj_index)
                    next_cond = 1;
                elseif next_track(next_frame_obj_index,1) == 0
                    next_cond = 1;
                elseif curr_frame_gt(next_track(next_frame_obj_index,1),1) ~= gt_objects(n,1)
                    next_cond = 1;
                end
                if and(prev_cond,next_cond)
                    gt_obj_frag_map_node(n,i) = 1;
                end

                if ~isempty(prev_frame_obj_index)
                    if curr_track(curr_frame_obj_index,1) == 0
                    elseif gt_objects(n,1) == prev_frame_gt(curr_track(curr_frame_obj_index,1),1)
                        gt_obj_frag_map_edge(n,i) = 1;
                    end
                end
            end   
        end
    end 
end
frags = 0;
for n = 1:size(gt_obj_frag_map_edge,1)
    num_frags = bwconncomp(gt_obj_frag_map_edge(n,:));
    for comp = 1:size(num_frags.PixelIdxList,2)
        if size(num_frags.PixelIdxList{1,comp},1) < 0.8*(size(tracks,2)-1)
            frags = frags + 1;
        end
    end
end
length_1_frags = 0;
for n = 1:size(gt_obj_frag_map_node,1)
    num_frags = sum(gt_obj_frag_map_node(n,:));
    length_1_frags = length_1_frags + num_frags;
end
frags_per_gt = (frags+length_1_frags)/size(base_track_gt,1);
