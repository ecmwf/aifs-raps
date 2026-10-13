# Results

## Run directory

Each run makes a directory in `$AIFS_OUTPUT_DIR/train`. The name is:

```text
<config>_<nodes>N_<gpus per node>gpn.<job name>-<job id>
```

The directory contains these files:

| File | Contents |
| --- | --- |
| `out.txt` | Output of the run, with start time, end time and exit code. |
| `config.yaml` | The resolved config. |
| `run_cmd.txt` | The command that ran. |
| `jobinfo.csv` | Summary of the run. Refer to the section below. |
| `python_env.txt` | Output of `pip freeze`. |
| `pytorch_config.txt` | PyTorch build settings. |
| `gpu.txt` | Output of `nvidia-smi` or `rocm-smi`. |
| `env.txt` | Environment variables. |
| `graph.txt` | Description of the graph. |
| `logs/nccl.*` | NCCL debug output. |
| `train-outputs/` | Checkpoints, profiler output and logs from anemoi-training. |
| `nsys/` | Nsight Systems reports, if you used `--nsys`. |

## Performance values

The benchmark profiler writes tables at the end of `out.txt`. The most important values are:

| Value | Description |
| --- | --- |
| `training_avg_throughput` | Mean number of training steps each second. |
| `run_training_epoch` | Time for one training epoch, in seconds. |
| `Allocated memory` | Peak GPU memory. |

## Compare runs

`bin/aifs-jobinfo` makes one CSV line for each run directory:

```bash
bin/aifs-jobinfo $AIFS_OUTPUT_DIR/train/o1280_* > o1280.csv
```

## Other tools

| Tool | Description |
| --- | --- |
| `bin/upload_to_mlflow <rundir>` | Sends offline MLflow logs to an MLflow server. Enable MLflow logging with `diagnostics.log.mlflow.enabled=True`. |
