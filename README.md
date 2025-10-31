# AIFS-RAPS

> \[!IMPORTANT\]
> This software is **Incubating** and subject to ECMWF's guidelines on [Software Maturity](https://github.com/ecmwf/codex/raw/refs/heads/main/Project%20Maturity).


DISCLAIMER This project is BETA and will be Experimental for the foreseeable future. Interfaces and functionality are likely to change, and the project itself may be scrapped. DO NOT use this software in any project/software that is operational.

AIFS-RAPS is a package for bootstrapping and benchmarking AIFS on different systems. 

RAPS (Real Applications on Parallel Systems), is a benchmarking initiative that was started in the 1990s by ECMWF and a number of weather and climate research centres. The goal of this initiative was the release of realistic benchmarks to vendors outside of the usual procurement framework. This enabled vendors to gain insights into the current and future developments of these applications over a longer time period than is otherwise available during procurements. 
For ease of use, AIFS-RAPS has been spun off into a standalone repository.

This version of AIFS-RAPS is based on the ensemble version of AIFS which went operational in July 2025 as 'AIFS ENS'
The AIFS is built on the Anemoi framework for building data-driven weather forecasting models, a collaborative effort led by European national meterological services. 

AIFS-RAPS handles some complexity of bootstrapping on different systems (e.g. offline installation, different ISA, running from a container). 
It provides interfaces to launch training and inference runs in a consistent manner and many examples of different benchmarking configurations.
It includes utility scripts to generate synthetic input data, post-process benchmarking runs and others.

AIFS-RAPS is intended to benchmark AIFS performance on different systems. It is not intended to launch scientific workflows. 

## Documentation
The documentation can be found [here](https://git.ecmwf.int/users/naco/repos/raps-doc/browse?at=anemoi-docs)

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


## Install (on ECMWFs system)

```
cd aifs-raps
./aifs-build --build-dir build --arch arch/ecmwf/hpc2020
cd launchers/SLURM/hpc2020
sbatch throughput.hpc2020.slurm
```
