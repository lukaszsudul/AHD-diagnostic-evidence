# AHD v41 G2B NVP camera ACQ1 COMPAT0 R2R1 CONT1

## Result

- Engineering gate: `FAIL`
- Overall result: `FAIL`
- First failed gate: `R2R1GateError:SCAN1_CONFIGURATION_PROJECTION_INCOMPLETE`
- Physical camera gate: `NOT_REACHED`
- Functional NVP writes: `0`
- Unauthorized functional writes: `0`
- Rollback: `NOT_REQUIRED`
- Cleanup: `PASS`

## Completed continuation gates

The only DUT endpoint used was `192.168.1.57:22`. The endpoint change was treated as `NETWORK_ADDRESS_CHANGE_ONLY`; `10.132.1.111:22` was not contacted. Exact local source, DCP, bitstream, and runtime-bundle identities passed. The bundle was deployed and independently verified on the DUT. Fresh controller and DUT hardware locks passed. The exact bitstream was programmed once to volatile SRAM with `DONE=1`. Product-equivalent automatic NVP initialization passed with zero NACK and zero timeout. Exactly one graceful warm reboot was performed. The exact XDMA driver loaded and bound automatically to `0000:01:00.0`, `10ee:7011`, subsystem `10ee:0007`, at Gen2 x1.

SCAN1 and ACQ runtime identities passed. SCAN1 exposes 82 entries, 10 bank groups, the read-only oneshot mode, and 25 kHz I2C. ACQ exposes only CH1, Bank 5, registers 0x08 and 0x05, fixed slice actions, exact rollback, and no generic I2C, mode, or EQ capability. Autoinit, NVP reset release, disabled streaming, idle state, and zero functional-write state passed.

## First failure

The frozen pre-camera controller completed both 16-cycle MMIO sanity loops and then executed one SCAN1 ONESHOT. That scan completed 82/82 entries, 10/10 groups, and 105/105 transactions; `A8_PRE=A8_POST=0x0F`, entry bank and exit bank were both `0x00`, and entry-bank restore passed. While constructing its host-side configuration projection, the frozen controller required Bank 1 registers `0x88`, `0x89`, `0x8A`, and `0x8B`. Those four addresses are not members of the frozen 82-entry SCAN1 manifest. The controller therefore failed closed before publishing the required pre-camera PASS and before the 32-scan regression.

This is classified as `FROZEN_RUNTIME_CONTROLLER_MANIFEST_PROJECTION_CONTRADICTION`. It is not an I2C NACK, timeout, bank-restore failure, FPGA programming failure, runtime identity mismatch, camera-format result, or NVP write result.

## Safe terminal state

After the failure, a separate read-only gate proved scanner idle, executor idle, I2C idle, stream disabled, pending AIO zero, NACK zero, timeout zero, bank-verify failures zero, functional writes zero, unauthorized writes zero, and no current-boot PCIe AER/DPC error. No baseline, slice, format-identification, or rollback phase was entered. The driver was unloaded normally exactly once; all `/dev/xdma*` nodes disappeared; the DUT hardware lock was released. The diagnostic image remains only in volatile SRAM. No Flash programming, power-cycle, mode action, EQ action, capture, or persistent experiment write occurred.

## Required corrective action

Open a separately governed offline source task to reconcile `CONFIG_STABLE_ADDRESSES` with the frozen SCAN1 read manifest. Do not resume this hardware campaign from the failed image. After source correction, rerun the complete required offline qualification and create a new governed hardware candidate.
