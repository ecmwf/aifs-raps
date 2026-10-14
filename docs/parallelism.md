# Parallel training

This document describes how anemoi-training divides the work across GPUs. It gives the parallelisation scheme in the `feat/raps-update-oct26` branch of anemoi-core.

There are two levels of parallelisation:

- Data parallelism. Each model instance trains on a different sample.
- Model sharding. One model instance uses more than one GPU. Each GPU calculates a part of the grid.

## Terms

| Term | Description |
| --- | --- |
| Model group | The GPUs that share one model instance. `system.hardware.num_gpus_per_model` gives the number of GPUs in a model group. |
| Rank | One GPU process. |
| Node (graph) | A point of the data grid or of the hidden grid. Do not confuse a graph node with a compute node. |
| Edge | A connection between two graph nodes. Each edge goes from a source node to a destination node. |
| Shard | The part of a tensor that one rank keeps. |
| Halo | The remote source nodes that a rank needs from other ranks. |

## Data parallelism

The total number of GPUs is the number of model groups multiplied by `num_gpus_per_model`. Each model group reads a different sample. All model groups have the same weights.

After the backward pass, PyTorch DDP adds the gradients of all ranks. This is an all-reduce. Each rank then applies the same optimizer step.

The cost of the all-reduce depends on the number of model parameters. It does not depend on the grid size. With many model groups, it can be a large part of the step time.

## Model sharding

The model has three parts:

1. The encoder. It maps the data grid to the hidden grid.
2. The processor. It updates the hidden grid.
3. The decoder. It maps the hidden grid back to the data grid.

When `num_gpus_per_model` is larger than 1, each rank of the model group keeps:

- A shard of the data grid nodes.
- A shard of the hidden grid nodes.
- The edges that go into its destination nodes.
- A full copy of the model weights.

The shards are contiguous blocks of node indices. The blocks have almost the same size. For an octahedral grid, the node order follows the rows of latitude. Thus each shard of an octahedral grid is approximately a band of latitude. The refined icosahedral hidden grids (configs `o96` and `o800`) have a different node order.

With `model.keep_batch_sharded=True`, the dataloader of each rank reads only the grid points of its shard. All the configs use this setting.

### Sharding strategies

Each graph transformer layer has a `shard_strategy`:

| Value | Description |
| --- | --- |
| `edges` | Each rank calculates the attention for its destination nodes only. The rank gets the remote source nodes from the other ranks. This is the default. |
| `heads` | An all-to-all changes the tensors from a shard of nodes to a shard of attention heads. Each rank calculates some heads on the full grid. A second all-to-all changes the result back. |

The processor of the `transformer` model (configs `n320`, `o1280` and `o2560`) always uses heads sharding. The configs set `shard_strategy: edges` for the encoder and the decoder.

## Halo exchange

With the `edges` strategy, a destination node on one rank can have source nodes on other ranks. The rank must get the values of these source nodes before it calculates the attention.

Before this branch, the encoder and the decoder gathered all the source nodes on each rank. The data volume was the full source grid on each rank.

The halo exchange sends only the source nodes that a remote rank needs. Each rank sends the boundary rows of its shard to the ranks that need them. For a band of latitude, these are the rows near the north and the south edges of the band.

The figure shows one rank with its local nodes and its halo, for shards that are bands of latitude:

```text
            rank r-1
  ------------------------------
  | halo rows from rank r-1    |   <- received from rank r-1
  |============================|
  | local nodes of rank r      |   <- destination nodes of rank r
  |============================|
  | halo rows from rank r+1    |   <- received from rank r+1
  ------------------------------
            rank r+1
```

### Halo plan

The halo plan (`HaloInfo`) gives, for each rank:

- The local source nodes to send to each peer rank.
- The number of halo nodes to receive from each peer rank.
- The local edges with new node indices. The indices start with the local nodes. The halo nodes follow them.

The plan uses only the outgoing edges. Thus the graph can be directed. It does not need the reverse edges.

The rank builds the plan in the first forward pass. To do this, it gathers the edge indices of all ranks one time. The model then keeps the plan and uses it again in all subsequent steps. The plan stays valid while the graph and the shard sizes do not change.

The processor builds one plan. All processor layers use this plan. The encoder and the decoder each build their own plan, because their source nodes and destination nodes are on different grids.

### Communication

The halo exchange uses point-to-point messages (`batch_isend_irecv`). Each rank sends messages only to its peers. A peer is a rank that shares halo nodes with it. If the shards are bands of latitude, a rank usually has two peers. Thus the cost depends on the number of peers, not on the size of the model group.

Set `ANEMOI_HALO_COMM=a2a` to use one `all_to_all` over the full model group. This was the method before the point-to-point change. Use it only to compare.

### Overlap with computation

In each processor layer, the exchange occurs in two steps: start and wait.

1. The layer applies the layer norm.
2. The layer starts the halo exchange.
3. While the halo rows move, the layer calculates the query, and the key, value and edge projections of the local nodes.
4. The layer waits for the halo rows.
5. The layer calculates the key and value of the halo rows, and then the attention.

The backward pass starts the reverse exchange in the same way. It adds the received gradients in fp32.

The halo rows move in the compute dtype (for example bf16). This halves the data volume when compared with fp32.

### Caches

The model keeps these static values for all steps:

- The graph partition and the halo plan.
- The chunk plan of the encoder and the decoder (refer to [Chunks](performance-tuning.md#chunks)).
- The sorted edge layout (CSC) for the Triton graph transformer kernels.
- The edge attributes, if there are no trainable edge parameters.

These caches remove host work and host-device synchronisation from each step.

### Limits

- The processor halo exchange needs a batch size of 1 for each model group.
- The caches are valid only for a static graph. If you change the edges but not the shard sizes, build the model again.
- `heads` sharding and runs with one GPU for each model do not use a halo exchange.

## Settings

| Setting | Default | Description |
| --- | --- | --- |
| `system.hardware.num_gpus_per_model=<n>` | 1 (2 for `o1280`, 4 for `o2560`) | Number of GPUs in a model group. |
| `model.encoders.0.mapper.shard_strategy=<s>` | `edges` | `edges` or `heads`. |
| `model.decoders.0.mapper.shard_strategy=<s>` | `edges` | `edges` or `heads`. |
| `model.processor.shard_strategy=<s>` | `edges` | Only for the `graphtransformer` model. |
| `model.encoders.0.mapper.use_halo_exchange=<bool>` | True | False gathers all source nodes on each rank. Use it only to compare. |
| `model.decoders.0.mapper.use_halo_exchange=<bool>` | True | The same, for the decoder. |
| `model.keep_batch_sharded=<bool>` | True | Each rank reads only its shard of the input. |

Environment variables:

| Variable | Default | Description |
| --- | --- | --- |
| `ANEMOI_HALO_COMM` | `p2p` | `p2p` sends point-to-point messages to the peers only. `a2a` uses one `all_to_all`. |
| `ANEMOI_DEBUG_SHARDING` | Not set | If set, each rank keeps the global node IDs of its halo and checks the plan against its peers. This adds collective communication. Use it only to find errors. |

For more GPUs for each model, the halo exchange keeps the communication small. But each rank then has less work, and the fixed costs of each layer become more important. Measure the throughput for some values of `num_gpus_per_model`.
