function [tracks_TPSRPM, TPSRPM_runtime] = methods_TPSRPM(source, target, cnt, tracks_TPSRPM, TPSRPM_runtime, run_local)
if ~run_local
    path_1 = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods_reg/TPS-RPM';
else
    path_1 = 'D:\Shivesh\OptimalTransport\tracking\other_methods_reg\TPS-RPM';
end
addpath(genpath(path_1))

tic
% CPD parameters
frac       = 1;
T_init     = 0.5;
T_finalfac = 3000;
disp_flag  = 0;
m_method   = 'mix-rpm';
lam1       = 1;
lam2       = 0.01;
perTmaxit  = 3;


% Note - keep disp_flag zero because TPS_RPM code throws error for
% visualizing 3D points registration. No error for 2D points.
[c,d,m]=cMIX (target,source,frac,T_init, T_finalfac, disp_flag, 'mixture');
C = zeros(size(target,1),1)
for n = 1:size(m,1)
    max_curr = max(m(n,:));
    if max_curr ~= 0
        curr_match = find(m(n,:) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_TPSRPM{1,cnt} = C;
TPSRPM_runtime = TPSRPM_runtime + toc;

rmpath(genpath(path_1))
end