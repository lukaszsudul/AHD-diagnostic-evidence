# R3R4R6 Prequeue Architecture

The task-local source implements two 4096-byte-aligned, prefaulted buffers and
raw Linux AIO syscalls (`io_setup`, `io_submit`, `io_getevents`, `io_destroy`).
It orders a 10,240,000-byte primary request before a 4,194,304-byte guard
request and emits metadata-only `PREQUEUE_READY` only after both submissions.
The parent owns MMIO and requires that receipt before enable. Raw data is
persisted only after DMA completion/quiescence.

Static focused checks passed for ordering, MMIO dependency, absence of signal
interruption, absence of `O_TRUNC`/`eop_flush`, and separation of integrity,
continuity, source diagnostics, and byte accounting. Native compilation was
not established, so this architecture was not executed on hardware.
