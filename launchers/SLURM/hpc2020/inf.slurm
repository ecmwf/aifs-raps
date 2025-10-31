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
#SBATCH --cpus-per-task=32
#SBATCH --gpus-per-node=4
#SBATCH --qos=ng
#SBATCH --mem=0
#SBATCH --time=1:00:00
#SBATCH -o %x-%j.out

pwd
printenv | fgrep SLURM

cd $SLURM_SUBMIT_DIR
pwd

set -eu
source ../../../.aifsenv

set -eux

printenv

#no input given -> mars will be used to retrive data (will only work on hpc2020)
#input="$RAPS_AIFS_ROOT_DIR/aifs_n320_input.grib"

lead_time=30
rundir="$OUTROOT/train/1N_4gpm_transformer_1024c_o1280_1r.jobname-3452104" #o1280
res="o1280"
rundir=$OUTROOT/train/1N_1gpm_transformer_256c_n320_1r.aifs_n320-633061
input=$HPCPERM/raps/n320-inf.grib
if [[ $res == "o1280" ]]; then
rundir=$OUTROOT/train/1N_4gpm_transformer_1024c_o1280_1r.aifs_o1280-843159
input=$HPCPERM/raps/aifs-input-o1280-onemonth.grib
fi

jobid=$$
jobname=aifs_inf

$RAPS_AIFS_ROOT_DIR/bin/inf -j "$jobid" -J "$jobname" --lead-time=$lead_time -I $input --rundir=$rundir --lead-time=120 -D 4 --chunks=8 --multio #--no-output #--multio

exit $?
