%%% function to run methods by Leordeanu

if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/Code_including_Spectral_Matching/PairwiseMatching';
    path_2 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/Code_including_IPFP_and_L2QP_for_MAP_Inference/Efficient_MAP_Code';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\Code_including_Spectral_Matching\PairwiseMatching';
    path_2 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\Code_including_IPFP_and_L2QP_for_MAP_Inference\Efficient_MAP_Code';
end
addpath(genpath(path_1))
addpath(genpath(path_2))

tic
labels = zeros(1, nNodes*nLabels);
nodes = zeros(1, nNodes*nLabels);
el = 0;
for node =  1:nNodes
    for label = 1:nLabels
       el = el + 1;
       nodes(el)  = node;
       labels(el) = label;
    end
end
M_t1 = M_t1 + toc;



% SM
tic
[sol, v] = spectral_matching_1(M, labels, nodes);
sol = reshape(sol,size(source,1),size(target,1));
C = zeros(size(target,1),1);
for n = 1:size(C,1)
    max_curr = max(sol(:,n));
    if max_curr ~= 0
        curr_match = find(sol(:,n) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_SM{1,i} = C;
SM_runtime = SM_runtime + toc;


% SM_IPFP
tic
[sol, v] = spectral_matching_ipfp(M, labels, nodes);
sol = reshape(sol,size(source,1),size(target,1));
C = zeros(size(target,1),1);
for n = 1:size(C,1)
    max_curr = max(sol(:,n));
    if max_curr ~= 0
        curr_match = find(sol(:,n) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_SM_IPFP{1,i} = C;
SM_IPFP_runtime = SM_IPFP_runtime + toc;


% IPFP_gm
tic
sol0 = ones(length(nodes),1);
sol0 = sol0/norm(sol0);
[sol, v] = ipfp_gm(M, sol0, labels, nodes);
sol = reshape(sol,size(source,1),size(target,1));
C = zeros(size(target,1),1);
for n = 1:size(C,1)
    max_curr = max(sol(:,n));
    if max_curr ~= 0
        curr_match = find(sol(:,n) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_IPFP_gm{1,i} = C;
IPFP_gm_runtime = IPFP_gm_runtime + toc;


% IPFP
tic
sol0 = ones(length(nodes),1);
sol0 = sol0/norm(sol0);
D = zeros(length(sol0), 1);
[sol, x_opt, score, score_sol]  = ipfp(M, D, sol0, labels, nodes, 100);
sol = reshape(sol,size(source,1),size(target,1));
C = zeros(size(target,1),1);
for n = 1:size(C,1)
    max_curr = max(sol(:,n));
    if max_curr ~= 0
        curr_match = find(sol(:,n) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_IPFP{1,i} = C;
IPFP_runtime = IPFP_runtime + toc;


% IPFP_MAP
tic
sol0 = ones(length(nodes),1);
sol0 = sol0/norm(sol0);
D = zeros(length(sol0), 1);
[sol, score2] = IPFP_MAP_inference(M, D, sol0, labels, nodes);
sol = reshape(sol,size(source,1),size(target,1));
C = zeros(size(target,1),1);
for n = 1:size(C,1)
    max_curr = max(sol(:,n));
    if max_curr ~= 0
        curr_match = find(sol(:,n) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_IPFP_MAP{1,i} = C;
IPFP_MAP_runtime = IPFP_MAP_runtime + toc;


% L2QP_MAP
tic
D = zeros(length(nodes), 1);
[sol, score1, V] = L2QP_MAP_inference(M, D, labels, nodes, 50, 200);
sol = reshape(sol,size(source,1),size(target,1));
C = zeros(size(target,1),1);
for n = 1:size(C,1)
    max_curr = max(sol(:,n));
    if max_curr ~= 0
        curr_match = find(sol(:,n) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_L2QP_MAP{1,i} = C;
L2QP_MAP_runtime = L2QP_MAP_runtime + toc;

rmpath(genpath(path_1))
rmpath(genpath(path_2))