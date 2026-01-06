function ca_signal = assign_activity_using_experimental_data(cell_struct, Neuron_head, keep_neurons_from_atlas, num_tp_in_video, data_num, run_local)

switch data_num
    case 1
        if run_local
            load('D:\Shivesh\OptimalTransport\tracking\ZimmerPaperData\wbdata\TS20140715e_lite-1_punc-31_NLS3_2eggs_56um_1mMTet_basal_1080s.mat')
        else
           load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/ZimmerPaperData/wbdata/TS20140715e_lite-1_punc-31_NLS3_2eggs_56um_1mMTet_basal_1080s.mat')
        end
    case 2
        if run_local
            load('D:\Shivesh\OptimalTransport\tracking\ZimmerPaperData\wbdata\TS20140715f_lite-1_punc-31_NLS3_3eggs_56um_1mMTet_basal_1080s.mat')
        else
            load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/ZimmerPaperData/wbdata/TS20140715f_lite-1_punc-31_NLS3_3eggs_56um_1mMTet_basal_1080s.mat')
        end
    case 3
        if run_local
            load('D:\Shivesh\OptimalTransport\tracking\ZimmerPaperData\wbdata\TS20140905c_lite-1_punc-31_NLS3_AVHJ_0eggs_1mMTet_basal_1080s.mat')
        else
            load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/ZimmerPaperData/wbdata/TS20140905c_lite-1_punc-31_NLS3_AVHJ_0eggs_1mMTet_basal_1080s.mat')
        end
    case 4
        if run_local
            load('D:\Shivesh\OptimalTransport\tracking\ZimmerPaperData\wbdata\TS20140926d_lite-1_punc-31_NLS3_RIV_2eggs_1mMTet_basal_1080s.mat')
        else
            load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/ZimmerPaperData/wbdata/TS20140926d_lite-1_punc-31_NLS3_RIV_2eggs_1mMTet_basal_1080s.mat')
        end
    case 5
        if run_local
            load('D:\Shivesh\OptimalTransport\tracking\ZimmerPaperData\wbdata\TS20141221b_THK178_lite-1_punc-31_NLS3_6eggs_1mMTet_basal_1080s.mat')
        else
            load('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/OptimalTransport/ZimmerPaperData/wbdata/TS20141221b_THK178_lite-1_punc-31_NLS3_6eggs_1mMTet_basal_1080s.mat')
        end
end

names = wbData.NeuronIds;
data_tps = size(wbData.deltaFOverF,1);

ca_signal = zeros(size(cell_struct,2),data_tps);
assigned_in_cell_struct = [];
used_in_data = [];
for n = 1:size(names,2)
    name_flag = 0;
    curr_name = names{1,n};
    if isempty(curr_name)
    elseif iscell(curr_name)
        curr_name = curr_name{1,1};
        name_flag = 1;
    else
        name_flag = 1;
    end
    if name_flag
        idx_in_Neuron_head = find(strcmp(Neuron_head,curr_name));
        if ismember(idx_in_Neuron_head, keep_neurons_from_atlas)
            idx_in_cell_struct = find(idx_in_Neuron_head == keep_neurons_from_atlas);
            ca_signal(idx_in_cell_struct,:) = wbData.deltaFOverF(:,n);
            assigned_in_cell_struct = [assigned_in_cell_struct;idx_in_cell_struct];
            used_in_data = [used_in_data;n];
        end
    end
end

unused_in_data = setdiff([1:1:size(names,2)]', used_in_data);
unassigned_in_cell_struct = setdiff([1:1:size(cell_struct,2)]',assigned_in_cell_struct);
for n = 1:size(unassigned_in_cell_struct,1)
    random_select = unused_in_data(randi(size(unused_in_data,1)),:);
    ca_signal(unassigned_in_cell_struct(n,1),:) = wbData.deltaFOverF(:,random_select);
end

if num_tp_in_video < size(ca_signal,2)
    rand_start = randi(size(ca_signal,2)-num_tp_in_video+1);
    ca_signal = ca_signal(:,rand_start:rand_start+num_tp_in_video-1);
else
end