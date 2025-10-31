#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-inf-o2560-1N-seqIO-32mc-8pc-noOutput
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=72
#SBATCH --gres=gpu:4
#SBATCH --hint=nomultithread
#SBATCH --exclusive
#SBATCH -p booster
#SBATCH --account=jureap129
#SBATCH --time=1:00:00
#SBATCH -o %x-%j.out

pwd
printenv 

cd $SLURM_SUBMIT_DIR

source ../../../.aifsenv

set -eux

num_chunks_mapper=32
num_chunks_processor=8
lead_time=60 #10 steps

jobid=$$
jobname=aifs_inf

res="o2560"
rundir=$OUTROOT/train/1N_1gpm_transformer_256c_n320_1r.aifs_n320-633061
input=.../n320-inf.grib
model_cmd=" --rundir=$rundir"
if [[ $res == "o1280" ]]; then
rundir=$OUTROOT/train/1N_4gpm_transformer_256c_n1280_1r.aifs_o1280-633061
input=.../aifs-input-o1280-onemonth.grib
model_cmd=" --rundir=$rundir"
elif [[ $res == "o2560" ]]; then
rundir=$OUTROOT/train/8N_8gpm_transformer_1024c_o2560_o256_1r_4e.jobname-1366338
model_cmd=" --rundir=$rundir"
fi

export CUDA_VISIBLE_DEVICES=0,1,2,3

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export DETERMINISTIC=0 #if 1, sets on torch.deter and enforces cublas deter
export PARALLEL_OUT=0
export WRITERS_PER_GPU=0

jobid=$$
jobname=aifs_inf

$RAPS_AIFS_ROOT_DIR/bin/inf  --launcher="srun" -j "$jobid" -J "$jobname" --dummy $model_cmd --lead-time=$lead_time -D 4 --num-mapper-chunks=$num_chunks_mapper --num-processor-chunks=$num_chunks_processor --no-output #--multio -I $input

exit $?
