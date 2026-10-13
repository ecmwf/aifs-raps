# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

# Example environment that runs the benchmark in an Apptainer image.
# The image must contain anemoi-training (and anemoi-inference for bin/inf).
# Nothing is activated on the host. See docs/containers.md.

module load apptainer

AIFS_IMAGE=${AIFS_IMAGE:?set AIFS_IMAGE to the .sif file}

export AIFS_OUTPUT_DIR=${AIFS_OUTPUT_DIR:-$SCRATCH/aifs-raps}
export AIFS_GRAPH_DIR=${AIFS_GRAPH_DIR:-$AIFS_OUTPUT_DIR/graphs}
# Optional: only for real datasets
# export AIFS_DATA_DIR=/path/to/datasets

# The container must see the repo, the output directory and (if used) the datasets.
repo=${AIFS_RAPS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}
binds=$repo,$AIFS_OUTPUT_DIR${AIFS_DATA_DIR:+,$AIFS_DATA_DIR}
mkdir -p $AIFS_OUTPUT_DIR
export AIFS_EXEC="apptainer exec --nv --bind $binds $AIFS_IMAGE"
