#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-o2560-1N-0ens-trans-2048c-4gpm-1B-bf16exp
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

train_end_yyyymmdd="20230929"
val_start_yyyymmdd="20230930"
val_end_yyyymmdd="20230930"

num_channels=2048
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus_per_model=4
ens_size=0
res=o2560
hydra_args="data=zarr_no_insolation"

dataset=4km-2years.zarr

mapper_chunks=32 #32 for 1N, 16 for 2N
proc_chunks=8 #8 for 1N, 4 for 2N
num_workers=4 #6 for 2N, 4 for 1N

export CUDA_VISIBLE_DEVICES=0,1,2,3
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export ANEMOI_BASE_SEED=42
export CLONED_DATASET=1

jobid=$$
jobname=$SLURM_JOB_NAME

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=200 --val-batch-limit=0 --max-epochs=1 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=$num_workers \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --model="transformer" --hidden-res="o256"  --ens=$ens_size \
    --num-mapper-chunks=$mapper_chunks --num-processor-chunks=$proc_chunks \
    --hydra-args="$hydra_args" "$@"

exit $?
