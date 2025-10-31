#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.


#SBATCH --job-name=aifs-n320
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=7
#SBATCH --gpus-per-node=8
#SBATCH --partition=standard-g
#SBATCH --mem=480G
#SBATCH --time=2:00:00
#SBATCH --account=project_465000527
#SBATCH -o %x-%j.out

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

printenv

train_end_yyyymmdd=202010
val_start_yyyymmdd=202011
val_end_yyyymmdd=202012

num_channels=1024
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES)) 
num_gpus_per_model=8
res=n320

dataset=aifs-ea-an-oper-0001-mars-n320-2020-2020-6h-v4.zarr

jobid=$$
jobname=aifs_n320
host=${RAPS_SYSTEM:-""}

c=fe
MYMASKS="0x${c}000000000000,0x${c}00000000000000,0x${c}0000,0x${c}000000,0x${c},0x${c}00,0x${c}00000000,0x${c}0000000000"

export NCCL_IGNORE_CPU_AFFINITY=1
export NCCL_NET_GDR_LEVEL=3
export NCCL_NCHANNELS_PER_PEER=32

$RAPS_AIFS_ROOT_DIR/bin/train \
    -j "$jobid" -J "$jobname" \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=200 --val-batch-limit=20 --max-epochs=5 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=4 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --dataset="$dataset" --launcher="srun --cpu-bind=mask_cpu:$MYMASKS" --res="$res" "$@"

exit $?
