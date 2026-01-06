%%% note - dimensions of all entries for the field should be same

function return_array = get_fieldvar_from_struct(data_struct, varargin)
    
    var_string = genvarname(varargin);
    for k = 1:size(var_string,2)
        eval([var_string{1,k}, '= [];']);
    end
    
    for n = 1:size(data_struct,2)
        for k = 1:size(var_string,2)
            curr_var = data_struct(n).(var_string{1,k});
            eval([var_string{1,k}, '=[', var_string{1,k}, '; curr_var];'])
        end
    end
    
    return_array = {};
    for k = 1:size(varargin,2)
        return_array{1,k} = eval(var_string{1,k});
    end
    
end
        