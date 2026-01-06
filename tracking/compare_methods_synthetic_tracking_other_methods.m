%%%% function to compare different tracking methods on synthetic data
%%%%
function compare_methods_synthetic_tracking_other_methods(precision, recall, num)
% precision = [0.75:0.05:1];
% recall = [0.75:0.05:1];
% precision = 0.75;
% recall = 0.75;
rng shuffle

results_SM = [];
results_SM_IPFP = [];
results_IPFP_gm = [];
results_IPFP = [];
results_IPFP_MAP = [];
results_L2QP_MAP = [];

results_GNCCP = [];
results_BPFG = [];
results_PSM = [];

results_GA = [];
results_PHM = [];
results_SMAC = [];
results_IPFPU = [];
results_IPFPS = [];
results_RRWM = [];
results_FGMD = [];

results_EigenAlign = [];
results_FAQAP = [];

% fgm_path = 'D:\Shivesh\OptimalTransport\tracking\other_methods\fgm-master'; 
% fgm_path = '/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/other_methods/fgm-master';
% path00 = cd;
% cd(fgm_path)
% make
% cd(path00)

for p = 1:size(precision,2)
    for r = 1:size(recall,2)
        for vid = 1:1
            load('D:\Shivesh\OptimalTransport\annotation\data_neuron_relationship.mat')
%             load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/data_neuron_relationship.mat')

            %%% select random 130 cells to be tracked in current video
            curr_to_be_tracked = randperm(size(X_rot,1),130);
            X_rot = X_rot(curr_to_be_tracked,:);
            Y_rot = Y_rot(curr_to_be_tracked,:);
            Z_rot = Z_rot(curr_to_be_tracked,:);
            total_cells = size(X_rot,1);
            base_track_gt = cat(2,[1:1:total_cells]',X_rot,Y_rot,Z_rot,ones(size(X_rot,1),1));
            id_cnt = max(base_track_gt(:,1));

            num_frames = 100;
            frame_track_gt = {}; % records gt neuron identities for each frame
            for i = 1:num_frames
                recall_param = normrnd(recall(1,r),0.056);
                precision_param = normrnd(precision(1,p),0.04);
%                 recall_param = recall;
%                 precision_param = precision;
                curr_track = base_track_gt;

                % add FN
                FN = max(0,round((1-recall_param)*total_cells));
                remove = randperm(total_cells,FN);
                curr_track(remove,:) = [];
                TP = size(curr_track,1);

                % add FP
                FP = max(0,round((1-precision_param)*TP/precision_param));
                x_FP = min(X_rot) + (max(X_rot) - min(X_rot))*rand(FP,1);
                y_FP = min(Y_rot) + (max(Y_rot) - min(Y_rot))*rand(FP,1);
                z_FP = min(Z_rot) + (max(Z_rot) - min(Z_rot))*rand(FP,1);
                curr_track = [curr_track;cat(2,[id_cnt+1:1:id_cnt+FP]',x_FP,y_FP,z_FP,zeros(FP,1))];
                id_cnt = max(curr_track(:,1));

                % add tiny position noise
            %     noise_level = [0.01,0.006,0.0056]; % position noise level 1
                noise_level = [0.01/2,0.006/2,0.0056/2];
                curr_track(:,2) = curr_track(:,2) + noise_level(1,1)*randn(size(curr_track,1),1);
                curr_track(:,3) = curr_track(:,3) + noise_level(1,2)*randn(size(curr_track,1),1);
                curr_track(:,4) = curr_track(:,4) + noise_level(1,3)*randn(size(curr_track,1),1);

                % store curr track
                frame_track_gt{1,i} = curr_track;
            end

%             %%% write movie
%             writerObj = VideoWriter('D:\Shivesh\OptimalTransport\tracking\synth_video_P0_R0_v3.avi'); % Name it.
%             writerObj.FrameRate = 10; % How many frames per second.
%             open(writerObj);
%             figure,
%             for i = 1:num_frames
%                 scatter(base_track_gt(:,2),base_track_gt(:,4),'.r')
%                 hold on
%                 curr_track = frame_track_gt{1,i};
% %                 scatter(curr_track(curr_track(:,5)==1,2),curr_track(curr_track(:,5)==1,4),'.b')  
% %                 scatter(curr_track(curr_track(:,5)==0,2),curr_track(curr_track(:,5)==0,4),'.g')  
%                 frame = getframe(gcf);
%                 writeVideo(writerObj, frame);
%                 cla()
%             end
%             close(writerObj)


            %%%% start tracking with several QAP methods            
            tracks_SM = {};
            tracks_SM_IPFP = {};
            tracks_IPFP_gm = {};
            tracks_IPFP = {};
            tracks_IPFP_MAP = {};
            tracks_L2QP_MAP = {};
            
            tracks_KerGM = {};
            tracks_GNCCP = {};
            tracks_BPFG = {};
            tracks_PSM = {};
            
            tracks_GA = {};
            tracks_PHM = {};
            tracks_SMAC = {};
            tracks_IPFPU = {};
            tracks_IPFPS = {};
            tracks_RRWM = {};
            tracks_FGMD = {};
            
            tracks_LAI_LP = {};
            tracks_EigenAlign = {};
            tracks_FAQAP = {};
            tracks_RCCA = {};
            
            common_runtime = 0; M_t1 = 0; K_t1 = 0; F_t1 = 0;
            SM_runtime = 0;
            SM_IPFP_runtime = 0;
            IPFP_gm_runtime = 0;
            IPFP_runtime = 0;
            IPFP_MAP_runtime = 0;
            L2QP_MAP_runtime = 0;
            
            KerGM_runtime = 0;
            GNCCP_runtime = 0;
            BPFG_runtime = 0;
            PSM_runtime = 0;
            
            GA_runtime = 0;
            PHM_runtime = 0;
            SMAC_runtime = 0;
            IPFPU_runtime = 0;
            IPFPS_runtime = 0;
            RRWM_runtime = 0;
            FGMD_runtime = 0;
            
            LAI_LP_runtime = 0;
            EigenAlign_runtime = 0;
            FAQAP_runtime = 0;
            RCCA_runtime = 0;
            
            for i = 2:size(frame_track_gt,2)
                tic
                source = frame_track_gt{1,i-1};
                source = source(:,2:4);
                [PA_matrix_src,LR_matrix_src,DV_matrix_src] = make_pos_relation_mat(source);
                
                target = frame_track_gt{1,i};
                target = target(:,2:4);
                [PA_matrix,LR_matrix,DV_matrix] = make_pos_relation_mat(target);
                
                
                % make source and target graphs
                nNodes = size(PA_matrix,1);
                Eg_target = make_edges(nNodes);
                
                nLabels = size(PA_matrix_src,1);
                Eg_src = make_edges(nLabels);
                
                
                % make node-affinity and edge-affinity
                [KP, KQ] = make_gphKPQD(nNodes, nLabels, Eg_target, Eg_src, target, source, PA_matrix, LR_matrix, DV_matrix, PA_matrix_src, LR_matrix_src, DV_matrix_src, [1,1,1,1]);
                
                
                % make global affinity
                [K, M] = make_gphK(KP, KQ, Eg_target, Eg_src);
                common_runtime = common_runtime + toc;
                
                
                run_local = 1;
                %%% Several methods by Marius Leordeanu ,  Martial Hebert
%                 methods_Leordeanu
                
                
                %%% Methods from KerGM
%                 methods_KerGM
                
                
                %%% Methods from FGM
%                 methods_FGM


                %%% Methods that require adjacency matrices
%                 [tracks_LAI_LP, LAI_LP_runtime] = methods_LAI_LP(source,target, i, tracks_LAI_LP, LAI_LP_runtime); % works for only 2d points
                [tracks_EigenAlign, EigenAlign_runtime] = methods_EigenAlign(source, target, i, tracks_EigenAlign, EigenAlign_runtime, run_local);
                [tracks_FAQAP, FAQAP_runtime] = methods_FAQAP(source, target, i, tracks_FAQAP, FAQAP_runtime, run_local);
                
                
                %%% Methods that need only points
%                 [tracks_RCCA, RCCA_runtime] = methods_RCCA(source, target, i, tracks_RCCA, RCCA_runtime, run_local);
                
            end
            
%             total_SM_runtime = common_runtime + M_t1 + SM_runtime;
%             total_SM_IPFP_runtime = common_runtime + M_t1 + SM_IPFP_runtime;
%             total_IPFP_gm_runtime = common_runtime + M_t1 + IPFP_gm_runtime;
%             total_IPFP_runtime = common_runtime + M_t1 + IPFP_runtime;
%             total_IPFP_MAP_runtime = common_runtime + M_t1 + IPFP_MAP_runtime;
%             total_L2QP_MAP_runtime = common_runtime + M_t1 + L2QP_MAP_runtime;
            
%             total_GNCCP_runtime = common_runtime + K_t1 + GNCCP_runtime;
%             total_BPFG_runtime = common_runtime + K_t1 +  BPFG_runtime;
%             total_PSM_runtime = common_runtime + K_t1 + PSM_runtime;
            
%             total_GA_runtime = common_runtime + F_t1 + GA_runtime;
%             total_PHM_runtime = common_runtime + F_t1 + PHM_runtime;
%             total_SMAC_runtime = common_runtime + F_t1 + SMAC_runtime;
%             total_IPFPU_runtime = common_runtime + F_t1 + IPFPU_runtime;
%             total_IPFPS_runtime = common_runtime + F_t1 + IPFPS_runtime;
%             total_RRWM_runtime = common_runtime + F_t1 + RRWM_runtime;
%             total_FGMD_runtime = common_runtime + F_t1 + FGMD_runtime;

              total_EigenAlign_runtime = EigenAlign_runtime;
              total_FAQAP_runtime = FAQAP_runtime;
            
            
              
              %% Leordeanu methods
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_SM);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_SM_runtime);
            if isempty(fieldnames(results_SM)); results_SM = results; else; results_SM = [results_SM;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_SM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_SM')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_SM_IPFP);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_SM_IPFP_runtime);
            if isempty(fieldnames(results_SM_IPFP)); results_SM_IPFP = results; else; results_SM_IPFP = [results_SM_IPFP;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_SMIPFP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_SM_IPFP')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_IPFP_gm);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFP_gm_runtime);
            if isempty(fieldnames(results_IPFP_gm)); results_IPFP_gm = results; else; results_IPFP_gm = [results_IPFP_gm;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFPgm_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFP_gm')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_IPFP);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFP_runtime);
            if isempty(fieldnames(results_IPFP)); results_IPFP = results; else; results_IPFP = [results_IPFP;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFP')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_IPFP_MAP);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFP_MAP_runtime);
            if isempty(fieldnames(results_IPFP_MAP)); results_IPFP_MAP = results; else; results_IPFP_MAP = [results_IPFP_MAP;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFPmap_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFP_MAP')
            
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_L2QP_MAP);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_L2QP_MAP_runtime);
            if isempty(fieldnames(results_L2QP_MAP)); results_L2QP_MAP = results; else; results_L2QP_MAP = [results_L2QP_MAP;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_L2QPMAP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_L2QP_MAP')
            
            
            %% KerGM methods
%             results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_GNCCP);
%             results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_GNCCP_runtime);
%             if isempty(fieldnames(results_GNCCP)); results_GNCCP = results; else; results_GNCCP = [results_GNCCP;results]; end
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_GNCCP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_GNCCP')
%             
%             results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_BPFG);
%             results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_BPFG_runtime);
%             if isempty(fieldnames(results_BPFG)); results_BPFG = results; else; results_BPFG = [results_BPFG;results]; end
%             save(['/gpfs/pace1/project/pchbe2/schaudhary9/OptimalTransport/Results/results_BPFG_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_BPFG')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_PSM);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_PSM_runtime);
            if isempty(fieldnames(results_PSM)); results_PSM = results; else; results_PSM = [results_PSM;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_PSM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_PSM')
            
            
            %% FGM methods
%             results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_GA);
%             results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_GA_runtime);
%             if isempty(fieldnames(results_GA)); results_GA = results; else; results_GA = [results_GA;results]; end
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_GA_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_GA')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_PHM);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_PHM_runtime);
            if isempty(fieldnames(results_PHM)); results_PHM = results; else; results_PHM = [results_PHM;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_PHM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_PHM')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_SMAC);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_SMAC_runtime);
            if isempty(fieldnames(results_SMAC)); results_SMAC = results; else; results_SMAC = [results_SMAC;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_SMAC_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_SMAC')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_IPFPU);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFPU_runtime);
            if isempty(fieldnames(results_IPFPU)); results_IPFPU = results; else; results_IPFPU = [results_IPFPU;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFPU_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFPU')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_IPFPS);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFPS_runtime);
            if isempty(fieldnames(results_IPFPS)); results_IPFPS = results; else; results_IPFPS = [results_IPFPS;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFPS_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFPS')
            
            results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_RRWM);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_RRWM_runtime);
            if isempty(fieldnames(results_RRWM)); results_RRWM = results; else; results_RRWM = [results_RRWM;results]; end
            save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_RRWM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_RRWM')
            
%             results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_FGMD);
%             results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_FGMD_runtime);
%             if isempty(fieldnames(results_FGMD)); results_FGMD = results; else; results_FGMD = [results_FGMD;results]; end
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_FGMD_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_FGMD')
            

            %% methods that require adjacency matrices
%             results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_EigenAlign);
%             results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_EigenAlign_runtime);
%             if isempty(fieldnames(results_EigenAlign)); results_EigenAlign = results; else; results_EigenAlign = [results_EigenAlign;results]; end
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_EigenAlign_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_EigenAlign')
%             
%             results = quantify_accuracy_sequential_v2(base_track_gt, frame_track_gt, tracks_FAQAP);
%             results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,total_FAQAP_runtime);
%             if isempty(fieldnames(results_FAQAP)); results_FAQAP = results; else; results_FAQAP = [results_FAQAP;results]; end
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_FAQAP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_FAQAP')


            %% Leordeanu methods
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_SM);
%             results_SM = [results_SM;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_SM_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_SM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_SM')
% 
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_SM_IPFP);
%             results_SM_IPFP = [results_SM_IPFP;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_SM_IPFP_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_SMIPFP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_SM_IPFP')
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_IPFP_gm);
%             results_IPFP_gm = [results_IPFP_gm;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFP_gm_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFPgm_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFP_gm')
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_IPFP);
%             results_IPFP = [results_IPFP;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFP_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFP')
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_IPFP_MAP);
%             results_IPFP_MAP = [results_IPFP_MAP;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFP_MAP_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFPmap_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFP_MAP')
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_L2QP_MAP);
%             results_L2QP_MAP = [results_L2QP_MAP;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_L2QP_MAP_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_L2QPMAP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_L2QP_MAP')
            
            
            %% KerGM methods
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_GNCCP);
%             results_GNCCP = [results_GNCCP;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_GNCCP_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_GNCCP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_GNCCP')
            
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_BPFG);
%             results_BPFG = [results_BPFG;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_BPFG_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/gpfs/pace1/project/pchbe2/schaudhary9/OptimalTransport/Results/results_BPFG_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_BPFG')
            
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_PSM);
%             results_PSM = [results_PSM;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_PSM_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_PSM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_PSM')
            
            
            %% FGM methods
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_GA);
%             results_GA = [results_GA;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_GA_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_GA_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_GA')

%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_PHM);
%             results_PHM = [results_PHM;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_PHM_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_PHM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_PHM')
            
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_SMAC);
%             results_SMAC = [results_SMAC;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_SMAC_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_SMAC_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_SMAC')
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_IPFPU);
%             results_IPFPU = [results_IPFPU;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFPU_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFPU_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFPU')
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_IPFPS);
%             results_IPFPS = [results_IPFPS;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_IPFPS_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_IPFPS_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_IPFPS')
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_RRWM);
%             results_RRWM = [results_RRWM;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_RRWM_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_RRWM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_RRWM')
            
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_FGMD);
%             results_FGMD = [results_FGMD;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_FGMD_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_FGMD_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_FGMD')

            %% methods that require adjacency matrices
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_EigenAlign);
%             results_EigenAlign = [results_EigenAlign;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_EigenAlign_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_EigenAlign_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_EigenAlign')
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_FAQAP);
%             results_FAQAP = [results_FAQAP;vid,precision(1,p),recall(1,r),precision_param,recall_param,total_FAQAP_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/OM_sequential/results_FAQAP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_FAQAP')

        end
    end
end