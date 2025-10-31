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
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=20
#SBATCH --gpus-per-node=4
#SBATCH --exclusive
#SBATCH --time=1:00:00
#SBATCH -p acc
#SBATCH -A ehpc01
#SBATCH --qos=acc_ehpc
#SBATCH -o %x-%j.out

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

train_end_yyyymmdd=20230121
val_start_yyyymmdd=20230122
val_end_yyyymmdd=20230125

num_channels=1024
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES)) #WIP assumes all gpus per node are being used
num_gpus_per_model=16
res=o1280
hydra_args=""

dataset=aifs-od-an-oper-0001-mars-o1280-2023-2023-6h-v1-one-month.zarr

jobid=$$
jobname=$SLURM_JOB_NAME
host=${RAPS_SYSTEM:-""}

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=100 --val-batch-limit=20 --max-epochs=2 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=4 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --hydra-args="$hydra_args" "$@"

exit $?
