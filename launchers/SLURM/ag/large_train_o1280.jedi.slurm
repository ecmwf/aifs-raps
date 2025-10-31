#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-o1280-trans-2048c-o256-8N-4gpm-8bs
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --gres=gpu:4
#SBATCH --hint=nomultithread
#SBATCH --exclusive
#SBATCH --time=4:00:00
#SBATCH -o %x-%j.out

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

source ../../../.aifsenv

set -eux

train_end_yyyymmdd=20230905
val_start_yyyymmdd=20230906
val_end_yyyymmdd=20230907

num_channels=2048
num_nodes=$SLURM_NNODES
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus_per_model=4
ens_size=0
res=o1280
#hydra_args="data=zarr_no_insolation model.processor.window_size=1140"
hydra_args="data=zarr_no_insolation"

dataset=aifs-od-an-oper-0001-mars-o1280-2016-2023-6h-v1.zarr

export CUDA_VISIBLE_DEVICES=0,1,2,3
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

jobid=$$
jobname=$SLURM_JOB_NAME

    #--train-batch-limit=20 --val-batch-limit=0 --max-epochs=1 --nsys \
    #--train-batch-limit=400 --val-batch-limit=0 --max-epochs=1 \

    #--model="graphtransformer" --hidden-res=7 \
    #--model="transformer" --hidden-res="o96" \
$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=180 --val-batch-limit=0 --max-epochs=5 --ens=$ens_size \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=6 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --model="transformer" --hidden-res="o256" \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --num-mapper-chunks=8 --num-processor-chunks=4 \
    --hydra-args="$hydra_args" "$@"

exit $?
