#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-hero-bs16
#SBATCH --nodes=128
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --gres=gpu:4
#SBATCH --hint=nomultithread
#SBATCH --exclusive
#SBATCH --account=jureap129
#SBATCH --time=4:00:00
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

num_channels=2048
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus_per_model=8
ens_size=4

#4 ens members * 8 gpus per model = 32 gpus per model instance
res=o2560
hydra_args="data=zarr_no_insolation"

dataset=cloned-o2560-2years.zarr

mapper_chunks=16
proc_chunks=4

export CUDA_VISIBLE_DEVICES=0,1,2,3
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

jobid=$$
jobname=$SLURM_JOB_NAME

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=180 --val-batch-limit=0 --max-epochs=5 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=4 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --model="transformer" --hidden-res='o256' --ens=$ens_size \
    --num-mapper-chunks=$mapper_chunks --num-processor-chunks=$proc_chunks \
    --hydra-args="$hydra_args" "$@"

exit $?
