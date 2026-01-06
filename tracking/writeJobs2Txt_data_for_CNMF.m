function writeJobs2Txt_data_for_CNMF( myfunction, input_speckle_noise, input_background_int )
%writeJobs2Txt writes all matlab function calls to a text file called 'jobs.txt'
%that can be used to submit jobs to PACE
%   myfunction: the name of the function to be called on pace as a string
%   inputs: inputs to the function myfunction as a cell (only one input
%   expected here)

%%% compile list of parameter values already run on PACE. Use this list to
%%% update jobs.txt to run again on PACE

%%%% get rng_fix_parameter values that have already been run and number of
%%%% simulations that have been run for them

%%%% Inputs - 1. data names as 'data' cell array
%%%%          2. 'inputs' 1-by-2 array specifying number of landmarks and numLabelRemove 
%%%%          3. CRF function name

for p = 1:size(input_speckle_noise,2)
    for r = 1:size(input_background_int,2)
        inp_dir = ['D:\Shivesh\OptimalTransport\tracking\data_for_C\'];
        fileList = dir(inp_dir);
        sim_number = [];
        for i = 1:size(fileList,1)
            name = fileList(i).name;
            if and(~strcmp('.',name), ~strcmp('..',name))
                underscore_pos = strfind(name,'_');
                current_speckle_noise = str2num(name(1,underscore_pos(1,1)+1:underscore_pos(1,2)-1));
                current_background_int = str2num(name(1,underscore_pos(1,2)+1:underscore_pos(1,end)-1));
                if and(current_speckle_noise == input_speckle_noise(1,p), current_background_int == input_background_int(1,r))
                    sim_number = [sim_number;str2num(name(1,underscore_pos(1,end)+1:size(name,2)))];
                end
            end
        end
        

        file = fopen(['jobs_CNMF_data_',num2str(input_speckle_noise(1,p)),'_',num2str(input_background_int(1,r)),'.txt'],'w');
        total_jobs = 0;
        cnt = 0;
        if isempty(sim_number)
            begin = 2;
        else
            begin = max(sim_number)+1;
        end
        for k = begin:5 % 100 repeats for each fixed random selected landmarks
            call = ['matlab -nodisplay -singleCompThread -r ', '"', myfunction, '(', num2str(input_speckle_noise(1,p)), ',',num2str(input_background_int(1,r)),',',num2str(k), ')"'];
            %'\r' is only needed if reading the file with microsoft notepad:
            %fprintf(file, '%s\r\n', call);
            % the following should be fine for any linux systems:
            fprintf(file, '%s\n', call);
            total_jobs = total_jobs + 1;
        end
        fclose(file);
    
    
        %%%% write batch process file from the same function
        num_batches = 4;
        batch_size = floor(total_jobs/num_batches);
        file = fopen(['batch_process_CNMF_data_',num2str(input_speckle_noise(1,p)),'_',num2str(input_background_int(1,r)),'.sh'], 'w');
        fprintf(file, '#!/bin/bash\n');

        for i = 1: num_batches - 1
                call = ['qsub -vBATCHSIZE=',num2str(batch_size), ',BATCHNUM=',num2str(i-1),[' paralleljob_CNMF_data_',num2str(input_speckle_noise(1,p)),'_',num2str(input_background_int(1,r)),'.pbs']];
                %'\r' is only needed if reading the file with microsoft notepad:
                %fprintf(file, '%s\r\n', call);
                % the following should be fine for any linux systems:
                fprintf(file, '%s\n', call);
        end
        remaining_jobs = total_jobs - batch_size*(num_batches - 1);
        call = ['qsub -vBATCHSIZE=',num2str(remaining_jobs), ',BATCHNUM=',num2str(i),[' paralleljob_CNMF_data_',num2str(input_speckle_noise(1,p)),'_',num2str(input_background_int(1,r)),'.pbs']];
        fprintf(file, '%s\n', call);
        fclose(file);
        
        
        %%%% write paralleljob file
        file = fopen(['paralleljob_CNMF_data_',num2str(input_speckle_noise(1,p)),'_',num2str(input_background_int(1,r)),'.pbs'], 'w');
        N = [num2str(input_speckle_noise(1,p)),'_',num2str(input_background_int(1,r)),'_CNMF_data'];
        account = 'GT-hl94-joe';
        q = 'inferno';
        walltime = '24:00:00';
        JOBFILE = ['jobs_CNMF_data_',num2str(input_speckle_noise(1,p)),'_',num2str(input_background_int(1,r)),'.txt'];
        
        fprintf(file, ['#PBS -N ',N,'\n']);
        fprintf(file, ['#PBS -A ',account,'\n']);
        fprintf(file, ['#PBS -q ',q,'\n']);
        fprintf(file, ['#PBS -l walltime=',walltime,'\n']);
        fprintf(file, '#PBS -l nodes=1:ppn=4\n');
        fprintf(file, '#PBS -j oe\n');
        fprintf(file, '#PBS -o parameter_search.$PBS_JOBID\n\n');
        fprintf(file, 'cd $PBS_O_WORKDIR\nmodule load matlab/r2019a\nNP=$(wc -l < $PBS_NODEFILE)\n\n#JOBFILE, BATCHSIZE, and BATCHNUM should be set in the environment\n#If they are not, use some defaults.\n# By setting BATCHSIZE to a default of the length of the jobfile we only require one of these jobs.\n# The user can submit multiple jobs and split up the batchcount to work on multiple nodes.\n');
        fprintf(file, ['JOBFILE=${JOBFILE:-',JOBFILE,'}\n\n']);
        fprintf(file, 'if [ ! -f $JOBFILE ]; then echo "File $JOBFILE does not exist. Exiting"; exit 0; fi\n\n');
        fprintf(file, 'BATCHSIZE=${BATCHSIZE:-$(wc -l < $JOBFILE)}\nBATCHNUM=${BATCHNUM:-0}\n\n');
        fprintf(file, 'JOBCOUNT=$(wc -l < $JOBFILE)\n\n');
        fprintf(file, 'ENDLINE=$(($BATCHSIZE*$BATCHNUM + $BATCHSIZE))\n\n');
        fprintf(file, 'if [ $ENDLINE -gt $JOBCOUNT ]\nthen\n\n');
        fprintf(file, '  if [ $(($ENDLINE-$BATCHSIZE)) -gt $JOBCOUNT ]\n  then\n    echo "Given \\"BATCHNUM\\" is greater than the number of possible batches. Exiting..."\n    exit 0\n  fi\n\n');
        fprintf(file, '  DIFFERENCE=$(($ENDLINE-$JOBCOUNT))\n  REMAININGJOBCOUNT=$(($BATCHSIZE-$DIFFERENCE))\n\n');
        fprintf(file, 'fi\n\n');
        fprintf(file, 'BATCHSIZE=${REMAININGJOBCOUNT:-$BATCHSIZE}\n\n');
        fprintf(file, 'module load parallel\n');
%         fprintf(file, 'head -n $ENDLINE $JOBFILE | tail -n $BATCHSIZE | /usr/local/pacerepov1/gnuparallel/20110822/bin/parallel -j $NP -k \n\n');
        fprintf(file, 'head -n $ENDLINE $JOBFILE | tail -n $BATCHSIZE | parallel -j $NP -k \n\n');
        fclose(file);
    end
end

