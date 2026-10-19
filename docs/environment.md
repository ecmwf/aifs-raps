# Environment

AIFS-RAPS does not install software. You must supply a Python environment. The environment can be on the host or in a container image. For a container, refer to [containers.md](containers.md).

## Requirements

The environment must contain these packages:

| Package | Version |
| --- | --- |
| Python | 3.11 or later |
| PyTorch | 2.5 or later, built for your accelerator |
| anemoi-models | `feat/raps-update-oct26` branch of [anemoi-core](https://github.com/ecmwf/anemoi-core/tree/feat/raps-update-oct26) |
| anemoi-graphs | `feat/raps-update-oct26` branch of anemoi-core |
| anemoi-training | `feat/raps-update-oct26` branch of anemoi-core |
| anemoi-datasets | latest release |
| anemoi-inference | `main` branch of [anemoi-inference](https://github.com/ecmwf/anemoi-inference). Only for inference. |
| anemoi-utils | 0.5.13 or later |
| torch-geometric | 2.8 or later |
| tabulate | any. Only for `bin/train --profile`. The benchmark profiler uses it to write the result tables. |
| pyg-lib | optional, must match your PyTorch and CUDA versions |
| flash-attn | optional |

## Make an environment

Do these steps:

1. Make a virtual environment:

   ```bash
   python3 -m venv $HOME/venvs/aifs-raps
   source $HOME/venvs/aifs-raps/bin/activate
   ```

2. Install PyTorch for your accelerator. Refer to <https://pytorch.org/get-started/locally/>.

3. Install anemoi-core from the `feat/raps-update-oct26` branch:

   ```bash
   git clone --branch feat/raps-update-oct26 https://github.com/ecmwf/anemoi-core.git
   pip install -e anemoi-core/graphs[all] -e anemoi-core/models[all] -e anemoi-core/training[all]
   ```

4. For inference, install anemoi-inference from the `main` branch:

   ```bash
   git clone https://github.com/ecmwf/anemoi-inference.git
   pip install -e anemoi-inference
   ```

5. Make sure that the `anemoi-training` command is available:

   ```bash
   anemoi-training --help
   ```

## Make an environment file

The launchers read an environment file. The file loads modules, activates the Python environment and sets the variables below.

| Variable | Required | Description |
| --- | --- | --- |
| `AIFS_DATA_DIR` | No | Directory that contains the real zarr datasets. Only for real data. Refer to [configs.md](configs.md#input-data). |
| `AIFS_OUTPUT_DIR` | Yes | Directory for the run directories. |
| `AIFS_GRAPH_DIR` | No | Directory for the graph cache. The default is `$AIFS_OUTPUT_DIR/graphs`. |
| `AIFS_GPUS_PER_NODE` | No | Number of GPUs on each node. The default is `$SLURM_GPUS_PER_NODE`, or all visible GPUs. |
| `AIFS_EXEC`, `AIFS_TOOL_EXEC`, `AIFS_SRUN_ARGS` | No | Run the Python steps in a container. Refer to [containers.md](containers.md). |
| `AIFS_RAPS_ROOT` | No | Path of the repo, for the SLURM launchers. The default is the git checkout that you submit the job from. |

Do these steps:

1. Copy the example file:

   ```bash
   cp env/ecmwf-ag.sh env/my-system.sh
   ```

2. Change the module names, the environment path and the directories in `env/my-system.sh`.

3. Set `AIFS_ENV` to the new file before you start a launcher:

   ```bash
   export AIFS_ENV=$PWD/env/my-system.sh
   ```

If you do not set `AIFS_ENV`, the launchers use `env/ecmwf-ag.sh`.

## Known problems

### pyg-lib does not load

**Symptom:** The graph build fails with `ImportError: 'radius' requires 'pyg-lib>=0.6.0'`. A warning before the error shows that `libpyg.so` did not load.

**Cause:** The pyg-lib wheel is for a different CUDA version than PyTorch.

**Remedy:** Do one of these steps:

- Install the pyg-lib wheel that agrees with your PyTorch and CUDA versions.
- Set `ANEMOI_GRAPHS_DISABLE_PYG_LIB=1`. anemoi-graphs then uses scikit-learn. The graph build is slower, but the graph is cached.
