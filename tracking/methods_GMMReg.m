function [tracks_GMMReg, GMMReg_runtime] = methods_GMMReg(source, target, cnt, tracks_GMMReg, GMMReg_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/gmmreg-master/MATLAB';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\gmmreg-master\MATLAB';
end
addpath(genpath(path_1))

tic
motion = 'tps'; % can be 'rigid2d', 'rigid3d', 'affine2d', 'affine3d'.
[config] = initialize_config(target, source, motion);
[param, transformed_target, history, config] = gmmreg_L2(config);

%%% map transformed target to source
dist_target_to_source = repmat(diag(transformed_target*transformed_target'),1,size(source,1)) + repmat(diag(source*source')',size(transformed_target,1),1) - 2*transformed_target*source';
[min_dist,index] = min(dist_target_to_source,[],2);
C = index;
C = handle_duplicate_matches(C,source,target);
tracks_GMMReg{1,cnt} = C;
GMMReg_runtime = GMMReg_runtime + toc;

rmpath(genpath(path_1))
end

function [config] = initialize_config(model, scene, motion)

config.model = model;
config.scene = scene;
config.motion = motion;
% estimate the scale from the covariance matrix
[n,d] = size(model);
config.scale = power(det(model'*model/n), 1/(2^d));
config.display = 0;
config.init_param = [ ];
config.max_iter = 100;
config.normalize = 0;
switch lower(motion)
    case 'tps'
        interval = 10;
        config.ctrl_pts =  set_ctrl_pts(model, scene, interval);
        config.alpha = 1;
        config.beta = 0;
        config.opt_affine = 1;
        [n,d] = size(config.ctrl_pts); % number of points in model set
        config.init_tps = zeros(n-d-1,d);
        init_affine = repmat([zeros(1,d) 1],1,d);
        config.init_param = [init_affine zeros(1, d*n-d*(d+1))];
        config.init_affine = [ ];
    otherwise
        [x0,Lb,Ub] = set_bounds(motion);
        config.init_param = x0;
        config.Lb = Lb;
        config.Ub = Ub;
end
end