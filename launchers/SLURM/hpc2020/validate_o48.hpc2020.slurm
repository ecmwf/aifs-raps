#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-o48-validation
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:4
#SBATCH --gpus-per-node=4
#SBATCH --qos=ng
#SBATCH --mem=0
#SBATCH --time=2:00:00
#SBATCH -o %x-%j.out

#This is a low resolution run which is used to check program correctness
#It runs for a fixed number of steps (10 epochs of 1000 training steps)
#It runs with model size 2 and ens size 2, so that these code paths are tested
#It runs with a fixed seed
#The final validation loss will be used to compare correctness, within a threshold

cd $SLURM_SUBMIT_DIR
pwd
printenv | fgrep SLURM


set -eu

source ../../../.aifsenv

set -x
printenv

export ANEMOI_BASE_SEED=42

train_end_yyyymmdd=202010
val_start_yyyymmdd=202011
val_end_yyyymmdd=202012

num_channels=$((1024))
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus_per_model=2
ens_size=2
res=o48

dataset=aifs-ea-an-oper-0001-mars-o48-1979-2022-6h-v6.zarr

jobid=$$
jobname=aifs_n320
host=${RAPS_SYSTEM:-""}

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export FAKE_IO=1

$RAPS_AIFS_ROOT_DIR/bin/train \
    -j "$jobid" -J "$jobname" \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=1000 --val-batch-limit=100 --max-epochs=10 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=8 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" --num-mapper-chunks=1 --num-processor-chunks=2 \
    --model="transformer" -h "o32" \
    --dataset="$dataset" --launcher="srun" --res="$res" "$@"

exit $?
