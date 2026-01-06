%%% function to read OM results file generated on PACE

input_dir = 'D:\Shivesh\OptimalTransport\tracking\Results\OM_sequential';

results = [];
method = {};
file_list = dir(input_dir);
for i = 1:size(file_list,1)
    curr_name = file_list(i).name;
    if and(~strcmp(curr_name, '.'), ~strcmp(curr_name, '..'))
        underscore_index = strfind(curr_name,'_');
        
        curr_method = curr_name(1,underscore_index(1,1)+1:underscore_index(1,2)-1);
        method = cat(1,method,curr_method);
        
        avg_precision = num2str(curr_name(1,underscore_index(1,2)+1:underscore_index(1,3)-1));
        avg_recall = num2str(curr_name(1,underscore_index(1,3)+1:underscore_index(1,4)-1));
        
        load_results = load([input_dir,'\',curr_name]);
        if strcmp(curr_method,'SM')
            var_name = 'SM';
        elseif strcmp(curr_method,'SMIPFP')
            var_name = 'SM_IPFP';
        elseif strcmp(curr_method,'IPFPgm')
            var_name = 'IPFP_gm';
        elseif strcmp(curr_method,'IPFP')
            var_name = 'IPFP';
        elseif strcmp(curr_method,'IPFPmap')
            var_name = 'IPFP_MAP';
        elseif strcmp(curr_method,'L2QPMAP')
            var_name = 'L2QP_MAP';
        elseif strcmp(curr_method,'PSM')
            var_name = 'PSM';
        elseif strcmp(curr_method,'PHM')
            var_name = 'PHM';
        elseif strcmp(curr_method,'SMAC')
            var_name = 'SMAC';
        elseif strcmp(curr_method,'IPFPU')
            var_name = 'IPFPU';
        elseif strcmp(curr_method,'IPFPS')
            var_name = 'IPFPS';
        elseif strcmp(curr_method,'RRWM')
            var_name = 'RRWM';
        
        elseif strcmp(curr_method,'CPD')
            var_name = 'CPD';
        elseif strcmp(curr_method,'GLMD')
            var_name = 'GLMD';
        elseif strcmp(curr_method,'GLTP')
            var_name = 'GLTP';
        elseif strcmp(curr_method,'GMMReg')
            var_name = 'GMMReg';
        elseif strcmp(curr_method,'TPSRPM')
            var_name = 'TPSRPM';
        elseif strcmp(curr_method,'ECMPR')
            var_name = 'ECMPR';
        end
        
        curr_var = ['results_',var_name];
        results = [results;load_results.(curr_var)];
    end
end