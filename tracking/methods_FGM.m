%%% function to implement methods in FGM package
if ~run_local
    fgm_path = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/fgm-master';
else
    fgm_path = 'D:\Shivesh\OptimalTransport\tracking\other_methods_QAP\fgm-master';
end

path_1 = [fgm_path,'/src'];
path_2 = [fgm_path,'/lib'];

addpath(fgm_path)
addpath(genpath(path_1))
addpath(genpath(path_2))

tic
gph_target = make_gph(target,Eg_target);
gph_src = make_gph(source,Eg_src);
gphs = {};
gphs{1,1} = gph_target;
gphs{1,2} = gph_src;
[pars, algs] = gmPar(2);
Ct = ones(size(target,1),size(source,1));
F_t1 = F_t1 + toc;

% % GA
% tic
% asgGa = gm(K, Ct, [], pars{1}{:});
% sol = asgGa.X;
% C = zeros(size(target,1),1);
% for n = 1:size(sol,1)
%     max_curr = max(sol(n,:));
%     if max_curr ~= 0
%         curr_match = find(sol(n,:) == max_curr);
%         C(n) = curr_match(1,1);
%     end
% end
% C = handle_duplicate_matches(C,source,target);
% tracks_GA{1,i} = C;
% GA_runtime = GA_runtime + toc;


% PHM
tic
asgPhm = pm(K, KQ, gphs, []);
sol = asgPhm.X;
C = zeros(size(target,1),1);
for n = 1:size(sol,1)
    max_curr = max(sol(n,:));
    if max_curr ~= 0
        curr_match = find(sol(n,:) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_PHM{1,i} = C;
PHM_runtime = PHM_runtime + toc;


% SMAC
tic
asgSmac = gm(K, Ct, [], pars{4}{:});
sol = asgSmac.X;
C = zeros(size(target,1),1);
for n = 1:size(sol,1)
    max_curr = max(sol(n,:));
    if max_curr ~= 0
        curr_match = find(sol(n,:) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_SMAC{1,i} = C;
SMAC_runtime = SMAC_runtime + toc;


% IPFP-U
tic
asgIpfpU = gm(K, Ct, [], pars{5}{:});
sol = asgIpfpU.X;
C = zeros(size(target,1),1);
for n = 1:size(sol,1)
    max_curr = max(sol(n,:));
    if max_curr ~= 0
        curr_match = find(sol(n,:) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_IPFPU{1,i} = C;
IPFPU_runtime = IPFPU_runtime + toc;


% IPFP-S
tic
asgIpfpS = gm(K, Ct, [], pars{6}{:});
sol = asgIpfpS.X;
C = zeros(size(target,1),1);
for n = 1:size(sol,1)
    max_curr = max(sol(n,:));
    if max_curr ~= 0
        curr_match = find(sol(n,:) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_IPFPS{1,i} = C;
IPFPS_runtime = IPFPS_runtime + toc;


% RRWM
tic
asgRrwm = gm(K, Ct, [], pars{7}{:});
sol = asgRrwm.X;
C = zeros(size(target,1),1);
for n = 1:size(sol,1)
    max_curr = max(sol(n,:));
    if max_curr ~= 0
        curr_match = find(sol(n,:) == max_curr);
        C(n) = curr_match(1,1);
    end
end
C = handle_duplicate_matches(C,source,target);
tracks_RRWM{1,i} = C;
RRWM_runtime = RRWM_runtime + toc;


% % FGM-D
% tic
% asgFgmD = fgmD(KP, KQ, Ct, gphs, [], pars{9}{:});
% sol = asgFgmD.X;
% C = zeros(size(target,1),1);
% for n = 1:size(sol,1)
%     max_curr = max(sol(n,:));
%     if max_curr ~= 0
%         curr_match = find(sol(n,:) == max_curr);
%         C(n) = curr_match(1,1);
%     end
% end
% C = handle_duplicate_matches(C,source,target);
% tracks_FGMD{1,i} = C;
% FGMD_runtime = FGMD_runtime + toc;



rmpath(genpath(path_1))
rmpath(genpath(path_2))
