#!/bin/bash
qsub -vBATCHSIZE=1,BATCHNUM=0 paralleljob_CNMF_poisson_data_50_0.1.pbs
qsub -vBATCHSIZE=1,BATCHNUM=1 paralleljob_CNMF_poisson_data_50_0.1.pbs
