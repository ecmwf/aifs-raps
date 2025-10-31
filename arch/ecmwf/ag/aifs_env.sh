# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

module load python3/3.12.9-01 cuda/12.9   cmake/3.31.6 gcc/15.1.0 nvidia/25.5 #need cmake to build eccodes
export LD_LIBRARY_PATH=$gcc_DIR/lib64/:$LD_LIBRARY_PATH #some Flash Attn versions complain about GLIBC being too old

# 2. setup_env
export ENV_TYPE='venv'
export INPUT_VENV_PATH="$PERM/venvs/aifs-raps-ag"

# 3. running
export AIFS_DATA_PATH="..."
export AIFS_OUTPUT_PATH=$SCRATCH/aifs/outputs/aifs-raps
export AIFS_NUM_GPUS_PER_NODE=4
