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
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:4
#SBATCH --mem=0
#SBATCH --time=0:30:00
#SBATCH --partition=boost_usr_prod
#SBATCH --qos=boost_qos_dbg
#SBATCH --account DestE_340_25
#SBATCH -o %x-%j.out

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

train_end_yyyymmdd=20230120
val_start_yyyymmdd=20230121
val_end_yyyymmdd=20230125

num_channels=1024
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES)) #WIP assumes all gpus per node are being used
num_gpus_per_model=4
res=o1280

dataset=aifs-od-an-oper-0001-mars-o1280-2023-2023-6h-v1-one-month.zarr

jobid=$$
jobname=$SLURM_JOB_NAME
host=${RAPS_SYSTEM:-""}

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

$RAPS_AIFS_ROOT_DIR/bin/train \
    -j "$jobid" -J "$jobname" \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=200 --val-batch-limit=20 --max-epochs=1 \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=8 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --num-mapper-chunks=16 --num-processor-chunks=4 \
    --dataset="$dataset" --launcher="srun" --res="$res" "$@"

exit $?
