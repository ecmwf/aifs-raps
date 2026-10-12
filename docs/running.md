# Run a benchmark

## Before you start

Make sure that you have:

- A Python environment. Refer to [environment.md](environment.md).
- An environment file. Refer to [environment.md](environment.md).
- The input datasets in `$AIFS_DATA_DIR`. Refer to [configs.md](configs.md) for the dataset names.

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

To change the number of nodes, use the `sbatch` option `--nodes`. The config reads the number of nodes from SLURM.

### Make a launcher for a different system

1. Copy `launchers/SLURM/ag` to `launchers/SLURM/<system>`.
2. Change the `#SBATCH` lines. Set one task for each GPU.
3. Change the default environment file in the `source` line.

## Run without SLURM

Use the interactive launcher. It runs on the current node and does not use `srun`.

```bash
launchers/INTERACTIVE/train <config> [hydra overrides]
```

If there is more than one GPU, PyTorch Lightning starts one process for each GPU.

## Use bin/train directly

The launchers call `bin/train`. You can call it directly after you load your environment.

```bash
source env/ecmwf-ag.sh
bin/train --config=o800 -- model.num_channels=512
```

| Option | Description |
| --- | --- |
| `-c`, `--config <name>` | Config name in `configs/`. Required. |
| `-J`, `--jobname <name>` | Name for the run directory. The default is `$SLURM_JOB_NAME`. |
| `--interactive` | Do not use `srun`. |
| `--no-profile` | Use `anemoi-training train`. The default is `anemoi-training profile`. |
| `--nsys` | Run with Nsight Systems, or with `rocprofv3` on AMD GPUs. |
| `--dryrun` | Show the resolved config. Do not train. |

Put Hydra overrides after `--`.

## Frequent overrides

| Override | Description |
| --- | --- |
| `model.num_channels=<n>` | Width of the model. |
| `system.hardware.num_gpus_per_model=<n>` | Number of GPUs that shard one model. |
| `dataloader.batch_size.training=<n>` | Batch size for each model instance. |
| `dataloader.limit_batches.training=<n>` | Number of training steps in each epoch. |
| `dataloader.num_workers.training=<n>` | Number of dataloader processes for each GPU. |
| `training.max_epochs=<n>` | Number of epochs. |
| `training.precision=<p>` | For example `16-mixed` or `bf16-mixed`. |
| `diagnostics.log.mlflow.enabled=True` | Write offline MLflow logs. |
