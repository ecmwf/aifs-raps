# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

module load intel impi hdf5 mkl
module load python/3.11.5-gcc
module load sqlite3/3.45.2-gcc #needed for inference

#setup env
export ENV_TYPE='venv'
export INPUT_VENV_PATH="$SCRATCH/venvs/aifs-raps"

#running
export AIFS_DATA_PATH=$SCRATCH/$(user)/datasets
export AIFS_OUTPUT_PATH=$SCRATCH/$(user)/aifs/outputs/raps
export AIFS_NUM_GPUS_PER_NODE=4
