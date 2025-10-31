#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-throughput-o800-GT-1024c-h7-4N-1gpm-16bs-8mc
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:4
#SBATCH --mem=0
#SBATCH --hint=nomultithread
#SBATCH --time=6:00:00
#SBATCH --qos=ng
#SBATCH -o outputs/%x-%j.out

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
#num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus=16
num_gpus_per_model=1
ens_size=0
res=o800
hydra_args="model.recompile_limit=32"

dataset=aifs-o800-10years-cloned.zarr
export CLONED_DATASET=1

export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

jobid=$$
jobname=throughput

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=null --val-batch-limit=0 --max-epochs=2 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=4 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --model="graphtransformer" --hidden-res="7" -J $jobname \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --num-mapper-chunks=8 --num-processor-chunks=8 \
    --hydra-args="$hydra_args" "$@"

exit $?
