# Inference

`bin/inf` runs a forecast with [anemoi-inference](https://github.com/ecmwf/anemoi-inference). It measures the time to make the forecast and to write the output.

## Before you start

Make sure that you have:

- anemoi-inference in your Python environment. Refer to [environment.md](environment.md).
- An inference checkpoint. A training run writes `inference-last.ckpt` in `train-outputs/checkpoint/<run id>/`.

The checkpoint must come from the same anemoi-models version as your environment.

## Run inference

With SLURM:

```bash
cd launchers/SLURM/ag
sbatch inf.slurm -- --checkpoint=/path/to/inference-last.ckpt
```

Put `--` before the `bin/inf` options. If you do not, `sbatch` tries to read the options and fails.

Without SLURM:

```bash
launchers/INTERACTIVE/inf --checkpoint=/path/to/inference-last.ckpt
```

To use the last checkpoint of a training run, give the run directory:

```bash
sbatch inf.slurm -- --train-rundir=$AIFS_OUTPUT_DIR/train/<run>
```

## Options

| Option | Description |
| --- | --- |
| `-C`, `--checkpoint <path>` | Inference checkpoint. |
| `--train-rundir <dir>` | Use the last inference checkpoint of a `bin/train` run directory. |
| `-T`, `--lead-time <hours>` | Length of the forecast. The default is 240. |
| `-I`, `--input <input>` | `dummy`, a GRIB file or a zarr dataset. The default is `dummy`. |
| `-d`, `--date <date>` | Initial date. The default is `2023-01-01T00:00:00`. |
| `-O`, `--output <type>` | `grib`, `netcdf`, `zarr` or `none`. The default is `grib`. |
| `-W`, `--writers <n>` | Number of parallel output writers. `0` disables parallel output. The default is `0`. |
| `-p`, `--precision <p>` | Inference precision, for example `bf16` or `16-mixed`. `checkpoint` uses the training precision. The default is `bf16`. |
| `--chunks <n>` | Number of chunks for the mappers and the processor. The default is `1`. |
| `-D`, `--devices <n>` | Number of GPUs for model sharding without SLURM. The default is `1`. |
| `--interactive` | Do not use `srun`. |
| `--profile` | Enable the anemoi-inference profiler. |
| `--nsys` | Run with Nsight Systems, or with `rocprofv3` on AMD GPUs. |
| `--dryrun` | Show the inference config. Do not run. |

Put anemoi-inference config overrides after `--`, for example `-- write_initial_state=false`.

## Synthetic input

The default input is `dummy`. The `dummy` input makes synthetic fields for all input variables of the checkpoint. You do not need input data.

Use synthetic input to measure performance only. The forecast values have no meaning.

Do not use fp16 (`16-mixed`) with synthetic input. The synthetic fields can cause overflow in fp16, and the output then contains NaN values. The default precision is `bf16` for this reason.

## Model sharding

Model sharding divides one model across more than one GPU. Each GPU keeps a part of the model and a part of the grid. Use model sharding when:

- The model does not fit in the memory of one GPU.
- You want to make one forecast faster.

### Enable model sharding

With SLURM, `bin/inf` shards the model across all tasks of the job. Set one task for each GPU:

```bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --gres=gpu:4
```

To use more GPUs, increase `--nodes` or `--ntasks-per-node`.

Without SLURM, set the number of GPUs with `--devices`:

```bash
launchers/INTERACTIVE/inf --checkpoint=<ckpt> --devices=4
```

### Configuration

If there is more than one GPU, `bin/inf` adds the parallel runner to the config. With SLURM, the runner gets the ranks from the SLURM variables:

```yaml
runner: parallel
```

Without SLURM, `bin/inf` sets the number of GPUs:

```yaml
runner:
  parallel:
    cluster:
      manual: 4
```

### Decrease memory use

If the model does not fit in GPU memory, do these steps in this sequence:

1. Increase the number of GPUs.
2. Increase `--chunks`. More chunks use less memory, but the forecast is slower.

## Parallel output

Parallel output writes the forecast in more than one process. The forecast continues while the writers write the output. Use parallel output when the output time is a large part of the total time.

### Enable parallel output

Set the number of writers with `--writers`:

```bash
sbatch inf.slurm -- --checkpoint=<ckpt> --writers=4
```

`bin/inf` puts the output in a `parallel` block:

```yaml
output:
  parallel:
    num_writers: 4
    output:
      grib:
        path: aifs_out.grib
```

Each writer writes its own file. The file names have the suffix `_w<n>`, for example `aifs_out_w0.grib` and `aifs_out_w1.grib`. Each file contains a part of the fields for each step.

### Choose the number of writers

- `--writers=0`: The main process writes the output. The forecast stops while it writes.
- `--writers=1`: One writer process writes all output to one file. The forecast does not stop while it writes.
- `--writers=2` or more: The writers write at the same time. Start with 2 or 4. Increase the number if the output is still slow.

Each writer uses one CPU core and memory for the fields. Make sure that `--cpus-per-task` is larger than the number of writers.

### Parallel output with model sharding

You can use the two together. Only the process on GPU 0 makes the writers. The other processes do not write output.

```bash
sbatch --nodes=1 --ntasks-per-node=4 inf.slurm -- --checkpoint=<ckpt> --writers=4
```

## Output formats

| Output | Description |
| --- | --- |
| `grib` | GRIB files. `bin/inf` uses the templates in `etc/aifs/inf/grib-templates`. There are templates for N96, N128, N320, N1280, O96, O128, O320, O800, O1280 and O2560. |
| `netcdf` | NetCDF files. Requires the `netCDF4` package. |
| `zarr` | Zarr store. |
| `none` | No output. Use it to measure the forecast time only. |

## Run directory

Each run makes a directory in `$AIFS_OUTPUT_DIR/inf`. The directory contains:

| File | Contents |
| --- | --- |
| `inf.yaml` | The anemoi-inference config. |
| `out.txt` | Output of the run, with start time, end time and exit code. |
| `run_cmd.txt` | The command that ran. |
| `aifs_out*` | The forecast output. |
| `output_size.txt` | Size of the output. |
| `python_env.txt`, `gpu.txt`, `env.txt` | Information about the environment. |

## Known problems

### The GRIB output fails with "Encoding invalid"

**Symptom:** `out.txt` contains `Minimum value out of range: nan` and `Encoding invalid`.

**Cause:** The forecast contains NaN values. This occurs with fp16 and synthetic input.

**Remedy:** Use `--precision=bf16`.

### A sharded run stops after approximately 10 minutes

**Symptom:** The job stops with exit code 143. Only rank 0 shows an error.

**Cause:** Rank 0 stopped because of an error. The other ranks wait for rank 0 until the NCCL timeout.

**Remedy:** Find the first error from rank 0 in `out.txt` and correct it.

