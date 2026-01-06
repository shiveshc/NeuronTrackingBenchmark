function [tracks_PRGLS, PRGLS_runtime] = methods_PRGLS(source, target, cnt, tracks_PRGLS, PRGLS_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/PR-GLS-master';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\PR-GLS-master';
end
addpath(genpath(path_1))

tic
% PRGLS parameters
opt.outliers = 0.3;
opt.viz = 0;
opt.t = 0.9;
opt.sparse = 0;
opt.nsc = 5;
opt.normalize = 1;
opt.beta = 1;
opt.lambda = 3;
opt.tol = 1e-10;
opt.corresp = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[Transform,C] = prgls_register(source, target, opt);
C = handle_duplicate_matches(C,source,target);
tracks_PRGLS{1,cnt} = C;
PRGLS_runtime = PRGLS_runtime + toc;

rmpath(genpath(path_1))
end