# AIFS-RAPS

> \[!IMPORTANT\]
> This software is **Incubating** and subject to ECMWF's guidelines on [Software Maturity](https://github.com/ecmwf/codex/raw/refs/heads/main/Project%20Maturity).


DISCLAIMER This project is BETA and will be Experimental for the foreseeable future. Interfaces and functionality are likely to change, and the project itself may be scrapped. DO NOT use this software in any project/software that is operational.

AIFS-RAPS is a package to benchmark AIFS training and inference on different systems.

RAPS (Real Applications on Parallel Systems) is a benchmark initiative. ECMWF and other weather and climate centres started it in the 1990s. RAPS gives realistic benchmarks to vendors outside of procurements. Vendors can then see how these applications change over a long period.

AIFS is the ECMWF data-driven forecast model. It uses the [Anemoi](https://anemoi.readthedocs.io) framework. AIFS-RAPS uses the `feat/raps-update-oct26` branch of [anemoi-core](https://github.com/ecmwf/anemoi-core/tree/feat/raps-update-oct26).

AIFS-RAPS contains:

- Hydra configs for benchmarks at different resolutions (`configs/`).
- Scripts that run a training or an inference benchmark and keep the results (`bin/train`, `bin/inf`).
- Launchers for SLURM and for interactive runs (`launchers/`).
- Tools to examine the results (`bin/`).

AIFS-RAPS does not install software. You must supply a Python environment that contains anemoi-core.

You do not need input data. The configs use synthetic data by default. Refer to [docs/configs.md](docs/configs.md#input-data).

Do not use AIFS-RAPS for scientific work. Use it only to measure performance.

## Quick start

1. Make a Python environment that contains anemoi-core. Refer to [docs/environment.md](docs/environment.md).
2. Make an environment file for your system. Use `env/ecmwf-ag.sh` as an example.
3. Do a test run:

   ```bash
   export AIFS_ENV=$PWD/env/ecmwf-ag.sh
   launchers/INTERACTIVE/train o96
   ```

4. Submit a benchmark:

   ```bash
   cd launchers/SLURM/ag
   sbatch train_o1280.slurm
   ```

5. Examine the results in `$AIFS_OUTPUT_DIR/train/<run>/jobinfo.csv`.

## Documentation

<!-- not-in-html -->
[docs/index.html](docs/index.html) shows all documents as one web page. It reads the Markdown files below. It is published at <https://ecmwf.github.io/aifs-raps/>. To read a local copy, open it through a web server:

```bash
python3 -m http.server 8000
```

Then open <http://localhost:8000/docs/>.
<!-- /not-in-html -->

| Document | Contents |
| --- | --- |
| [docs/environment.md](docs/environment.md) | Make the Python environment and the environment file. |
| [docs/running.md](docs/running.md) | Run a benchmark. |
| [docs/configs.md](docs/configs.md) | The benchmark configs. |
| [docs/results.md](docs/results.md) | The run directory and the performance values. |
| [docs/inference.md](docs/inference.md) | Run inference. Model sharding and parallel output. |
| [docs/performance-tuning.md](docs/performance-tuning.md) | Settings that change the performance. |
| [docs/parallelism.md](docs/parallelism.md) | Data parallelism, model sharding and the halo exchange. |
| [docs/precision.md](docs/precision.md) | Training precision. The explicit bf16 precision (`bf16-fp32-opt`). |
| [docs/containers.md](docs/containers.md) | Run with a container image. |

## License
```
Copyright 2025-, ECMWF.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

In applying this licence, ECMWF does not waive the privileges and immunities
granted to it by virtue of its status as an intergovernmental organisation
nor does it submit to any jurisdiction.
```
