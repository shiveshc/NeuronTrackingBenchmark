%%% function to run some methods provided by KerGM

if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/KerGM_Code-master/GraphMatching_ImageDataset/Methods/GNCCP';
    path_2 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/KerGM_Code-master/GraphMatching_ImageDataset/Methods/PSM';
    path_3 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/KerGM_Code-master/GraphMatching_ImageDataset/lib';
    path_4 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/KerGM_Code-master/GraphMatching_ImageDataset/functions';
    path_5 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/KerGM_Code-master/GraphMatching_ImageDataset/Methods/KerGMExact';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\KerGM_Code-master\GraphMatching_ImageDataset\Methods\GNCCP';
    path_2 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\KerGM_Code-master\GraphMatching_ImageDataset\Methods\PSM';
    path_3 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\KerGM_Code-master\GraphMatching_ImageDataset\lib';
    path_4 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\KerGM_Code-master\GraphMatching_ImageDataset\functions';
    path_5 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\KerGM_Code-master\GraphMatching_ImageDataset\Methods\KerGMExact';
end
addpath(genpath(path_1))
addpath(genpath(path_2))
addpath(genpath(path_3))
addpath(genpath(path_4))
addpath(genpath(path_5))


tic
[n1,n2] = size(KP);
Ct = ones(n1,n2);
[ind, ind_m] = find(Ct);
group1 = zeros(size(ind, 1), n1);
group2 = zeros(size(ind, 1), n2);
for e1 = 1:size(ind, 1)
    group1(e1, ind(e1)) = 1;
    group2(e1, ind_m(e1)) = 1;
end
group1 = logical(group1);
group2 = logical(group2);
K_t1 = K_t1 + toc;


% % KerGM
% tic
% gph_target = make_gph(target,Eg_target);
% gph_src = make_gph(source,Eg_src);
% 
% sigma=0.01;
% Graph1 = struct();
% Graph1.G = gph_target.G;
% Graph1.H = gph_target.H;
% Edge1 = gph_target.dsts;
% dist11=pdist2(Edge1,Edge1).^2;Graph1.K=exp(-dist11/sigma);
% Graph2 = struct();
% Graph2.G = gph_src.G;
% Graph2.H = gph_src.H;
% Edge2 = gph_src.dsts;
% dist22=pdist2(Edge2,Edge2).^2;Graph2.K=exp(-dist22/sigma);
% 
% lambda=1/(min(size(target,1),size(source,1)));num=11;
% [sol,val]=KerGM_Exact(Graph1,Graph2,KP,KQ,lambda,num);
% C = zeros(size(target,1),1);
% for n = 1:size(sol,1)
%     max_curr = max(sol(n,:));
%     if max_curr ~= 0
%         curr_match = find(sol(n,:) == max_curr);
%         C(n) = curr_match(1,1);
%     end
% end
% C = handle_duplicate_matches(C,source,target);
% tracks_KerGM{1,i} = C;
% KerGM_runtime = KerGM_runtime + toc;


% % GNCCP
% tic
% parGnccp = st('nItMa', 100, 'deta', 0.001, 'nHist', 5, 'rho', 2, 'theta', 0.01);
% sol = GNCCP_K(K, group1, group2, parGnccp);
% sol = greedyMapping(sol, group1, group2);
% sol = reshape(sol, size(target,1), size(source,1));
% C = zeros(size(target,1),1);
% for n = 1:size(sol,1)
%     max_curr = max(sol(n,:));
%     if max_curr ~= 0
%         curr_match = find(sol(n,:) == max_curr);
%         C(n) = curr_match(1,1);
%     end
% end
% C = handle_duplicate_matches(C,source,target);
% tracks_GNCCP{1,i} = C;
% GNCCP_runtime = GNCCP_runtime + toc;


% % BPF-G
% tic
% parGnccp = st('nItMa', 100, 'deta', 0.001, 'nHist', 5, 'rho', 2, 'theta', 0.01);
% sol = BPF_G(K, group1, group2, parGnccp);
% sol = greedyMapping(sol, group1, group2);
% sol = reshape(sol, size(target,1), size(source,1));
% C = zeros(size(target,1),1);
% for n = 1:size(sol,1)
%     max_curr = max(sol(n,:));
%     if max_curr ~= 0
%         curr_match = find(sol(n,:) == max_curr);
%         C(n) = curr_match(1,1);
%     end
% end
% C = handle_duplicate_matches(C,source,target);
% tracks_BPFG{1,i} = C;
% BPFG_runtime = BPFG_runtime + toc;


% PSM
tic
sol = PSM(K, group1, group2,200);
sol = reshape(sol, size(target,1), size(source,1));
C = zeros(size(target,1),1);
for n = 1:size(sol,1)
    max_curr = max(sol(n,:));
    if max_curr ~= 0
        curr_match = find(sol(n,:) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_PSM{1,i} = C;
PSM_runtime = PSM_runtime + toc;


rmpath(genpath(path_1))
rmpath(genpath(path_2))
rmpath(genpath(path_3))
rmpath(genpath(path_4))
rmpath(genpath(path_5))