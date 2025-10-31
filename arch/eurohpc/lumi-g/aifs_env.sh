# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

module load LUMI/24.03 partition/G
module load gnuplot/5.4.10-cpeCray-24.03


# 2. setup_env

export ENV_TYPE='hybrid_container'
export INPUT_HYBRID_CONTAINER_PATH="..."
export INPUT_HYBRID_VENV_PATH="$PROJECT/aifs/venvs/aifs-raps"
export INPUT_HYBRID_CONTAINER_EXTRA_BINDS="..."
export INPUT_HYBRID_CONTAINER_INIT_CMD='source /opt/miniconda3/bin/activate pytorch' # an optional command which is run each time you enter the container

# 3. running
export AIFS_DATA_PATH=$SCRATCH/$(user)/aifs/inputs
export AIFS_OUTPUT_PATH=$SCRATCH/$(user)aifs/outputs/raps
export AIFS_NUM_GPUS_PER_NODE=8
