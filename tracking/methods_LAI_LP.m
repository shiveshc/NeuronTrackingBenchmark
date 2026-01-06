function [tracks_LAI_LP, LAI_LP_runtime] = methods_LAI_LP(source, target, cnt, tracks_LAI_LP, LAI_LP_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/CPD2';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\LAI_LP_PAMI13_CVPR10_Matching_v0.1\CVPR10_PAMI13_Matching_v0.1';
end
addpath(genpath(path_1))

tic
% make neighbor graph in source
adj = zeros(size(source,1),size(source,1));
K = 6;
dist_source = repmat(diag(source*source'),1,size(source,1)) + repmat(diag(source*source')',size(source,1),1) - 2*source*source';
[sort_dist,sort_index] = sort(dist_source,2,'ascend');
for i = 1:size(adj,1)
    adj(i,sort_index(i,2:K+1)) = 1;
end
adj = max(adj,adj');


% make cost matrix
C = repmat(diag(source*source'),1,size(target,1)) + repmat(diag(target*target')',size(source,1),1) - 2*source*target';


% other parameters
lambda = 1;
roundingIterNum = 2;
diameterParams = [150,15,15,30];
Nsame = 3;

% LAI_LP
sol = Convex_Matching_Affine( source, adj, target, C, lambda, ...
    roundingIterNum, diameterParams, Nsame );
C = zeros(size(target,1),1);
for n = 1:size(C,1)
    max_curr = max(sol(:,n));
    if max_curr ~= 0
        curr_match = find(sol(:,n) == max_curr);
        C(n) = curr_match(1,1);
    end
end

C = handle_duplicate_matches(C,source,target);
tracks_LAI_LP{1,cnt} = C;
LAI_LP_runtime = LAI_LP_runtime + toc;

rmpath(genpath(path_1))
end