# Containers

You can run AIFS-RAPS with a container image. The repo stays on the host. The launchers and `bin/train` or `bin/inf` run on the host. They start the Python steps in the container.

## Requirements

The image must contain:

- anemoi-training, anemoi-models and anemoi-graphs from the branch in [environment.md](environment.md).
- anemoi-inference, if you run inference.
- PyYAML. `bin/aifs-jobinfo` uses it.
- A C compiler (`gcc`). Triton compiles a small C module when it starts. The graph transformer kernels and `torch.compile` use Triton. The NVIDIA PyTorch images contain `gcc`. Minimal images, for example `rockylinux:9`, do not contain it.

The host must have SLURM and your container runtime. The host does not need Python.

## Variables

Set these variables in your environment file:

| Variable | Description |
| --- | --- |
| `AIFS_EXEC` | Command prefix for the benchmark command. `bin/train` puts it after `srun` and before `anemoi-training`. |
| `AIFS_TOOL_EXEC` | Command prefix for the steps outside `srun`: the config check, `pip freeze`, the GPU information and `aifs-jobinfo`. The default is `$AIFS_EXEC`. |
| `AIFS_SRUN_ARGS` | Options that `bin/train` and `bin/inf` add to `srun`. |
| `AIFS_RAPS_ROOT` | Path of the repo. The SLURM launchers use it. If it is not set, the launchers use the git checkout that you submit the job from. |

`bin/train` splits these values at spaces. Do not use quotes in the values.

The run command is in `run_cmd.txt` in the run directory.

## Apptainer or Singularity

1. Copy the example environment file:

   ```bash
   cp env/container-apptainer.sh env/my-system.sh
   ```

2. Change the module name and the directories.

3. Set the image and submit:

   ```bash
   export AIFS_IMAGE=/path/to/aifs.sif
   export AIFS_ENV=$PWD/env/my-system.sh
   cd launchers/SLURM/ag
   sbatch train_o96.slurm
   ```

The example file sets:

```bash
export AIFS_EXEC="apptainer exec --nv --bind $repo,$AIFS_OUTPUT_DIR $AIFS_IMAGE"
```

Make sure that:

- `--nv` is in the command. Without it, the container does not see the GPUs.
- The container can see the repo, `$AIFS_OUTPUT_DIR`, `$AIFS_GRAPH_DIR` and `$AIFS_DATA_DIR`. Use `--bind` for each directory that is not in the image.
- You do not use `--cleanenv` or `--containall`. PyTorch Lightning reads the SLURM variables, and `bin/train` sets variables that the configs read.

Apptainer sets its own `PATH` in the container. If the Python environment is not on the default `PATH` of the image, add `--env PATH=<path>`.

## Pyxis and Enroot

Pyxis adds container options to `srun`. The steps outside `srun` must also use the container. Run them with a one-task `srun`:

```bash
export AIFS_SRUN_ARGS="--container-image=/path/to/aifs.sqsh --container-mounts=/scratch:/scratch"
export AIFS_TOOL_EXEC="srun --ntasks=1 --nodes=1 --overlap --container-image=/path/to/aifs.sqsh --container-mounts=/scratch:/scratch"
```

Do not set `AIFS_EXEC`.

## Without SLURM

`launchers/INTERACTIVE/train` and `launchers/INTERACTIVE/inf` use `AIFS_EXEC` for all steps. Use them on one node, for example in a Docker container or on a workstation.

## Profilers

With `--nsys`, `bin/train` runs `nsys` in the container: `srun <AIFS_EXEC> nsys profile ... anemoi-training`. The image must contain Nsight Systems. The NVIDIA PyTorch images contain it.

## Known problems

### "anemoi-training not found with AIFS_TOOL_EXEC=..."

**Cause:** `anemoi-training` is not on the `PATH` in the container.

**Remedy:** Make sure that the image contains anemoi-training. For Apptainer, add `--env PATH=<path>` to `AIFS_EXEC`.

### Training stops in Triton with "No such file or directory"

**Symptom:** The traceback contains `_create_driver`, `compile_module_from_src` and `subprocess.check_call`.

**Cause:** The image does not contain a C compiler. Triton cannot compile its CUDA module.

**Remedy:** Install `gcc` in the image.

### The job cannot find the repo

**Symptom:** The job stops with `Cannot find the AIFS-RAPS repo`.

**Cause:** You submitted the job from outside the repo, or the host does not have git.

**Remedy:** Set `AIFS_RAPS_ROOT` to the path of the repo before you submit the job.
