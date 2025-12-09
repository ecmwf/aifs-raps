#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-hero-o2560-8N-4ens-8gpm-1B
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --mem=0
#SBATCH --gres=gpu:4
#SBATCH --hint=nomultithread
#SBATCH --time=4:00:00
#SBATCH -o %x-%j.out

# This reference script does a hero training run, but only for a single model instance
# batch size 1 instead of batch size 16, the weak scaling via DDP is removed
# THIS SCRIPT IS FOR TESTING ONLY, for reference benchmark runs refer to train_o2560.itt380.slurm

# Within a model instance, there are 4 ensemble members
# These load the same input data, add a unique random perturbation and all-gather their loss values each step
# Each ensemble member is split across 8 GPUs
# This split is the most communication intensive, with many all-to-alls and all-gathers each step (strong scaling)
# In total, 32 GPUs are used: 1 model instances * 4 ensemble members * 8 gpus per model => 32 GPUs

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

train_end_yyyymmdd="20230929"
val_start_yyyymmdd="20230930"
val_end_yyyymmdd="20230930"

num_channels=2048 #fixed in the benchmark specification
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus_per_model=8 #You can tweak this, strong scaling
ens_size=4 # fixed in the benchmark specification
res=o2560
hydra_args="data=zarr_no_insolation"

dataset=4km-2years.zarr

# The following are free parameters

# compute the mapping between 4km and smaller hidden resolution in chunks,
# More chunks decreases memory use but increases runtime at larger chunk counts (16+)
mapper_chunks=32
# How many processor layers to compute in GPU memory at once
# More chunks decrease memory usage, but limited to the number of heads in model (max(16, gpus_per_model))
proc_chunks=8 
# How many dataloader workers each GPU spawns on the CPU
# More workers increases CPU memory usage but can prevent GPU stalling between iterations
num_workers=4 

export CUDA_VISIBLE_DEVICES=0,1,2,3
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export CLONED_DATASET=1 #Must be set if using a cloned dataset

# for testing purposes ONLY
# set to 1 to fake the dataloading
# can be helpful to determine if the filesystem is bottlenecking your run
# especially when pushing strong scaling via increasing the GPUs per model
export AIFS_FAKE_DATALOADING=0

# limit batches to 180 as this is how many batches a full training run sees
# we split a 2 year dataset, 2920 dates (2*365*4), over 16 model instances
# resulting in ~180 training batches per model
batches_per_epoch=180
max_epochs=2 #fixed in benchmark specificiation

# By default, training runs with the profiler
# This has an associated overhead
# You can disable it by passing the following flag
profile="--no-profile"
#profile="" #to run with the profiler

jobid=$$
jobname=$SLURM_JOB_NAME

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=$batches_per_epoch --val-batch-limit=0 --max-epochs=$max_epochs \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=$num_workers \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --model="transformer" --hidden-res="o256"  --ens=$ens_size  \
    --num-mapper-chunks=$mapper_chunks --num-processor-chunks=$proc_chunks \
    --hydra-args="$hydra_args" $profile "$@"

exit $?
