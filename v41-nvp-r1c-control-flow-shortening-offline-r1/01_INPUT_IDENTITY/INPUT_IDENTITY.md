# Input identity

Audit mode: offline, existing evidence only. No network, hardware, build, source edit, or repository mutation was used for this identity gate.

## Evidence repositories

| Evidence set | Required commit | Object present locally | Commit tree | Result |
|---|---|---:|---|---|
| Historical R1 lifecycle measurement | `cbe2cee94c3b8fd7b8b6c13e6978bc26bc903c7c` | YES | `828b5a5ef1e705f3d001024aabf5ece98522b3c7` | PASS |
| R1c paired A/B | `2c86f792bb439279d2eca69d87c21125f99bf63f` | YES | `6514427f62d310e2f7205fd555a08a1fe7476147` | PASS |

The four R1c telemetry worktree files hash to the exact Git blobs at the R1c evidence commit. Their SHA-256 values are recorded in `INPUT_SHA256.txt`.

## Source commits and trees

| Role | Commit | Tree | Local object result |
|---|---|---|---|
| Formal Phase 2 | `c89e88bcdf389614c884fb129e8b2d42a585bccb` | `417820c69c134161fcafae0947dc5976919814d1` | PASS |
| Historical R1 measurement | `0af44dee3bc091eaff805704dd5c687eeaa01bbd` | `69154c1257c226c8cddacf4d8e1e9badbbd91c46` | PASS |
| R1c Arm A 25 kHz | `f007dc172d43d30b02729755e60382f8ce3dbff4` | `b8f87966c8021396acb6341bd2d7d86a10fd7f13` | PASS |

Parentage was also verified from the commit objects:

- R1 is a direct child of formal checkpoint `c89e88bcdf389614c884fb129e8b2d42a585bccb`.
- R1c source is a direct child of provenance-correct base `8464af66611f7c22b8a36a4aab915d598eedda3f`.

## Bitstream identities rehashed locally

| Role | Existing bounded local artifact | Size (bytes) | SHA-256 | Result |
|---|---|---:|---|---|
| Historical R1 | `C:\FPGA\V41_NVP_AXI_CLOCK_MEASURE_R1\05_BUILD\evidence\artifacts\ahd_capture_v41_axi_clock_measure_r1.bit` | 2192144 | `4C169486BCEA09F0C76213C88CF675317C8F30C4DD887EDC4B8989D8E72EF5DB` | PASS |
| R1c Arm A | `C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\04_BUILD\FULL_BUILD_EVIDENCE\artifacts\ahd_capture_v41_i2c_25khz_r1.bit` | 2192144 | `B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191` | PASS |
| R1c Arm B formal | `C:\FPGA\FPGA_AHD_v41_V40_1_0_PHASE2_EVIDENCE\02_FRESH_BUILD\SEALED\artifacts\ahd_capture_v41_phase2_p1.bit` | 2192144 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | PASS |

## R1c sealed evidence

The existing repository ZIP was rehashed in place:

```text
PATH=C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\AHD-diagnostic-evidence\v41-nvp-i2c-25khz-paired-ab-r1c\V41_NVP_I2C_25KHZ_PAIRED_AB_R1C_MEASUREMENT_EVIDENCE.zip
SIZE_BYTES=208334
SHA256=9B8AF29EEDFF10775F747F28BDF5B208A1C87AF82EF22A156129DF4ABE992D19
RESULT=PASS
```

## Protected NVP source blobs

The following Git blob identities are identical at formal Phase 2, R1, and R1c Arm A:

| Path | Git blob |
|---|---|
| `rtl/nvp/nvp6134c_autoinit.vhd` | `5dc0230cd569f03d68452055db6b10c5fcade751` |
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `cfe33464d8e75c514462786593b278d90b4059a4` |
| `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` | `7ddd60fc86da49cda1adcd7af7b772b337c95df6` |

## Gate result

```text
INPUT_IDENTITY=PASS
BLOCKED_INPUT_IDENTITY=NO
```
