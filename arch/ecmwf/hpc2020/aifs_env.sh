# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

module load python3/3.11.10-01
module load nvidia/24.11  #needed to find nsys
module load gcc/12.2.0
export LD_LIBRARY_PATH=$gcc_DIR/lib64/:$LD_LIBRARY_PATH #sometimes Flash Attn complains about GLIBC being too old

#setup env
export ENV_TYPE='venv'
export INPUT_VENV_PATH="$PERM/venvs/aifs-raps"

#running
export AIFS_OUTPUT_PATH=$SCRATCH/aifs/outputs/raps
export AIFS_NUM_GPUS_PER_NODE=4
