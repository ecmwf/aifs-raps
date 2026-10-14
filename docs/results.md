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

The `BenchmarkTimer` callback measures the training performance. `configs/base.yaml` enables it. The code is in `python/aifs_raps/benchmark.py`.

The callback does not measure the first 10 steps (the warm-up). These steps include `torch.compile` and the start of the dataloader. The callback synchronises the GPU only at the start and at the end of the measured steps. It stops before the first validation.

At the end of training, rank 0 writes one line in `out.txt`:

```text
AIFS-RAPS benchmark: warmup_steps=10 total_steps=50 measured_steps=40 measured_time_s=8.435 steps_per_s=4.7423 warmup_time_s=6.653 global_batch_size=4 samples_per_s=18.9690 peak_gpu_mem_mib=3264
```

| Value | Description |
| --- | --- |
| `steps_per_s` | Training steps each second, after the warm-up. |
| `samples_per_s` | Samples each second for all GPUs: `steps_per_s` × batch size × number of model instances. Use this value to compare runs with different numbers of GPUs. |
| `measured_steps`, `measured_time_s` | Number of measured steps and their time. |
| `warmup_time_s` | Time for the warm-up steps. |
| `peak_gpu_mem_mib` | Peak allocated GPU memory on rank 0, in MiB. |

To change the number of warm-up steps, use `diagnostics.callbacks.0.warmup_steps=<n>`. The number of training steps must be larger than the number of warm-up steps.

With `bin/train --profile`, the benchmark profiler also writes tables at the end of `out.txt`. Refer to [performance-tuning.md](performance-tuning.md#profiler).

## Compare runs

`bin/aifs-jobinfo` makes one CSV line for each run directory. It reads `config.yaml`, `run_cmd.txt` and the `AIFS-RAPS benchmark` line in `out.txt`. The columns `TrainingEpochTimeS` and `AvgTrainingThroughput` come from the profiler tables. They are empty if you did not use `--profile`.

```bash
bin/aifs-jobinfo $AIFS_OUTPUT_DIR/train/o1280_* > o1280.csv
```

## Other tools

| Tool | Description |
| --- | --- |
| `bin/upload_to_mlflow <rundir>` | Sends offline MLflow logs to an MLflow server. Enable MLflow logging with `diagnostics.log.mlflow.enabled=True`. |
