# Configs

The configs are in `configs/`. They are [Hydra](https://hydra.cc) configs for anemoi-training.

## Structure

- `configs/base.yaml` contains the settings for all benchmarks.
- Each top-level config, for example `configs/o1280.yaml`, includes `base.yaml` and sets the resolution, model, graph and dataset.
- In the `defaults` list, put `base` after the config groups (`data`, `model`, `graph`, `training`). If `base` is before a group, the group replaces the values from `base.yaml`.
- `configs/data/zarr_no_insolation.yaml` is for datasets that do not contain the `insolation` variable.
- All other config groups come from anemoi-training.

## Available configs

| Config | Grid | Processor | Hidden grid | GPUs for each model | Dataset |
| --- | --- | --- | --- | --- | --- |
| `o96` | O96 (about 100 km) | Graph transformer | Refinement level 5 | 1 | `aifs-ea-an-oper-0001-mars-o96-1979-2023-6h-v8.zarr` |
| `n320` | N320 (about 31 km) | Transformer | O96 | 1 | `aifs-ea-an-oper-0001-mars-n320-1979-2023-6h-v8.zarr` |
| `o800` | O800 (about 12 km) | Graph transformer | Refinement level 7 | 1 | `aifs-benchmarking-ea-an-oper-0001-mars-o800-2023-2023-6h-v1.zarr` |
| `o1280` | O1280 (about 9 km) | Transformer | O96 | 2 | `aifs-od-an-oper-0001-mars-o1280-2016-2023-6h-v1.zarr` |
| `o2560` | O2560 (about 4.4 km) | Transformer | O256 | 4 | `aifs-rd-an-lwda-ifc3-mars-o2560-2023-2023-6h-v1-1month.zarr` |

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
2. Change `data.resolution`, `system.input.dataset` and `system.input.graph`.
3. Change the training and validation dates. They must be in the dataset.
4. Run `bin/train --config=<name> --dryrun` to make sure that the config is correct.
