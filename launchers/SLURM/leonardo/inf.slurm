#!/bin/bash --login
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.


#SBATCH --job-name=aifs-inf
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:4
#SBATCH --mem=0
#SBATCH --time=0:20:00
#SBATCH --partition=boost_usr_prod
#SBATCH --qos boost_qos_dbg
#SBATCH --account DestE_340_24
#SBATCH -o %x-%j.out

cd $(dirname "$1")
pwd
source .ifsenv
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
set -eux

input=".../aifs_n320_input.grib"
model=" --rundir $OUTROOT/train/1N_1gpn_transformer_128c_n320.aifs_n320-2478785"

MASTER_ADDR=$(scontrol show hostname $SLURM_NODELIST | head -n 1)
export MASTER_ADDR=$(nslookup $MASTER_ADDR | grep -oP '(?<=Address: ).*')

# Port for communication (choose a random port in the range 10000-20000)
export MASTER_PORT=$((10000 + RANDOM % 10000))

# Total number of tasks (processes)
export WORLD_SIZE=$SLURM_NTASKS

echo "MASTER_ADDR: $MASTER_ADDR"
echo "MASTER_PORT: $MASTER_PORT"
echo "WORLD_SIZE: $WORLD_SIZE"

lead_time=240

jobid=$$
jobname=parallel_inf

$RAPS_AIFS_ROOT_DIR/bin/inf -j "$jobid" -J "$jobname" $model \
	--lead-time=$lead_time --no-output --input-path $input --launcher="srun" "$@"

exit $?
