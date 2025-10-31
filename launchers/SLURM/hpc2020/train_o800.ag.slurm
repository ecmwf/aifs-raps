#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-o800-GT-1024c-h6-1N-1gpm-4bs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:4
#SBATCH --qos=ng
#SBATCH --hint=nomultithread
#SBATCH --time=1:00:00
#SBATCH -o %x-%j.out

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

train_end_yyyymmdd=20231230
val_start_yyyymmdd=20231231
val_end_yyyymmdd=20231231

num_channels=1024
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus_per_model=1
ens_size=0
res=o800
hydra_args=""

dataset=aifs-benchmarking-ea-an-oper-0001-mars-o800-2023-2023-6h-v1.zarr

export CUDA_VISIBLE_DEVICES=0,1,2,3
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

jobid=$$
jobname=$SLURM_JOB_NAME

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=90 --val-batch-limit=0 --max-epochs=5 --ens=$ens_size \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=6 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --model="graphtransformer" --hidden-res="h6" \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --num-mapper-chunks=8 --num-processor-chunks=2 \
    --hydra-args="$hydra_args" "$@"

exit $?
