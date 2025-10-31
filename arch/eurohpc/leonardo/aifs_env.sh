# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

module load python/3.11.6--gcc--8.5.0

# 2. setup_env
export ENV_TYPE='venv'
export INPUT_VENV_PATH="$WORK/users/$(user)/venvs/aifs-raps"

# 3. running
export AIFS_DATA_PATH=$WORK/$user/datasets
export AIFS_OUTPUT_PATH=$SCRATCH/aifs/outputs/raps
export AIFS_NUM_GPUS_PER_NODE=4
