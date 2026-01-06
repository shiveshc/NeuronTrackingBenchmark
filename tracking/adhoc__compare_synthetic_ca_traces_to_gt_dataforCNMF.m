% function to plot and compare gt traces and noisy traces in the synthetic
% data generated for CNMF

inp_dir = 'D:\Shivesh\OptimalTransport\tracking\data_for_CNMF_poisson\both_gt_and_noisy_img_uint16\test_data\vid_100_0.1_3';

load([inp_dir,'\cell_struct.mat'])
data_vars = get_fieldvar_from_struct(cell_struct, 'mu', 'gt_signal');
mu = data_vars{1,1};
gt_ca_signal = data_vars{1,2};


gt_vid_dir = [inp_dir,'\gt_vid'];
noisy_vid_dir = [inp_dir,'\noisy_vid'];
pred_vid_dir = [inp_dir, '\pred_vid_poisson_hourglass_wres_d1_6_1000'];
tp_to_read = [1, 100];
gt_vid = read_wb_video(gt_vid_dir, tp_to_read);
noisy_vid = read_wb_video(noisy_vid_dir, tp_to_read);
pred_vid = read_wb_video(pred_vid_dir, tp_to_read);

gt_vid_ca_signal = zeros(size(cell_struct,2), size(gt_vid, 4));
noisy_vid_ca_signal = zeros(size(cell_struct,2), size(noisy_vid, 4));
pred_vid_ca_signal = zeros(size(cell_struct,2), size(pred_vid, 4));
medfilt_vid_ca_signal = zeros(size(cell_struct,2), size(pred_vid, 4));
gaussfilt_vid_ca_signal = zeros(size(cell_struct,2), size(pred_vid, 4));
for t = 1:size(gt_vid, 4)
    curr_idx = sub2ind(size(gt_vid), round(mu(:, 2)), round(mu(:, 1)), round(mu(:, 3)));
    
    curr_gt_img = gt_vid(:, :, :, t);
    curr_gt_vid_ca_signal = curr_gt_img(curr_idx);
    gt_vid_ca_signal(:, t) = curr_gt_vid_ca_signal;
    
    curr_noisy_img = noisy_vid(:, :, :, t);
    curr_noisy_vid_ca_signal = curr_noisy_img(curr_idx);
    noisy_vid_ca_signal(:, t) = curr_noisy_vid_ca_signal;
    
    curr_pred_img = pred_vid(:, :, :, t);
    curr_pred_vid_ca_signal = curr_pred_img(curr_idx);
    pred_vid_ca_signal(:, t) = curr_pred_vid_ca_signal;
    
    curr_medfilt_img = noisy_vid(:, :, :, t);
    for z = 1:size(curr_medfilt_img,3)
        curr_medfilt_img(:, :, z) = medfilt2(curr_medfilt_img(:, :, z));
    end
    medfilt_vid_ca_signal(:, t) = curr_medfilt_img(curr_idx);
    
    curr_gaussfilt_img = noisy_vid(:, :, :, t);
    for z = 1:size(curr_gaussfilt_img,3)
        curr_gaussfilt_img(:, :, z) = imgaussfilt(curr_gaussfilt_img(:, :, z), 1);
    end
    gaussfilt_vid_ca_signal(:, t) = curr_gaussfilt_img(curr_idx);
end



for i = 1:size(cell_struct,2)
%     figure
%     imshow(max(noisy_vid(:, :, :, 1), [], 3), [])
%     hold on
%     scatter(mu(i, 1), mu(i, 2), '.r')
%     
%     figure
%     imshow(max(pred_vid(:, :, :, 1), [], 3), [])
%     hold on
%     scatter(mu(i, 1), mu(i, 2), '.r')
    y_lim_min = min(noisy_vid_ca_signal(i, :)) - 3;
    y_lim_max = max(noisy_vid_ca_signal(i, :)) + 3;
    
    figure, 
    subplot(3,2,1), plot(gt_ca_signal(i, :), 'w'), title('zimmer video', 'color', 'w'), set(gcf,'color','k'), set(gca, 'color', 'k', 'XColor', [1,1,1], 'YColor', [1,1,1])
    subplot(3,2,3), plot(gt_vid_ca_signal(i, :), 'color', [1, 0.3, 0.3]), ylim([y_lim_min, y_lim_max]), title('gt video', 'color', 'w'), set(gcf,'color','k'), set(gca, 'color', 'k', 'XColor', [1,1,1], 'YColor', [1,1,1])
    subplot(3,2,5), plot(noisy_vid_ca_signal(i, :), 'color', [0.3, 0.3, 1]), hold on, plot(gt_vid_ca_signal(i, :), 'color', [1, 0.3, 0.3]), ylim([y_lim_min, y_lim_max]), title('noisy video', 'color', 'w'), set(gcf,'color','k'), set(gca, 'color', 'k', 'XColor', [1,1,1], 'YColor', [1,1,1])
    subplot(3,2,2), plot(pred_vid_ca_signal(i, :), 'c'), hold on, plot(gt_vid_ca_signal(i, :), 'color', [1, 0.3, 0.3]), ylim([y_lim_min, y_lim_max]), title('denoise - cnn', 'color', 'w'), set(gcf,'color','k'), set(gca, 'color', 'k', 'XColor', [1,1,1], 'YColor', [1,1,1])
    subplot(3,2,4), plot(medfilt_vid_ca_signal(i, :), 'c'), hold on, plot(gt_vid_ca_signal(i, :), 'color', [1, 0.3, 0.3]), ylim([y_lim_min, y_lim_max]), title('denoise - median filter', 'color', 'w'), set(gcf,'color','k'), set(gca, 'color', 'k', 'XColor', [1,1,1], 'YColor', [1,1,1])
    subplot(3,2,6), plot(gaussfilt_vid_ca_signal(i, :), 'c'), hold on, plot(gt_vid_ca_signal(i, :), 'color', [1, 0.3, 0.3]), ylim([y_lim_min, y_lim_max]), title('denoise - gaussian filter', 'color', 'w'), set(gcf,'color','k'), set(gca, 'color', 'k', 'XColor', [1,1,1], 'YColor', [1,1,1])
    set(gcf, 'InvertHardCopy', 'off');
%     figure,
%     hold on
% %     plot(pred_vid_ca_signal(i, :) - mean(pred_vid_ca_signal(i, :)), 'g')
%     plot(gaussfilt_vid_ca_signal(i, :) - mean(gaussfilt_vid_ca_signal(i, :)), 'b')
%     plot(gt_vid_ca_signal(i, :) - mean(gt_vid_ca_signal(i, :)), 'r')
end

%%% accuracy
accuract_noisy_vid = sum(abs(noisy_vid_ca_signal - gt_vid_ca_signal),2)/size(noisy_vid_ca_signal,2);
accuract_pred_vid = sum(abs(pred_vid_ca_signal - gt_vid_ca_signal),2)/size(noisy_vid_ca_signal,2);
accuract_medfilt_vid = sum(abs(medfilt_vid_ca_signal - gt_vid_ca_signal),2)/size(noisy_vid_ca_signal,2);
accuract_gaussfilt_vid = sum(abs(gaussfilt_vid_ca_signal - gt_vid_ca_signal),2)/size(noisy_vid_ca_signal,2);
figure, boxplot([accuract_noisy_vid, accuract_pred_vid, accuract_medfilt_vid, accuract_gaussfilt_vid])


%%% normalized trace accuracy
gt_vid_ca_signal_n = gt_vid_ca_signal - repmat(mean(gt_vid_ca_signal, 2), 1, size(gt_vid_ca_signal, 2));
noisy_vid_ca_signal_n = noisy_vid_ca_signal - repmat(mean(noisy_vid_ca_signal, 2), 1, size(noisy_vid_ca_signal, 2));
pred_vid_ca_signal_n = pred_vid_ca_signal - repmat(mean(pred_vid_ca_signal, 2), 1, size(pred_vid_ca_signal, 2));
medfilt_vid_ca_signal_n = medfilt_vid_ca_signal - repmat(mean(medfilt_vid_ca_signal, 2), 1, size(medfilt_vid_ca_signal, 2));
gaussfilt_vid_ca_signal_n = gaussfilt_vid_ca_signal - repmat(mean(gaussfilt_vid_ca_signal, 2), 1, size(gaussfilt_vid_ca_signal, 2));

accuract_noisy_vid = sum(abs(noisy_vid_ca_signal_n - gt_vid_ca_signal_n),2)/size(noisy_vid_ca_signal_n,2);
accuract_pred_vid = sum(abs(pred_vid_ca_signal_n - gt_vid_ca_signal_n),2)/size(noisy_vid_ca_signal_n,2);
accuract_medfilt_vid = sum(abs(medfilt_vid_ca_signal_n - gt_vid_ca_signal_n),2)/size(noisy_vid_ca_signal_n,2);
accuract_gaussfilt_vid = sum(abs(gaussfilt_vid_ca_signal_n - gt_vid_ca_signal_n),2)/size(noisy_vid_ca_signal_n,2);
figure, boxplot([accuract_noisy_vid, accuract_pred_vid, accuract_medfilt_vid, accuract_gaussfilt_vid])
