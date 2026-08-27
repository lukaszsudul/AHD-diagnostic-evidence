# R1i–R2 Reproduction Guide

This guide describes the scientific flow without credentials or site-specific access details. It authorizes no action by itself. Use only approved hardware procedures and volatile FPGA programming; never program configuration flash.

## Required identities

- FPGA source commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Source tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- R1h base/control source: `c4f4bfcf577c92c3021d1fe83c05878dd12e001c`
- Vivado: 2025.2 build 6299465
- FPGA part/top: `xc7a35tcsg325-2` / `ahd_capture_top_xdma`
- Exact bitstream hashes: see [source provenance](R1I_R2_SOURCE_PROVENANCE.md)

## Build environment

The successful build used a short ASCII-only workspace and a child-only Vivado environment:

```text
XILINX_LOCAL_USER_DATA=NO
XILINX_TCLAPP_REPO=C:/AMDDesignTools/2025.2/Vivado/data/XilinxTclStore
TEMP=<short ASCII-only isolated directory>
TMP=<same directory>
```

Use the committed `scripts/v41/r1i_build.tcl` flow without source, XDC, IP, or directive changes. The published bitstream can be reviewed without rebuilding.

## Hardware flow

1. Verify the exact Formal Phase-2 read-only baseline and approved driver/device identity.
2. Volatile-program the exact R1i bitstream; prove same-session and independent DONE.
3. Follow the frozen reboot/driver procedure and prove R1i runtime source identity.
4. Read telemetry without DMA and complete exactly 10,000 opportunities in each WADDR, REGADDR, and DATA phase.
5. Persist all A1 telemetry before image change.
6. Volatile-program the exact R1h control; repeat the same identity, reboot, and 10,000-per-phase measurement.
7. Restore the exact Formal Phase-2 image and prove its runtime identity and diagnostic magic zero.
8. Hard stop.

Autoinit and post-init counters must remain separate. Completion is 60,000 total post-init phase observations, not the historical R1h-R4 value of 90,000. Do not introduce retries, alter A/B semantics, or discard first-attempt NACKs outside the frozen firmware behavior.
