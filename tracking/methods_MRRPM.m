function [tracks_MRRPM, MRRPM_runtime] = methods_MRRPM(source, target, cnt, tracks_MRRPM, MRRPM_runtime, run_local)
if ~run_local
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\MR-RPM-master';
end
addpath(genpath(path_1))

tic
% MR-RPM parameters
conf = struct();
conf = set_conf(conf);

if size(source,1) <= size(target,1)
    transformed_target = run_MR(target, source, conf);

    %%% map transformed target to source
    dist_target_to_source = repmat(diag(transformed_target*transformed_target'),1,size(source,1)) + repmat(diag(source*source')',size(transformed_target,1),1) - 2*transformed_target*source';
    [min_dist,index] = min(dist_target_to_source,[],2);
    C = index;
    C = handle_duplicate_matches(C,source,target);
elseif size(target,1) <= size(source,1)
    transformed_source = run_MR(source, target, conf);
    
    %%% map transformed target to source
    dist_source_to_target = repmat(diag(transformed_source*transformed_source'),1,size(target,1)) + repmat(diag(target*target')',size(transformed_source,1),1) - 2*transformed_source*target';
    [min_dist,index] = min(dist_source_to_target',[],2);
    C = index;
    C = handle_duplicate_matches(C,source,target);
end

tracks_MRRPM{1,cnt} = C;
MRRPM_runtime = MRRPM_runtime + toc;


rmpath(genpath(path_1))
end

function conf = set_conf(conf)
%   CONF = set_conf(CONF) sets the default configuration for registration.
%
%   gamma: Percentage of inliers in the samples. This is an inital value
%       for EM iteration, and it is not important. Default value is 0.9.
%
%   beta: Paramerter of Gaussian Kernel, k(x, y) = exp(-beta*||x-y||^2).
%       Default value is 0.1.
%
%   lambda1: Regularization parameter of norm of transformation in Hilbert
%       space ||f||_H
% 
%   lambda2: Regularization parameter of manifold regularization term on
%       transformation ||f||_M
%
%   theta: If the posterior probability of a sample being an inlier is 
%       larger than theta, then it will be regarded as an inlier.
%       Default value is 0.75.
%
%   a: Paramerter of the uniform distribution. We assume that the outliers
%       obey a uniform distribution 1/a. Default Value is 10.
%
%   MaxIter: Maximum iterition times. Defualt value is 500.
%
%   ecr: The minimum limitation of the energy change rate in the iteration
%       process. Default value is 1e-5.
%
%   minP: The posterior probability Matrix P may be singular for matrix
%       inversion. We set the minimum value of P as minP. Default value is
%       1e-5.
%   Kn: The number of k-nearst neibourhood. Default value is 15.
%   M: The number of control point. Default value is 15.


% Authors: Jiayi Ma (jyma2010@gmail.com)
% Date:    04/17/2012

if ~isfield(conf,'MaxIter'), conf.MaxIter = 500; end;
if ~isfield(conf,'gamma'), conf.gamma = 0.9; end;
if ~isfield(conf,'beta'), conf.beta = 0.1; end;
if ~isfield(conf,'theta'), conf.theta = 0.75; end;
if ~isfield(conf,'a'), conf.a = 10; end;
if ~isfield(conf,'ecr'), conf.ecr = 1e-5; end;
if ~isfield(conf,'minP'), conf.minP = 1e-5; end;
if ~isfield(conf,'Kn'), conf.Kn = 15; end;
if ~isfield(conf,'M'), conf.M = 15; end;
if ~isfield(conf,'lambda1'), conf.lambda1 = 3; end;
if ~isfield(conf,'lambda2'), conf.lambda2 = 1; end;
if ~isfield(conf,'r'), conf.r = 0.05; end;
if ~isfield(conf,'normalize'), conf.normalize = 1; end;
end