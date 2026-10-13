# Configs

The configs are in `configs/`. They are [Hydra](https://hydra.cc) configs for anemoi-training.

## Structure

- `configs/base.yaml` contains the settings for all benchmarks.
- Each top-level config, for example `configs/o1280.yaml`, includes `base.yaml` and sets the resolution, model, graph and input data.
- In the `defaults` list, put `base` after the config groups (`data`, `model`, `graph`, `training`). If `base` is before a group, the group replaces the values from `base.yaml`.
- `configs/data/zarr_no_insolation.yaml` is for datasets that do not contain the `insolation` variable.
- All other config groups come from anemoi-training.

## Available configs

| Config | Grid | Processor | Hidden grid | GPUs for each model | Default input | Real dataset |
| --- | --- | --- | --- | --- | --- | --- |
| `o96` | O96 (about 100 km) | Graph transformer | Refinement level 5 | 1 | Synthetic | `aifs-ea-an-oper-0001-mars-o96-1979-2023-6h-v8.zarr` |
| `n320` | N320 (about 31 km) | Transformer | O96 | 1 | Real | `aifs-ea-an-oper-0001-mars-n320-1979-2023-6h-v8.zarr` |
| `o800` | O800 (about 12 km) | Graph transformer | Refinement level 7 | 1 | Synthetic | `aifs-benchmarking-ea-an-oper-0001-mars-o800-2023-2023-6h-v1.zarr` |
| `o1280` | O1280 (about 9 km) | Transformer | O96 | 2 | Synthetic | `aifs-od-an-oper-0001-mars-o1280-2016-2023-6h-v1.zarr` |
| `o2560` | O2560 (about 4.4 km) | Transformer | O256 | 4 | Synthetic | `aifs-rd-an-lwda-ifc3-mars-o2560-2023-2023-6h-v1-1month.zarr` |

## Input data

### Synthetic data

The configs use synthetic data, but `n320` uses real data. anemoi-training makes the fields while it trains. You do not need a dataset and `AIFS_DATA_DIR`.

The config selects synthetic data with the grid name:

```yaml
system:
  input:
    dataset: synthetic:o96
```

The synthetic data has the same 101 variables as the real o96 and o800 datasets. The fields have realistic values, but they are not real weather. Use synthetic data to measure performance only.

Synthetic data is available only for octahedral grids (`o<N>`). For this reason, the `n320` config uses real data.

Synthetic data is in the `feat/raps-update-oct26` branch of anemoi-core.

### Real data

To use a real dataset, give it with `--dataset`:

```bash
bin/train --config=o96 --dataset=aifs-ea-an-oper-0001-mars-o96-1979-2023-6h-v8.zarr
```

- If the path is relative, `bin/train` finds the dataset in `$AIFS_DATA_DIR`.
- If the path is absolute, `bin/train` uses the path.
- The table above gives the real dataset for each config.

The `n320` config uses `$AIFS_DATA_DIR`. If `AIFS_DATA_DIR` is not set, use `--dataset`.

## Benchmark settings

`base.yaml` sets these values:

- Training stops after 200 steps (`dataloader.limit_batches.training`).
- Validation uses 10 steps.
- Training runs for 1 epoch.
- Plots are disabled.
- MLflow logging is disabled.
- The memory profiler is enabled.
- The number of nodes and GPUs comes from the environment.

## Graphs

anemoi-training makes the graph at the start of the first run. It then keeps the graph in `$AIFS_GRAPH_DIR`. Later runs with the same config use the cached graph.

If you change a graph setting, also change the graph file name with `system.input.graph=<path>`, or set `graph.overwrite=True`. If you do not, the run uses the old graph.

## Add a config

1. Copy a top-level config that is similar, for example `configs/n320.yaml`.
2. Change `data.resolution`, `system.input.dataset` and `system.input.graph`. For synthetic data, set `system.input.dataset: synthetic:<grid>`.
3. Change the training and validation dates. For real data, the dates must be in the dataset.
4. Run `bin/train --config=<name> --dryrun` to make sure that the config is correct.
