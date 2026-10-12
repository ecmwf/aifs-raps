# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

# Example environment for the ECMWF AG cluster (GH200).
# Copy this file and change it for your system. bin/train only needs
# 'anemoi-training' on PATH and the AIFS_* variables below.

module load python3/3.12.9-01 nvidia/25.7

venv_root_path=${venv_root_path:-/perm/naco/venvs}
venv=${venv:-raps-sep26}
source $venv_root_path/$venv/bin/activate

# Input datasets (zarr)
export AIFS_DATA_DIR=${AIFS_DATA_DIR:-/home/mlx/ai-ml/datasets}
# Run directories are made in $AIFS_OUTPUT_DIR/train
export AIFS_OUTPUT_DIR=${AIFS_OUTPUT_DIR:-$SCRATCH/aifs-raps}
# Graphs are cached here and used again by later runs
export AIFS_GRAPH_DIR=${AIFS_GRAPH_DIR:-$AIFS_OUTPUT_DIR/graphs}

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# pyg-lib in this venv is built for CUDA 13 but torch is cu129, so pyg-lib can
# not load. Use the scikit-learn graph builders instead.
export ANEMOI_GRAPHS_DISABLE_PYG_LIB=1
