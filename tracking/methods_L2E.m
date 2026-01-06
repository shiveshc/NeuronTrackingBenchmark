function [tracks_L2ERPM, L2ERPM_runtime] = methods_L2E(source, target, cnt, tracks_L2ERPM, L2ERPM_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/RPM-L2E-master';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\RPM-L2E-master';
end
addpath(genpath(path_1))

tic
%%% parameters for L2E-RPM
opt.normalize = 1;
opt.thresh = 0.5;
opt.n_iter = 50;

if size(target,1) <= size(source,1)
    [idt,transformed_target] = runL2E(target, source, opt);

    %%% map transformed target to source
    dist_target_to_source = repmat(diag(transformed_target*transformed_target'),1,size(source,1)) + repmat(diag(source*source')',size(transformed_target,1),1) - 2*transformed_target*source';
    [min_dist,index] = min(dist_target_to_source,[],2);
    C = index;
    C = handle_duplicate_matches(C,source,target);
elseif size(source,1) < size(target,1)
    [idt,transformed_source] = runL2E(source, target, opt);

    %%% map transformed target to source
    dist_source_to_target = repmat(diag(transformed_source*transformed_source'),1,size(target,1)) + repmat(diag(target*target')',size(transformed_source,1),1) - 2*transformed_source*target';
    [min_dist,index] = min(dist_source_to_target',[],2);
    C = index;
    C = handle_duplicate_matches(C,source,target);
end
    
tracks_L2ERPM{1,cnt} = C;
L2ERPM_runtime = L2ERPM_runtime + toc;

rmpath(genpath(path_1))
end