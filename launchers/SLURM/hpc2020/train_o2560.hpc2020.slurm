#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-o2560-o256-124c-transformer
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:4
#SBATCH --gpus-per-node=4
#SBATCH --mem=0
#SBATCH --qos=dg
#SBATCH --exclude=ac6-320
#SBATCH --time=0:30:00
#SBATCH -o %x-%j.out

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

train_end_yyyymmdd=20230906
val_start_yyyymmdd=20230907
val_end_yyyymmdd=20230907

num_channels=124
num_nodes=$SLURM_NNODES
num_gpus=$SLURM_NTASKS
num_gpus_per_model=$SLURM_NTASKS
res=o2560
hydra_args="data=zarr_no_insolation"
dataset=aifs-rd-an-lwda-ifc3-mars-o2560-2023-2023-6h-v3-1week.zarr

jobid=$$
jobname=$SLURM_JOB_NAME
host=${RAPS_SYSTEM:-""}

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export FAKE_IO=0

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --max-epochs=1 --train-batch-limit=10 --val-batch-limit=0 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=6 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --model='transformer' --nsys \
    --dataset="$dataset" --launcher="srun" --res="$res" -h "o256" \
    --num-mapper-chunks=16 --num-processor-chunks=4 \
    --hydra-args="$hydra_args" "$@"

exit $?
