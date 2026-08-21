# Fail-Closed One-Build Checklist

This checklist applies to the sole clean diagnostic build for
`V41_NVP_I2C_25KHZ_PAIRED_AB_R1`.

## Before invoking Vivado

- The branch is `diag/v41-nvp-i2c-25khz-r1`.
- `HEAD` is one clean commit whose sole parent is
  `8464af66611f7c22b8a36a4aab915d598eedda3f`.
- The complete base-to-HEAD tracked diff is exactly one deletion and one
  insertion in `rtl/top/ahd_capture_top_xdma.sv`: the `I2C_HZ` connection is
  `50000 -> 25000`.
- The protected NVP files, XDMA XCI, pin/control XDC, register RTL/test/map, and
  `scripts/v41/phase3_build.tcl` match their frozen hashes.
- The numerical, cycle-count, transaction-stream, fault, reset, watchdog,
  control-status, AXI bridge, and 53-entry register-contract gates are all
  internally consistent and PASS. Invalid checker attempts remain labelled as
  invalid evidence and are not left in the canonical PASS location.
- The provenance-only run uses a separate, fresh evidence directory and the
  exact final source commit. It must not create the reserved full-build root.
- The full-build work root and full-build evidence root do not exist before the
  single invocation. The wrapper and build script hashes are recorded before
  launch.

## Exact build boundary

- Invoke the installed supported wrapper at
  `C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat`, after the installed
  `C:\AMDDesignTools\2025.2\Vivado\settings64.bat`.
- Invoke the unchanged `scripts/v41/phase3_build.tcl` with exactly five Tcl
  arguments: repository root, fresh build root, fresh evidence root, exact
  40-hex source commit, and `ahd_capture_v41_i2c_25khz_r1.bit`.
- Preserve a uniquely named full log and journal. Do not invoke the build a
  second time for any failure.

## Mandatory post-build parser gates

- Source: exact `HEAD`, exact parent, clean tree, exact one-line diff, all
  protected hashes unchanged.
- Provenance: source commit and five words reconstruct exactly; build flag is
  `0x00000002`; actual log identifies Vivado 2025.2 build 6299465; top and part
  are exact.
- Implementation: project creation, synthesis, implementation and route PASS;
  routed-net errors are zero in both the key/value result and raw route report.
- Timing: `WNS >= 0`, `WHS > 0`, `VDO_WNS > 0`, `VDO_WHS > 0`. The stock build
  script permits `VDO_WNS == 0`, so the independent parser must enforce the
  stricter task gate.
- DRC: errors zero, critical warnings zero, bus-skew violations zero.
- REQP-1839: derive the exact count from the raw DRC summary and cross-check the
  detail rows; require the count not to exceed the accepted baseline of four.
- CDC: derive the summary severities from the raw report; require Critical = 0
  and Unknown = 0. `CDC_CRITICAL_TYPES=0` from the stock script is necessary
  but is not, by itself, the complete task gate.
- Artifacts: nonempty synth DCP, routed DCP and diagnostic bit; record their
  SHA-256 values. Require the build input XCI copy and source XCI to retain the
  frozen SHA-256.

Run `verify_full_build_gates.ps1` after the sole build. Any missing report,
unparseable gate, mismatch, zero-margin violation, increased REQP-1839 count,
or provenance contradiction is a hard stop before hardware.

## Report-only supplements after a passing build

The preserved build script does not itself emit `report_power`, `report_io`,
or focused NVP fan-in/fan-out reports. Generate these, if required for the
task evidence, only by opening the exact routed DCP in a separate report-only
Vivado session. Do not synthesize, optimize, place, route, save a checkpoint,
or write another bitstream. These supplemental reports do not repair a failed
build gate.
