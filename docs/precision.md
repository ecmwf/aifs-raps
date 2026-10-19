# Precision

This document describes the training precision options. It gives special attention to the explicit bf16 precision (`bf16-fp32-opt`) in the `feat/raps-update-oct26` branch of anemoi-core.

## Options

Set the precision with `training.precision`:

| Value | Weights in the model | Calculation | Weights for the optimizer |
| --- | --- | --- | --- |
| `32` | fp32 | fp32 | fp32 |
| `16-mixed` | fp32 | fp16 (autocast), with loss scaling | fp32 |
| `bf16-mixed` | fp32 | bf16 (autocast) | fp32 |
| `bf16-fp32-opt` | bf16 | bf16 (no autocast) | fp32 reference weights |

`16-mixed` is the default in `configs/base.yaml`.

Use the same precision on all the systems that you compare. Record the precision with your results. `bin/aifs-jobinfo` writes it in the `Precision` column of `jobinfo.csv`.

## Mixed precision with autocast

`16-mixed` and `bf16-mixed` use PyTorch autocast. The model keeps its weights in fp32. In the forward pass, autocast changes the inputs of each operation to fp16 or bf16 when the operation is safe in low precision.

This has a cost:

- Each forward pass makes low-precision copies of the weights. These are cast kernels.
- Activation checkpointing calculates the forward pass again in the backward pass. Thus it makes the casts again.
- The casts add launches on the host. For a large model on many GPUs, the host time can limit the step time.

## Explicit bf16 precision

`bf16-fp32-opt` keeps the model in bf16. It does not use autocast. Thus the forward pass and the recomputation do not have cast kernels.

The optimizer does not use the bf16 weights. It uses a separate fp32 copy, the reference weights (also known as master weights). Small updates to the weights are thus not lost to bf16 rounding.

### Sequence of one step

1. The forward pass and the backward pass use the bf16 weights.
2. DDP adds the gradients of all ranks. A communication hook changes the gradients to fp32 before the all-reduce. It calculates the mean, and then changes the result back to bf16.
3. The plugin adds the bf16 gradients to the fp32 gradients of the reference weights. It then deletes the bf16 gradients. Thus gradient accumulation occurs in fp32.
4. Lightning clips the gradients of the fp32 reference weights.
5. The optimizer updates the fp32 reference weights. The optimizer state (for example the AdamW moments) is fp32.
6. The plugin copies the reference weights to the bf16 model weights.

### Model changes

The strategy gives the bf16 compute dtype to the model. The model uses it for:

- The latent tensors of the encoder, the processor and the decoder.
- The noise of the ensemble model.
- The halo rows that move between the ranks. Refer to [parallelism.md](parallelism.md#overlap-with-computation).

### Memory

For each model parameter, `bf16-fp32-opt` keeps:

- 2 bytes for the bf16 weight.
- 4 bytes for the fp32 reference weight.
- The fp32 optimizer state (8 bytes for AdamW).
- The bf16 gradient and the fp32 gradient.

The log gives the size of the reference weights: `BF16FP32OptPrecision: Created <n> reference weights (~<size> GB in fp32)`.

The activations are bf16. Thus `bf16-fp32-opt` usually uses less activation memory than `32`.

### Checkpoints

A checkpoint contains the bf16 model weights, the fp32 reference weights and the fp32 optimizer state. When you resume a run, the plugin loads the reference weights from the checkpoint. It does not make them again from the bf16 weights. Thus no precision is lost when you resume.

### Optimizer

The plugin replaces the parameters of the optimizer with the reference weights. Do not use `foreach=True` or `fused=True` in the optimizer. The plugin gives a warning if they are set.

### Performance

On a 4.4 km grid (o2560 data), `bf16-fp32-opt` decreased the GPU compute time by approximately 15% when compared with autocast.

The fp32 gradient all-reduce sends twice the data of a bf16 all-reduce. To measure this cost, set `ANEMOI_BF16_GRAD_REDUCE=1`. The plugin then does not register the hook, and DDP does the all-reduce in bf16. Do not use this setting for training, and do not use it for benchmark results. The precision of the gradients is lower.

### Use it

```bash
bin/train --config=o1280 training.precision=bf16-fp32-opt
```

The log shows the plugin:

```text
Active precision plugin: BF16FP32OptPrecision
BF16FP32OptPrecision: Converting model to bfloat16
Registered fp32 gradient reduction hook for DDP
```

`bf16-fp32-opt` needs a GPU that supports bf16 (NVIDIA Ampere or newer, AMD MI200 or newer).

## Inference

The training precision does not set the inference precision. Use `bin/inf --precision`. The default is `bf16`. Refer to [inference.md](inference.md).
