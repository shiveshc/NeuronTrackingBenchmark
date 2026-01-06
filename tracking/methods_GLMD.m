function [tracks_GLMD, GLMD_runtime] = methods_GLMD(source, target, cnt, tracks_GLMD, GLMD_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/GLMD_Demo/src' ;
    path_2 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/GLMD_Demo' ;
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\GLMD_Demo\src' ;
    path_2 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\GLMD_Demo' ;
end
addpath(path_1);
addpath(path_2);

tic
m = GLMD(target, source); % target X source correspondence matrix
C = zeros(size(target,1),1);
for n = 1:size(m,1)
    max_curr = max(m(n,:));
    if max_curr ~= 0
        curr_match = find(m(n,:) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_GLMD{1,cnt} = C;
GLMD_runtime = GLMD_runtime + toc;

rmpath(path_1)
rmpath(path_2)