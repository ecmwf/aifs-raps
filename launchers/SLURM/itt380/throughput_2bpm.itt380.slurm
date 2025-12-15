#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-o800-2bpm
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --gres=gpu:4
#SBATCH --mem=0
#SBATCH --hint=nomultithread
#SBATCH --time=4:00:00
#SBATCH -o %x-%j.out

# This reference script does a throughput training run, as specified in the ITT document
# It does a single research training run, with batch size 16
# Each model instance runs on a single GPU
# Each model batch size has a local batch size of 2
# for a total of 8 GPUs in use

# The research benchmark tests how many consecutive research experiments can be run concurrently
# Each submission of this script is a single research experiment
# You are free to increase the num_gpus to decrease the walltime of a single experiment
# However, that will decrease how many concurrent experiments you can run

# The 'jobname' variable allows you to tag a set of concurrent runs with the same name
# Once your runs are completed, you can calculate your research throughput score using the following commands
# (assuming jobname is 'throughput_08122025')
# ./bin/aifs-jobinfo $AIFS_OUTPUT_PATH/train/*throughput_08122025* | aifs-calculate-throughput
# The script looks at the start time of the earlier job, and end time of the latest job
# so you should avoid reusing jobnames

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

train_end_yyyymmdd=20231230
val_start_yyyymmdd=20231231
val_end_yyyymmdd=20231231

num_channels=1024  # fixed in benchmark specification
num_nodes=$SLURM_NNODES

BATCH_SIZE=16 # fixed in benchmark specification
num_gpus=16 # free parameter, you can increase this to decrease walltime via strong scaling
num_gpus_per_model=$(( num_gpus / BATCH_SIZE ))
ens_size=0 # fixed in the benchmark specification
res=o800
hydra_args=""

dataset=aifs-o800-10years-cloned.zarr
export CLONED_DATASET=1 # must be set when using a cloned dataset

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

jobid=$$
jobname=throughput_benchmark


# The following are free parameters
# compute the mapping between 4km and smaller hidden resolution in chunks,
# More chunks decreases memory use but increases runtime at larger chunk counts (16+)
mapper_chunks=32
# How many processor layers to compute in GPU memory at once
# More chunks decrease memory usage, but limited to the number of heads in model (max(16, gpus_per_model))
proc_chunks=8
# How many dataloader workers each GPU spawns on the CPU
# More workers increases CPU memory usage but can prevent GPU stalling between iterations
num_workers=6

max_epochs=1 #fixed in benchmark specification
#10 year dataset contains 14,600 dates (10*365*4)
# divided by 16 thats ~900 per model instance
# set it to 900 here to be consistent when testing small batch sizes
batch_limit=900

# By default, training runs with the profiler
# This has an associated overhead
# You can disable it by passing the following flag
profile="--no-profile"
#profile="" #to run with the profiler

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=$batch_limit --val-batch-limit=0 --max-epochs=$max_epochs \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=$num_workers \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --model="graphtransformer" --hidden-res="7" -J $jobname \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --num-mapper-chunks=$mapper_chunks --num-processor-chunks=$proc_chunks \
    --hydra-args="$hydra_args" $profile "$@"

exit $?
