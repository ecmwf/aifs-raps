#!/bin/bash
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

# Inference benchmark. The model is sharded over all GPUs of the job
# (runner: parallel). Give the checkpoint and other bin/inf options after '--'.
# The '--' stops sbatch from reading the bin/inf options:
#   sbatch inf.slurm -- --checkpoint=/path/to/inference-last.ckpt --writers=4

#SBATCH --job-name=aifs-inf
#SBATCH --qos=ng
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-task=72
#SBATCH --hint=nomultithread
#SBATCH --time=1:00:00
#SBATCH --output=%x-%j.out

cd $SLURM_SUBMIT_DIR
root_dir=$(git rev-parse --show-toplevel)

source ${AIFS_ENV:-$root_dir/env/ecmwf-ag.sh}
set -eu

if [[ ${1:-} == "--" ]]; then
    shift
fi

$root_dir/bin/inf "$@"
