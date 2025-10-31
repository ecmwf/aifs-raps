#!/bin/bash --login
#SBATCH --job-name=aifs-ag-throughput-o800-GT-1024c-h7-1N-1gpm-16bs-2mc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --gres=gpu:4
#SBATCH --hint=nomultithread
#SBATCH --time=4:00:00
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
num_gpus=$((AIFS_NUM_GPUS_PER_NODE * SLURM_NNODES))
num_gpus_per_model=1
ens_size=0
res=o800
hydra_args=""

dataset=aifs-o800-10years-cloned.zarr
export CLONED_DATASET=1

export CUDA_VISIBLE_DEVICES=0,1,2,3
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

jobid=$$
jobname=throughput-ag

$RAPS_AIFS_ROOT_DIR/bin/train \
    --train-end=$train_end_yyyymmdd --val-start=$val_start_yyyymmdd --val-end=$val_end_yyyymmdd \
    --train-batch-limit=0 --val-batch-limit=0 --max-epochs=2 --ens=$ens_size \
    --num-nodes="$num_nodes" --num-gpus="$num_gpus" --num-workers=4 \
    --num-gpus-per-model="$num_gpus_per_model" -C "$num_channels" \
    --dataset="$dataset" --launcher="srun" --res="$res" \
    --model="graphtransformer" --hidden-res=7 \
    --num-mapper-chunks=2 --num-processor-chunks=2 \
    --hydra-args="$hydra_args" "$@"

exit $?
