#!/bin/bash
qsub -vBATCHSIZE=1,BATCHNUM=0 paralleljob_CNMF_data_0.001_0.1.pbs
qsub -vBATCHSIZE=1,BATCHNUM=1 paralleljob_CNMF_data_0.001_0.1.pbs
qsub -vBATCHSIZE=1,BATCHNUM=2 paralleljob_CNMF_data_0.001_0.1.pbs
qsub -vBATCHSIZE=1,BATCHNUM=3 paralleljob_CNMF_data_0.001_0.1.pbs
