function [tracks_GLTP, GLTP_runtime] = methods_GLTP(source, target, cnt, tracks_GLTP, GLTP_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/gltp-master/cpd';
    path_2 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/gltp-master';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\gltp-master\cpd';
    path_2 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\gltp-master';
end
addpath(genpath(path_1))
addpath(path_2)

tic
% Perform gltp registration
opt.lambda    = 100;     % regularization LLE weight
opt.viz       = 0;           % show every iteration if viz = 1
opt.outliers  = 0.3;         % use 0.7 noise weight
opt.fgt       = 0;           % use FGT to compute matrix-vector products (2 means to switch to truncated version at the end, see cpd_register)
opt.normalize = 1;           % normalize to unit variance and zero mean before registering (default)
opt.corresp   = 1;           % compute correspondence vector at the end of registration (not being estimated by default)
opt.max_it    = 150;         % max number of iterations
opt.tol       = 1e-10;       % tolerance
opt.beta      = sqrt(2.5);   % regularization CPD kernel weight
opt.alpha     = 100;         % regularization CPD weight
opt.case    = 'articulated';

% Compute LLE neighborhood matrix W
W = neighbour_preserve(target,15);

% Perform registration
[T,C] = gltp(source, target, opt, W);

C = handle_duplicate_matches(C,source,target);
tracks_GLTP{1,cnt} = C;
GLTP_runtime = GLTP_runtime + toc;

rmpath(genpath(path_1))
rmpath(path_2)
end