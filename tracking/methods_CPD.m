function [tracks_CPD, CPD_runtime] = methods_CPD(source, target, cnt, tracks_CPD, CPD_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/CPD2';
else
    path_1 = 'D:\Shivesh\OptimalTransport\CPD2';
end
addpath(genpath(path_1))

tic
% CPD parameters
opt.method='nonrigid'; % use nonrigid registration
opt.beta=1;            % the width of Gaussian kernel (smoothness)
opt.lambda=3;          % regularization weight

opt.viz=0;              % DON't show every iteration
opt.outliers=0.3;       % Noise weight
opt.fgt=0;              % do not use FGT (default)
opt.normalize=1;        % normalize to unit variance and zero mean before registering (default)
opt.corresp=1;          % compute correspondence vector at the end of registration (not being estimated by default)

opt.max_it=100;         % max number of iterations
opt.tol=1e-10;          % tolerance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[Transform,C] = cpd_register(source, target, opt);
C = handle_duplicate_matches(C,source,target);
tracks_CPD{1,cnt} = C;
CPD_runtime = CPD_runtime + toc;

rmpath(genpath(path_1))
end