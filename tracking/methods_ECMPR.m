function [tracks_ECMPR, ECMPR_runtime] = methods_ECMPR(source, target, cnt, tracks_ECMPR, ECMPR_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/ecmpr_demo/DEMO ECMPR';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\ecmpr_demo\DEMO ECMPR';
end
addpath(path_1);

tic
maxNumIter = 100;

[R,t,v,a,Thistory] = ecmpr(source',target',maxNumIter);
C = zeros(size(target,1),1);
for n = 1:size(a,1)
    max_curr = max(a(n,:));
    if max_curr ~= 0
        curr_match = find(a(n,:) == max_curr);
        C(n) = curr_match(1,1);
    end
end

C = handle_duplicate_matches(C,source,target);
tracks_ECMPR{1,cnt} = C;
ECMPR_runtime = ECMPR_runtime + toc;

rmpath(path_1);
end