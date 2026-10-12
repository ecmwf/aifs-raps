#!/bin/bash
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-train_o2560
#SBATCH --qos=ng
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=4
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-task=72
#SBATCH --hint=nomultithread
#SBATCH --time=4:00:00
#SBATCH --output=%x-%j.out

cd $SLURM_SUBMIT_DIR
root_dir=$(git rev-parse --show-toplevel)

source ${AIFS_ENV:-$root_dir/env/ecmwf-ag.sh}
set -eu

$root_dir/bin/train --config=o2560 -- "$@"
