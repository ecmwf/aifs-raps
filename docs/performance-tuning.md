# Performance tuning

This document gives the settings that change the training and inference performance. Change them with Hydra overrides. An override that starts with `+` adds a key that is not in the config. An override that starts with `++` adds the key or changes it.

```bash
bin/train --config=o1280 training.precision=bf16-mixed dataloader.num_workers.training=16
```

Record the overrides that you use with your results. `config.yaml` and `run_cmd.txt` in the run directory contain them.

## Profiler

`bin/train` runs `anemoi-training profile`. The benchmark profiler measures the time and the throughput. `bin/aifs-jobinfo` reads the result tables of the profiler from `out.txt`.

| Part | Default | Override | Effect |
| --- | --- | --- | --- |
| Time and speed | On | `diagnostics.benchmark_profiler.time.enabled`, `...speed.enabled` | Give the values in `jobinfo.csv`. Small overhead. Keep them on. |
| Memory | On, 20 steps, rank 0 only | `diagnostics.benchmark_profiler.memory.enabled=False` | Gives the peak GPU memory. The steps that it records are slower. At the end, it uses much host memory to make the summary. |
| System, snapshot, model summary | Off | `diagnostics.benchmark_profiler.<part>.enabled=True` | Use them only to examine a problem. |

Do these steps:

- To measure the best time, disable the memory profiler.
- If a large config stops with a host out-of-memory error after training, decrease `diagnostics.benchmark_profiler.memory.steps` or disable the memory profiler.
- Do not use `--no-profile` for benchmark results. Without the profiler, `out.txt` does not contain the result tables, and `jobinfo.csv` is empty.

## Checkpoints

There are two types of checkpointing. They are different.

### Model checkpoints

Training writes the model weights to `train-outputs/checkpoint/`. The o800 checkpoint is approximately 2.2 GB. The time to write the checkpoints is in the run time, but not in the throughput.

| Override | Description |
| --- | --- |
| `diagnostics.enable_checkpointing=False` | Do not write checkpoints. |
| `diagnostics.checkpoint.every_n_minutes.save_frequency=<n>` | Write a checkpoint each `<n>` minutes. The default is 30. |
| `diagnostics.checkpoint.every_n_epochs.save_frequency=<n>` | Write a checkpoint each `<n>` epochs. The default is 1. |

`bin/inf --train-rundir` needs the checkpoint `inference-last.ckpt`. If you want to run inference after training, keep the checkpoints.

### Activation checkpointing

Activation checkpointing (gradient checkpointing) does not keep the activations in memory. It calculates them again in the backward pass. This decreases the GPU memory, but the training is slower.

It is on by default for the processor and the mappers:

```bash
model.processor.gradient_checkpointing=False
model.encoders.0.mapper.gradient_checkpointing=False
model.decoders.0.mapper.gradient_checkpointing=False
```

If the model fits in GPU memory without it, disable it to make training faster.

## torch.compile

The model configs compile the graph transformer layers (`GraphTransformerConv`) with `torch.compile`. The `model.compile` list gives the modules to compile.

| Override | Description |
| --- | --- |
| `model.compile=null` | Do not compile. |
| `++model.compile.0.options.mode=max-autotune` | Use more time to compile and find faster kernels. |
| `+model.recompile_limit=<n>` | Maximum number of compilations for each function. The default is 8. |

Compilation occurs in the first training steps. These steps are slow, and the time for one epoch includes them. Use a sufficient number of steps (`dataloader.limit_batches.training`) to make this effect small.

`PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True` in `env/ecmwf-ag.sh` decreases memory fragmentation. PyTorch gives a warning that this setting can cause errors with `torch.compile`. If you get errors in compiled code, remove this setting.

## Attention backend

### Transformer processor

The `transformer` model (configs `n320`, `o1280` and `o2560`) uses attention in the processor:

| Value of `model.processor.attention_implementation` | Description |
| --- | --- |
| `flash_attention` | Default. Flash Attention. Faster than PyTorch attention. You must install it. |
| `scaled_dot_product_attention` | PyTorch attention. Slower, but you do not install other packages. Use it to compare, or if Flash Attention is not available. |
| `triton_attention` | Triton sliding window attention kernel. Roughly as fast as FA2, comes with anemoi-models. no installation (beyond triton) required. |

anemoi-models uses the newest Flash Attention version that is installed:

| Version | Package | Import | Notes |
| --- | --- | --- | --- |
| 4 | `flash-attn-4` | `flash_attn.cute` | For Hopper and Blackwell GPUs. |
| 3 | `flash-attn-3` | `flash_attn_interface` | For Hopper GPUs. |
| 2 | `flash-attn` | `flash_attn` | For Ampere GPUs and newer, and AMD MI200 and newer. |

The log shows the version, for example `Using flash attention v4`. To use an older version, remove the newer packages from the environment. Versions 3 and 4 do not support `use_rotary_embeddings` and `use_alibi_slopes`.

For inference, `ANEMOI_INFERENCE_TRANSFORMER_ATTENTION_BACKEND=<value>` replaces the value in the checkpoint.

### Graph transformer

The graph transformer layers (the mappers, and the processor of the `graphtransformer` model in configs `o96` and `o800`) have a different backend:

| Value of `graph_attention_backend` | Description |
| --- | --- |
| `triton` | Default. Triton kernels. |
| `pyg` | PyTorch Geometric. Use it to compare, or if Triton is not available. |

Set it for each part:

```bash
model.processor.graph_attention_backend=pyg
model.encoders.0.mapper.graph_attention_backend=pyg
model.decoders.0.mapper.graph_attention_backend=pyg
```

The `transformer` model has the key only in the mappers.

## Precision

| Value of `training.precision` | Description |
| --- | --- |
| `16-mixed` | Default. fp16 with fp32 weights. Uses loss scaling. |
| `bf16-mixed` | bf16 with fp32 weights. Usually as fast as fp16, and more stable. Needs Ampere GPUs or newer. |
| `32` | fp32. Slowest. Use it only as a reference. |

Use the same precision on all the systems that you compare.

For inference, use `bin/inf --precision`. The default is `bf16`. Refer to [inference.md](inference.md).

## Dataloader workers

Each GPU has its own dataloader processes. They read or make the input data.

| Override | Default | Description |
| --- | --- | --- |
| `dataloader.num_workers.training=<n>` | 8 (6 for o1280 and o2560) | Number of processes for each GPU. |
| `dataloader.num_workers.validation=<n>` | 8 | The same, for validation. |
| `dataloader.prefetch_factor=<n>` | 1 (`base.yaml`) | Number of batches that each process prepares before they are necessary. |
| `dataloader.pin_memory=<bool>` | True | Use page-locked host memory for faster copies to the GPU. |

To find if the dataloader is too slow, compare the throughput with `dataloader.num_workers.training=<n>` for some values of `<n>`. If the throughput increases, the dataloader was too slow.

Make sure that the number of workers for each GPU is smaller than `--cpus-per-task`.

Synthetic data uses CPU to make the fields. At high resolution, synthetic data can need more workers than real data.

## Chunks

Chunks divide the work of a layer into smaller parts. This decreases the GPU memory, but more chunks are usually slower.

### Training

| Override | Description |
| --- | --- |
| `model.processor.num_chunks=<n>` | The processor layers are in `<n>` groups for activation checkpointing. The number of layers (16) must be divisible by `<n>`. |
| `model.encoders.0.mapper.num_chunks=<n>` | The encoder edges are in `<n>` parts. |
| `model.decoders.0.mapper.num_chunks=<n>` | The decoder edges are in `<n>` parts. |

The configs set these values:

| Config | Processor | Encoder | Decoder |
| --- | --- | --- | --- |
| `o96`, `n320` | 4 | 4 | 4 |
| `o800` | 16 | 4 | 4 |
| `o1280` | 2 | 4 | 4 |
| `o2560` | 16 | 16 | 16 |

Use the smallest number of chunks that fits in GPU memory.

### Inference

Set the inference chunks with environment variables:

| Variable | Description |
| --- | --- |
| `ANEMOI_INFERENCE_NUM_CHUNKS` | Chunks for the mappers and the processor. `bin/inf --chunks` sets it. The default is 1. |
| `ANEMOI_INFERENCE_NUM_CHUNKS_MAPPER` | Chunks for the mappers only. |
| `ANEMOI_INFERENCE_NUM_CHUNKS_PROCESSOR` | Chunks in each graph transformer processor layer. Only for inference. |

The mappers use the larger value: the value in the checkpoint, or the value of the variable. The variables can increase the mapper chunks, but cannot decrease them.

## Model sharding

If the model does not fit in the memory of one GPU, divide it across more GPUs:

| Override | Description |
| --- | --- |
| `system.hardware.num_gpus_per_model=<n>` | Number of GPUs for each model instance. The configs `o1280` and `o2560` use 2 and 4. |
| `model.encoders.0.mapper.shard_strategy=<s>` | `edges` or `heads`. |

More GPUs for each model decrease the memory for each GPU, but add communication. Do these steps in this sequence: increase the chunks, then increase `num_gpus_per_model`.

For inference, refer to [inference.md](inference.md#model-sharding).
