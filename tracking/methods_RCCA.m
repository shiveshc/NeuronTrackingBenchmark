function [tracks_RCCA, RCCA_runtime] = methods_RCCA(source, target, cnt, tracks_RCCA, RCCA_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/CPD2';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\RandomCliqueComplexes_ICML2018-master';
end
addpath(genpath(path_1))

tic

m = size(source,1);
n = size(target,1);

if m < n
    source_n = [source;zeros(n-m,3)];
    target_n = target;
else
    target_n = [target;zeros(m-n,3)];
    source_n = source;
end

data = {};
data{1,1} = target_n;
data{1,2} = source_n;
 
% RCCA
GraphMatching(data)

ind = sub2ind(size(adj_n),1:1:size(adj_n,1),myp);
sol = zeros(size(adj_n));
sol(ind) = 1;
if size(adj_src,1) < size(adj,1)
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
elseif size(adj_src,1) > size(adj,1)
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