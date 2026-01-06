function [tracks_FAQAP, FAQAP_runtime] = methods_FAQAP(source, target, cnt, tracks_FAQAP, FAQAP_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/FastApproximateQAP-master/code/FAQ';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\FastApproximateQAP-master\code\FAQ';
end
addpath(genpath(path_1))

tic
% ER based
p = 0.7;
k = 6;
m = size(source,1);
n = size(target,1);
if m < n
    source_n = [source;zeros(n-m,3)];
    target_n = target;
else
    target_n = [target;zeros(m-n,3)];
    source_n = source;
end
[Graph1,Graph2] = make_ERGraph_Occ(target_n,source_n,size(target_n,1),size(source_n,1),p,k);
adj_n = Graph1;
adj_src_n = Graph2;
% adj = Graph1(1:size(target,1),1:size(target,1));
% adj_src = Graph2(1:size(source,1),1:size(source,1));


% % delaunay based
% dt_src = delaunay(source);
% adj_src = zeros(size(source,1),size(source,1));
% dt_edges = [dt_src(:,[1,2]);dt_src(:,[1,3]);dt_src(:,[1,4]);dt_src(:,[2,3]);dt_src(:,[2,4]);dt_src(:,[3,4])];
% dt_edges = [dt_edges;dt_edges(:,[2,1])];
% ind = sub2ind(size(adj_src),dt_edges(:,1),dt_edges(:,2));
% adj_src(ind) = 1;
% 
% dt = delaunay(target);
% adj = zeros(size(target,1),size(target,1));
% dt_edges = [dt(:,[1,2]);dt(:,[1,3]);dt(:,[1,4]);dt(:,[2,3]);dt(:,[2,4]);dt(:,[3,4])];
% dt_edges = [dt_edges;dt_edges(:,[2,1])];
% ind = sub2ind(size(adj),dt_edges(:,1),dt_edges(:,2));
% adj(ind) = 1;


% % nearest neighbor based
% adj_src = zeros(size(source,1),size(source,1));
% K = 6;
% dist_source = repmat(diag(source*source'),1,size(source,1)) + repmat(diag(source*source')',size(source,1),1) - 2*source*source';
% [sort_dist,sort_index] = sort(dist_source,2,'ascend');
% for i = 1:size(adj_src,1)
%     adj_src(i,sort_index(i,2:K+1)) = 1;
% end
% adj_src = max(adj_src,adj_src');
% 
% % nearest neighbor based
% adj = zeros(size(target,1),size(target,1));
% K = 6;
% dist_source = repmat(diag(target*target'),1,size(target,1)) + repmat(diag(target*target')',size(target,1),1) - 2*target*target';
% [sort_dist,sort_index] = sort(dist_source,2,'ascend');
% for i = 1:size(adj,1)
%     adj(i,sort_index(i,2:K+1)) = 1;
% end
% adj = max(adj,adj');



% % make graphs same size
% if size(adj_src,1) < size(adj,1)
%     adj_src_n = blkdiag(adj_src,ones(size(adj,1) - size(adj_src,1)));
%     adj_n = adj;
% elseif size(adj_src,1) > size(adj,1)
%     adj_n = blkdiag(adj,ones(size(adj_src,1) - size(adj,1)));
%     adj_src_n = adj_src;
% end

 
% FAQAP
[f,myp,x,iter,fs,myps]=sfw(adj_n,adj_src_n,30,-1);
ind = sub2ind(size(adj_n),1:1:size(adj_n,1),myp);
sol = zeros(size(adj_n));
sol(ind) = 1;
if size(source,1) < size(target,1)
    C = zeros(size(target,1),1);
    for n = 1:size(C,1)
        max_curr = max(sol(n,:));
        if max_curr ~= 0
            curr_match = find(sol(n,:) == max_curr);
            if curr_match > size(source,1)
                C(n) = 0;
            else
                C(n) = curr_match(1,1);
            end
        end
    end
elseif size(source,1) >= size(target,1)
    C = zeros(size(target,1),1);
    for n = 1:size(C,1)
        max_curr = max(sol(n,:));
        if max_curr ~= 0
            curr_match = find(sol(n,:) == max_curr);
            C(n) = curr_match(1,1);
        end
    end
end

C = handle_duplicate_matches(C,source,target);
tracks_FAQAP{1,cnt} = C;
FAQAP_runtime = FAQAP_runtime + toc;

rmpath(genpath(path_1))
end