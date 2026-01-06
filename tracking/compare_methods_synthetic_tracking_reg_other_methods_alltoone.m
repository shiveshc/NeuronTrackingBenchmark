%%%% function to compare different tracking methods on synthetic data
%%%%
% function compare_methods_synthetic_tracking_reg_other_methods_alltoone(precision, recall, num)
% precision = [0.9];
% recall = [0.9];
% precision = 0.75;
% recall = 0.75;

results_CPD = [];
results_GLMD = [];
results_GLTP = [];
results_GMMReg = [];
results_TPSRPM = [];
results_PRGLS = [];
results_L2ERPM = [];
results_MRRPM = [];
results_ECMPR = [];
results_munkres = [];

param_p = [0.8,0.7,0.6];
param_r = [0.8,0.7,0.6];

results = [];
for param = 1:size(param_p,2)
    precision = param_p(1,param);
    recall = param_r(1,param);
for p = 1:size(precision,2)
    for r = 1:size(recall,2)
        for vid = 1:50
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

            
            %%% registration based matching
            

            tracks_CPD = {};
            tracks_GLMD = {};
            tracks_GLTP = {};
            tracks_GMMReg = {};
            tracks_TPSRPM = {};
            tracks_PRGLS = {};
            tracks_L2ERPM = {};
            tracks_MRRPM = {};
            tracks_ECMPR = {};
            tracks_munkres = {};
            
            CPD_runtime = 0;
            GLMD_runtime = 0;
            GLTP_runtime = 0;
            GMMReg_runtime = 0;
            TPSRPM_runtime = 0;
            PRGLS_runtime = 0;
            L2ERPM_runtime = 0;
            MRRPM_runtime = 0;
            ECMPR_runtime = 0;
            munkres_runtime = 0;
            
            for i = 1:size(frame_track_gt,2)
                source = base_track_gt;
                source = source(:,2:4);

                target = frame_track_gt{1,i};
                target = target(:,2:4);
                
                %%% CPD
                [tracks_CPD, CPD_runtime] = methods_CPD(source, target, i, tracks_CPD, CPD_runtime, 1);
%                 
%                 %%% GLMD
%                 [tracks_GLMD, GLMD_runtime] = methods_GLMD(source, target, i, tracks_GLMD, GLMD_runtime, 1);
%                 
%                 %%% GLTP
%                 [tracks_GLTP, GLTP_runtime] = methods_GLTP(source, target, i, tracks_GLTP, GLTP_runtime, 1);
%                 
%                 %%% GMMReg
%                 [tracks_GMMReg, GMMReg_runtime] = methods_GMMReg(source, target, i, tracks_GMMReg, GMMReg_runtime, 1);
%                 
%                 %%% TPS-RPM
%                 [tracks_TPSRPM, TPSRPM_runtime] = methods_TPSRPM(source, target, i, tracks_TPSRPM, TPSRPM_runtime, 1);
%                 
%                 %%% PRGLS
%                 [tracks_PRGLS, PRGLS_runtime] = methods_PRGLS(source, target, i, tracks_PRGLS, PRGLS_runtime, 1);
%                 
%                 %%% L2E
%                 [tracks_L2ERPM, L2ERPM_runtime] = methods_L2E(source, target, i, tracks_L2ERPM, L2ERPM_runtime, 1);
%                 
%                 %%% MRRPM
%                 [tracks_MRRPM, MRRPM_runtime] = methods_MRRPM(source, target, i, tracks_MRRPM, MRRPM_runtime, 1);
%                 
%                 %%% ECMPR
%                 [tracks_ECMPR, ECMPR_runtime] = methods_ECMPR(source, target, i, tracks_ECMPR, ECMPR_runtime, 1);
%                 
%                 %%% Munkres
%                 [tracks_munkres, munkres_runtime] = methods_munkres(source, target, i, tracks_munkres, munkres_runtime, 1);

                
            end
          
            
            results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_CPD);
            results = add_var_to_struct(results,precision_param,recall_param,CPD_runtime);
            if isempty(fieldnames(results_CPD)); results_CPD = results; else; results_CPD = [results_CPD;results]; end
            
            results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_GLMD);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,GLMD_runtime);
            if isempty(fieldnames(results_GLMD)); results_GLMD = results; else; results_GLMD = [results_GLMD;results]; end
            
            results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_GLTP);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,GLTP_runtime);
            if isempty(fieldnames(results_GLTP)); results_GLTP = results; else; results_GLTP = [results_GLTP;results]; end
            
            results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_GMMReg);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,GMMReg_runtime);
            if isempty(fieldnames(results_GMMReg)); results_GMMReg = results; else; results_GMMReg = [results_GMMReg;results]; end
            
            results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_TPSRPM);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,TPSRPM_runtime);
            if isempty(fieldnames(results_TPSRPM)); results_TPSRPM = results; else; results_TPSRPM = [results_TPSRPM;results]; end
            
%             results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_PRGLS);
%             results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,PRGLS_runtime);
%             if isempty(fieldnames(results_PRGLS)); results_PRGLS = results; else; results_PRGLS = [results_PRGLS;results]; end
%             
%             results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_L2ERPM);
%             results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,L2ERPM_runtime);
%             if isempty(fieldnames(results_L2ERPM)); results_L2ERPM = results; else; results_L2ERPM = [results_L2ERPM;results]; end
%             
%             results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_MRRPM);
%             results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,MRRPM_runtime);
%             if isempty(fieldnames(results_MRRPM)); results_MRRPM = results; else; results_MRRPM = [results_MRRPM;results]; end
            
            results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_ECMPR);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,ECMPR_runtime);
            if isempty(fieldnames(results_ECMPR)); results_ECMPR = results; else; results_ECMPR = [results_ECMPR;results]; end
            
            results = quantify_accuracy_alltoone_v2(base_track_gt, frame_track_gt, tracks_munkres);
            results = add_var_to_struct(results,precision(1,p),recall(1,r),precision_param,recall_param,munkres_runtime);
            if isempty(fieldnames(results_munkres)); results_munkres = results; else; results_munkres = [results_munkres;results]; end
            
            
            % old results saving method
            
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks_CPD);
%             results_CPD = [results_CPD;vid,precision(1,p),recall(1,r),precision_param,recall_param,CPD_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks_GLMD);
%             results_GLMD = [results_GLMD;vid,precision(1,p),recall(1,r),precision_param,recall_param,GLMD_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks_GLTP);
%             results_GLTP = [results_GLTP;vid,precision(1,p),recall(1,r),precision_param,recall_param,GLTP_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks_GMMReg);
%             results_GMMReg = [results_GMMReg;vid,precision(1,p),recall(1,r),precision_param,recall_param,GMMReg_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks_TPSRPM);
%             results_TPSRPM = [results_TPSRPM;vid,precision(1,p),recall(1,r),precision_param,recall_param,TPSRPM_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks_PRGLS);
%             results_PRGLS = [results_PRGLS;vid,precision(1,p),recall(1,r),precision_param,recall_param,PRGLS_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks_L2ERPM);
%             results_L2ERPM = [results_L2ERPM;vid,precision(1,p),recall(1,r),precision_param,recall_param,L2ERPM_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_sequential(base_track_gt, frame_track_gt, tracks_MRRPM);
%             results_MRRPM = [results_MRRPM;vid,precision(1,p),recall(1,r),precision_param,recall_param,MRRPM_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks_ECMPR);
%             results_ECMPR = [results_ECMPR;vid,precision(1,p),recall(1,r),precision_param,recall_param,ECMPR_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
%             
%             [track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity] = quantify_accuracy_alltoone(base_track_gt, frame_track_gt, tracks_munkres);
%             results_munkres = [results_munkres;vid,precision(1,p),recall(1,r),precision_param,recall_param,munkres_runtime,track_link_accuracy,MT,ML,frags,length_1_frags,frags_per_gt,mean_track_purity,mean_obj_purity];
            
            
        end
        
%         save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/reg_OM_alltoone\results_CPD_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_CPD')
%         save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/reg_OM_alltoone\results_GLMD_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_GLMD')
%         save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/reg_OM_alltoone\results_GLTP_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_GLTP')
%         save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/reg_OM_alltoone\results_GMMReg_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_GMMReg')
%         save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/reg_OM_alltoone\results_TPSRPM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_TPSRPM')
%         save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/reg_OM_alltoone\results_PRGLS_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_PRGLS')
%         save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/reg_OM_alltoone\results_L2ERPM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_L2ERPM')
%         save(['D:\Shivesh\OptimalTransport\tracking\Results\reg_OM_alltoone\results_MRRPM_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_MRRPM')
%         save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/reg_OM_alltoone\results_ECMPR_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_ECMPR')
%         save(['/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/Results/reg_OM_alltoone\results_munkres_',num2str(precision(1,p)),'_',num2str(recall(1,r)),'_',num2str(num),'.mat'],'results_munkres')
        
    end
end
end
