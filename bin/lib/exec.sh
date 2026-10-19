# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

# Hooks to run AIFS-RAPS with a container or another non-host environment.
# Sourced by bin/train and bin/inf. The values are split on white space, like
# a command line; quotes inside the values are not supported.
#
#   AIFS_EXEC        Prefix for the benchmark command, inside srun,
#                    e.g. 'apptainer exec --nv --bind /scratch image.sif'
#   AIFS_TOOL_EXEC   Prefix for the helper steps outside srun (config check,
#                    pip freeze, jobinfo, ...). Default: $AIFS_EXEC
#   AIFS_SRUN_ARGS   Extra srun options, e.g. '--container-image=image.sqsh'

read -r -a run_exec <<< "${AIFS_EXEC:-}"
if [[ -n ${AIFS_TOOL_EXEC+set} ]]; then
    read -r -a tool_exec <<< "$AIFS_TOOL_EXEC"
else
    tool_exec=("${run_exec[@]}")
fi
read -r -a srun_args <<< "${AIFS_SRUN_ARGS:-}"

# Run a helper command in the benchmark environment
function in_env
{
    "${tool_exec[@]}" "$@"
}

# Stop if a command is not available in the benchmark environment
function require_cmd
{
    if ! in_env sh -c "command -v $1" > /dev/null 2>&1; then
        if [[ ${#tool_exec[@]} -gt 0 ]]; then
            echo "$cmd: (Error) '$1' not found with AIFS_TOOL_EXEC='${tool_exec[*]}'" >&2
        else
            echo "$cmd: (Error) '$1' not found. Activate your python environment first, or set AIFS_EXEC" >&2
        fi
        exit 1
    fi
}
