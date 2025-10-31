#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-inf-1N-4g-30hr-parOut-1wpg
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --mem=0
#SBATCH --gres=gpu:4
#SBATCH --hint=nomultithread
#SBATCH --time=1:00:00
#SBATCH -o %x-%j.out

pwd
printenv | fgrep SLURM

cloned=0

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

lead_time=360

jobid=$$
jobname=inf_bm

export ANEMOI_BASE_SEED=42
date=20230905 #just need to set date when using a zarr file

res=o2560
if [[ $res == "o2560" ]]; then
checkpoint=.../1N_4gpm_transformer_2048c_o2560_o256_1r_0e.jobname-83024/inference-last.ckpt #raps-dev 8/10 no DF
input=$AIFS_DATA_PATH/aifs-rd-an-lwda-ifc3-mars-o2560-2023-2023-6h-v3-1week.zarr
fi

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export DETERMINISTIC=0 #if 1, sets on torch.deter and enforces cublas deter

devices=4
mc=32
pc=16

output=" --parallel-output -w 1"
#output=" --parallel-output"
#output="" #output happens from device 0 only
#output=" --no-output"

$RAPS_AIFS_ROOT_DIR/bin/inf -j "$jobid" -J "$jobname" -I $input --checkpoint=$checkpoint --lead-time=$lead_time -D $devices --mapper-chunks=$mc --processor-chunks=$pc -d "$date" --profile $output --launcher="srun" -O "/dev/null"

