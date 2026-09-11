# Scope and hard boundary

## In scope

Pinned reference-source identity; local NVP6134C register authority; current-v41 read-only gap audit; reference detection/mode/EQ semantic extraction; register safety; SCAN1, host, ACQ1 and CAM1 design freeze; deterministic offline tests; sanitized evidence publication.

## Explicitly out of scope

DUT contact, `/dev/xdma*`, PCIe configuration, MMIO, hardware I2C, JTAG, bitstreams, programming, resets/reboots/power cycles, driver/module/process/lock changes, Vivado, synthesis, implementation, builds, captures, DMA/AIO, raw frames, source edits, PRODUCT edits, SSOT/META changes, and copying or publishing third-party source/PDF content.

`Engineering gate` and `Evidence publication` are independent. Unknown private-register meanings are retained as uncertainty; they are never promoted to NVP6134C proof.
