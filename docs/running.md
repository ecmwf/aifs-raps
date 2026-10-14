# Run a benchmark

## Before you start

Make sure that you have:

- A Python environment. Refer to [environment.md](environment.md).
- An environment file. Refer to [environment.md](environment.md).
You do not need input data. The configs use synthetic data, but `n320` uses real data. Refer to [configs.md](configs.md#input-data).

## Do a test run first

The `o96` config is small. It runs on one GPU in some minutes. Use it to make sure that your environment is correct.

```bash
launchers/INTERACTIVE/train o96
```

## Run with SLURM

1. Go to the launcher directory for your system:

   ```bash
   cd launchers/SLURM/ag
   ```

2. Submit a launcher:

   ```bash
   sbatch train_o1280.slurm
   ```

3. To change the config, add Hydra overrides after the script name:

   ```bash
   sbatch train_o1280.slurm model.num_channels=2048 dataloader.limit_batches.training=50
   ```

4. To give `bin/train` options, put `--` after the script name. If you do not, `sbatch` tries to read the options and fails:

   ```bash
   sbatch train_o1280.slurm -- --dataset=aifs-od-an-oper-0001-mars-o1280-2016-2023-6h-v1.zarr
   ```

To change the number of nodes, use the `sbatch` option `--nodes`. The config reads the number of nodes from SLURM.

### Make a launcher for a different system

1. Copy `launchers/SLURM/ag` to `launchers/SLURM/<system>`.
2. Change the `#SBATCH` lines. Set one task for each GPU.
3. Change the default environment file in the `source` line.

## Run without SLURM

Use the interactive launcher. It runs on the current node and does not use `srun`.

```bash
launchers/INTERACTIVE/train <config> [bin/train options] [hydra overrides]
```

If there is more than one GPU, PyTorch Lightning starts one process for each GPU.

## Use bin/train directly

The launchers call `bin/train`. You can call it directly after you load your environment.

```bash
source env/ecmwf-ag.sh
bin/train --config=o800 model.num_channels=512
```

| Option | Description |
| --- | --- |
| `-c`, `--config <name>` | Config name in `configs/`. Required. |
| `-d`, `--dataset <ds>` | Input dataset. The default is the dataset in the config. Refer to [configs.md](configs.md#input-data). |
| `-J`, `--jobname <name>` | Name for the run directory. The default is `$SLURM_JOB_NAME`. |
| `--interactive` | Do not use `srun`. |
| `--no-profile` | Use `anemoi-training train`. The default is `anemoi-training profile`. |
| `--nsys` | Run with Nsight Systems, or with `rocprofv3` on AMD GPUs. |
| `--dryrun` | Show the resolved config. Do not train. |

Hydra overrides have the form `key=value`. Put them after the options, or after `--`.

## Frequent overrides

| Override | Description |
| --- | --- |
| `model.num_channels=<n>` | Width of the model. |
| `system.hardware.num_gpus_per_model=<n>` | Number of GPUs that shard one model. |
| `dataloader.batch_size.training=<n>` | Batch size for each model instance. |
| `dataloader.limit_batches.training=<n>` | Number of training steps in each epoch. |
| `dataloader.num_workers.training=<n>` | Number of dataloader processes for each GPU. |
| `training.max_epochs=<n>` | Number of epochs. |
| `training.precision=<p>` | `16-mixed`, `bf16-mixed`, `bf16-fp32-opt` or `32`. Refer to [precision.md](precision.md). |
| `diagnostics.log.mlflow.enabled=True` | Write offline MLflow logs. |
