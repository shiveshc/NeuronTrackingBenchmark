function struct_with_var = add_var_to_struct(orig_struct,varargin)
    
    struct_with_var = orig_struct;
    
    for n = 1:size(varargin,2)
        curr_var = inputname(n+1);
        struct_with_var(1).(curr_var) = varargin{n};
    end
end