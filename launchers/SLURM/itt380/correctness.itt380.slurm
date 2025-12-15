#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-correctness
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --gres=gpu:4
#SBATCH --mem=0
#SBATCH --time=1:00:00
#SBATCH -o %x-%j.out

# This script runs a correctness test job, as specificed in the benchmark documentation
# This run must be run over 4 devices, more devices changes the order input data is loaded
# resulting in a different final loss
# The job should be relatively short to run ~10 mins

# Once the job completes you can check if the test has passed by running the command
# ./bin/test-correctness $rundir
# where '%rundir' can be found in the slurm output file of this job

cd $SLURM_SUBMIT_DIR
pwd
printenv | fgrep SLURM

set -eu

source ../../../.aifsenv

set -x
printenv

export ANEMOI_BASE_SEED=42 # FIXED

train_end_yyyymmdd=2020
val_start_yyyymmdd=2021
val_end_yyyymmdd=2021

num_channels=$((256)) # FIXED
num_nodes=$SLURM_NNODES
num_gpus=4 #FIXED
num_gpus_per_model=1
global_batch_size=16 #FIXED
batch_size=$((global_batch_size / num_gpus))
ens_size=0 #FIXED
res=o48

# available from the benchmark server
dataset=aifs-ea-an-oper-0001-mars-o48-1979-2022-6h-v6.zarr

jobid=$$
jobname=aifs_o48_val
host=${RAPS_SYSTEM:-""}

hydra_args="training.max_steps=30000 training.lr.rate=1e-3 training.lr.iterations=30000 training.lr.min=3e-7 model.processor.window_size=256"

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

batch_limit=1000 #fixed
val_batch_limit=100 #fixed
epoch_limit=5 # fixed

$RAPS_AIFS_ROOT_DIR/bin/train \
    -j "$jobid" -J "$jobname" \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=$batch_limit --val-batch-limit=$val_batch_limit --max-epochs=$epoch_limit -B $batch_size \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=8 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" --num-mapper-chunks=4 --num-processor-chunks=8 \
    --model="transformer" -h "o32"  --hydra-args="$hydra_args" $precision \
    --dataset="$dataset" --launcher="srun" --res="$res" --no-profile "$@"
exit $?
