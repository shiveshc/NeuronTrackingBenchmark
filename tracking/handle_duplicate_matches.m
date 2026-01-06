function C = handle_duplicate_matches(C,source,target)
    uniq_match = unique(C);
    if uniq_match(1,1) == 0
        uniq_match(1,:) = [];
    end
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
end