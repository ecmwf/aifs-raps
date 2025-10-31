#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-n320-bf16e
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=64
#SBATCH --gres=gpu:4
#SBATCH --gpus-per-node=4
#SBATCH --mem=0
#SBATCH --time=1:00:00
#SBATCH -o %x-%j.out

#--comment="NVIDIA_POWER_LIMIT=900,900"

cd $SLURM_SUBMIT_DIR
pwd
printenv | fgrep SLURM


set -eu

source ../../../.aifsenv

set -x
printenv

train_end_yyyymmdd=202010
val_start_yyyymmdd=202011
val_end_yyyymmdd=202012

num_channels=512
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus_per_model=2
ens_size=2
res=n320

dataset=aifs-ea-an-oper-0001-mars-n320-2020-2020-6h-v4.zarr

jobid=$$
jobname=$SLURM_JOB_NAME
host=${RAPS_SYSTEM:-""}

export TRITON_CACHE_DIR=$TMPDIR/.triton/cache
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
#hydra_args="dataloader.batch_size.training=8 dataloader.batch_size.validation=8" #example of setting the batch size
hydra_args="data=zarr_no_insolation"

$RAPS_AIFS_ROOT_DIR/bin/train \
    -j "$jobid" -J "$jobname" \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=100 --val-batch-limit=0 --max-epochs=1 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=4 --ens=$ens_size \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" --num-mapper-chunks=4 --num-processor-chunks=2  \
    --dataset="$dataset" --launcher="srun" --res="$res" --hydra-args="$hydra_args" "$@"

exit $?
