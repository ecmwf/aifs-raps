# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

"""Lightweight training timer for AIFS-RAPS.

Measures the training steps after a warm-up (torch.compile, dataloader start)
and prints one summary line on rank 0, which bin/aifs-jobinfo reads:

    AIFS-RAPS benchmark: warmup_steps=10 measured_steps=190 measured_time_s=... steps_per_s=... ...

The GPU is synchronised only at the start and the end of the measured window,
so the timer does not change the overlap of the steps.
"""

from __future__ import annotations

import logging
import time

import pytorch_lightning as pl
import torch

LOGGER = logging.getLogger(__name__)


class BenchmarkTimer(pl.Callback):
    def __init__(self, warmup_steps: int = 10) -> None:
        super().__init__()
        self.warmup_steps = warmup_steps
        self.steps = 0
        self.first_step_start = None
        self.window_start = None
        self.window_end = None
        self.measured_steps = 0

    @staticmethod
    def _sync() -> None:
        if torch.cuda.is_available():
            torch.cuda.synchronize()

    def on_train_batch_start(self, trainer, pl_module, batch, batch_idx) -> None:
        if self.first_step_start is None:
            self.first_step_start = time.perf_counter()
            if torch.cuda.is_available():
                torch.cuda.reset_peak_memory_stats()
        if self.steps == self.warmup_steps:
            self._sync()
            self.window_start = time.perf_counter()

    def on_train_batch_end(self, trainer, pl_module, outputs, batch, batch_idx) -> None:
        self.steps += 1

    def on_validation_start(self, trainer, pl_module) -> None:
        # Stop before the first validation, so the window contains only training steps
        self._stop_window()

    def on_train_end(self, trainer, pl_module) -> None:
        self._stop_window()
        if trainer.global_rank == 0:
            self._report(trainer, pl_module)

    def _stop_window(self) -> None:
        if self.window_start is not None and self.window_end is None and self.steps > self.warmup_steps:
            self._sync()
            self.window_end = time.perf_counter()
            self.measured_steps = self.steps - self.warmup_steps

    def _report(self, trainer, pl_module) -> None:
        values = {"warmup_steps": self.warmup_steps, "total_steps": self.steps}

        measured = self.measured_steps
        if self.window_end is not None and measured > 0:
            elapsed = self.window_end - self.window_start
            steps_per_s = measured / elapsed
            values.update(
                measured_steps=measured,
                measured_time_s=f"{elapsed:.3f}",
                steps_per_s=f"{steps_per_s:.4f}",
                warmup_time_s=f"{self.window_start - self.first_step_start:.3f}",
            )
            try:
                config = pl_module.config
                gpus_per_model = int(config.system.hardware.num_gpus_per_model)
                batch_size = int(config.dataloader.batch_size.training)
                model_instances = max(trainer.world_size // gpus_per_model, 1)
                values.update(
                    global_batch_size=batch_size * model_instances,
                    samples_per_s=f"{steps_per_s * batch_size * model_instances:.4f}",
                )
            except (AttributeError, KeyError, TypeError, ValueError):
                LOGGER.warning("AIFS-RAPS benchmark: cannot find the batch size, samples_per_s not given")
        else:
            LOGGER.warning(
                "AIFS-RAPS benchmark: only %d steps, not more than warmup_steps=%d. No throughput.",
                self.steps,
                self.warmup_steps,
            )

        if torch.cuda.is_available():
            values["peak_gpu_mem_mib"] = f"{torch.cuda.max_memory_allocated() / 2**20:.0f}"

        line = " ".join(f"{k}={v}" for k, v in values.items())
        # print, not LOGGER: the line must be in out.txt whatever the logging config is
        print(f"AIFS-RAPS benchmark: {line}", flush=True)
