#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-inf-o2560-1N-2048c-multio
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --gres=gpu:4
#SBATCH --hint=nomultithread
#SBATCH --exclusive
#SBATCH --account=jureap129
#SBATCH --time=1:00:00
#SBATCH -o %x-%j.out

pwd
printenv 

cd $SLURM_SUBMIT_DIR

source ../../../.aifsenv

set -eux

num_chunks_mapper=32
num_chunks_processor=8
lead_time=900 #150 steps

jobid=$$
jobname=aifs_inf

res="o2560"
checkpoint=$OUTROOT/train/2N_8gpm_graphtransformer_2048c_o2560_1r_0e.jobname-914909/inference-last.ckpt # my 204c model with csza

export CUDA_VISIBLE_DEVICES=0,1,2,3

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export DETERMINISTIC=0 #if 1, sets on torch.deter and enforces cublas deter
export PARALLEL_OUT=1
export WRITERS_PER_GPU=0

jobid=$$
jobname=aifs_inf

$RAPS_AIFS_ROOT_DIR/bin/inf  --launcher="srun" -j "$jobid" -J "$jobname" --dummy $model_cmd --lead-time=$lead_time -D 4 --num-mapper-chunks=$num_chunks_mapper --num-processor-chunks=$num_chunks_processor --multio

exit $?
