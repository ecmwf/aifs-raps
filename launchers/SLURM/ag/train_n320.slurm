#!/bin/bash
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

#SBATCH --job-name=aifs-train_n320
#SBATCH --qos=ng
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-task=72
#SBATCH --hint=nomultithread
#SBATCH --time=1:00:00
#SBATCH --output=%x-%j.out

# The repo: $AIFS_RAPS_ROOT, or the git checkout that the job was submitted from.
# (sbatch copies this script, so its own path does not give the repo.)
root_dir=${AIFS_RAPS_ROOT:-$(git -C $SLURM_SUBMIT_DIR rev-parse --show-toplevel 2>/dev/null || :)}
if [[ ! -x ${root_dir:-}/bin/train ]]; then
    echo "Cannot find the AIFS-RAPS repo. Set AIFS_RAPS_ROOT, or submit the job from inside the repo" >&2
    exit 1
fi
cd $SLURM_SUBMIT_DIR

source ${AIFS_ENV:-$root_dir/env/ecmwf-ag.sh}
set -eu

# 'sbatch train_n320.slurm -- --dataset=<ds>': the '--' stops sbatch from reading the options
if [[ ${1:-} == "--" ]]; then
    shift
fi

$root_dir/bin/train --config=n320 "$@"
