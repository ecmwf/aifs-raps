#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-inf
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --mem=0
#SBATCH --gres=gpu:4
#SBATCH --hint=nomultithread
#SBATCH --time=1:00:00
#SBATCH -o %x-%j.out


# This script implements a single inference run, with output, as specificed in the ITT documents
# This run has output enabled

# This script launches a single inference run
# To calculate your f_inf score you must launch multiple concurrent runs and measure the throughput achieved

# The 'jobname' variable allows you to tag a set of concurrent runs with the same name
# Once your runs are completed, you can calculate your throughput score using the following commands
# (assuming jobname is 'inf_08122025')
# ./bin/aifs-jobinfo $AIFS_OUTPUT_PATH/train/*inf_08122025* | aifs-calculate-throughput
# The script looks at the start time of the earlier job, and end time of the latest job
# so you should avoid reusing jobnames

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

lead_time=360 #15 days, fixed in benchmark specification

jobid=$$
jobname=inf_bm

export ANEMOI_BASE_SEED=42

# provide a checkpoint file containing a trained model
# You may either train a model and use the resulting checkpoint
# This is recomended as it ensures your training and inference environments match
# any of the 'o2560' reference scripts will work
checkpoint=$training_rundir/inference-last.ckpt
# or you may use the pretrained checkpoint file from the benchmark server

#pretrained checkpoint from the benchmark server
# MUST use pytorch 2.7 to run, due to version-specific model-code in the checkpoint
#checkpoint=itt380-T-o2560-o256-2048c.ckpt 

#As input you should use the o2560 input dataset from the benchmark server
date=20230905 # Selected date to use as initial input
input=$AIFS_DATA_PATH/aifs-rd-an-lwda-ifc3-mars-o2560-2023-2023-6h-v3-1week.zarr

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export DETERMINISTIC=0 #if 1, sets on torch.deter and enforces cublas deter

devices=4 # Free parameter, how many GPUs inference is run over
mc=32 # Free parameter, how many blocks the mapper computation is run over
pc=16 # Free parameter, how many blocks the mapper computation is run over

# How many writer processes each GPU spawns to write output
# output is split along the variable dimension
# ranges from 0 (block IO in main process)
num_writers=1  #free parameter

# you can remove parallel output
# with it, when running over multiple GPUs, output is split across GPUs in the variable dimension

output=" --parallel-output -w $num_writers" # $((num_devices * num_writers)) output files
#output=" -w $num_writers" # $((num_writers)) output files
#output="" # 1 output file
#output="--no-output" # disable output (testing only)

# You may add the '--profile' flag to run with added runtime and memory profiling
# This increases job runtime due to additional work at the end of a job step
# (Note that the timing data reported by aifs-jobinfo does not include the profiling overhead)
profile=""
#profile="--profile"

# Free parameter
# forecast data produced on GPU must be transposed before being written to disk
# With this switch you can control whether this transpose happens on CPU (default) or
# on GPU. It depends on the system which setting is best
export TRANSPOSE_ON_GPU=0

$RAPS_AIFS_ROOT_DIR/bin/inf -j "$jobid" -J "$jobname" -I $input --checkpoint=$checkpoint --lead-time=$lead_time -D $devices --mapper-chunks=$mc --processor-chunks=$pc -d "$date" $output --launcher="srun" $output $profile

