#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-o1280
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --gres=gpu:4
#SBATCH --hint=nomultithread
#SBATCH --exclusive
#SBATCH -p booster
#SBATCH --account=jureap129
#SBATCH --time=1:00:00
#SBATCH -o %x-%j.out

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

train_end_yyyymmdd=20230124
val_start_yyyymmdd=20230125
val_end_yyyymmdd=20230125

num_channels=1024
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus_per_model=2
res=o1280
hydra_args="model.processor.attention_implementation=flash_attention_v3"

dataset=aifs-od-an-oper-0001-mars-o1280-2016-2023-6h-v1.zarr

export CUDA_VISIBLE_DEVICES=0,1,2,3
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

jobid=$$
jobname=$SLURM_JOB_NAME

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=200 --val-batch-limit=20 --max-epochs=1 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=6 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --model="transformer" --hidden-res="o96" \
    --num-mapper-chunks=8 --num-processor-chunks=2 \
    --hydra-args="$hydra_args" "$@"

exit $?
