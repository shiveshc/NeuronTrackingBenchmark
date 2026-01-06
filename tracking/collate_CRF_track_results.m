%%% function to collate CRF track run results

inp_dir = 'D:\Shivesh\OptimalTransport\tracking\Results\gw_eot_alltorand';
file_list = dir(inp_dir);
summary = [];
for i = 1:size(file_list,1)
    if ~isdir([inp_dir,'\',file_list(i).name])
        curr_name = file_list(i).name;
        load([inp_dir,'\',curr_name])
        
        summary = [summary;results];
    end
end
        
        