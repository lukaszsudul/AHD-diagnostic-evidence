# R1h-to-R1i Changeset

## Exact range

- Base: `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` (R1h)
- Candidate: `20c3323d79d3896edc586d6db1df7deee60f9e41` (qualified R1i)
- Exact patch: [R1H_TO_R1I_SOURCE.patch](R1H_TO_R1I_SOURCE.patch)

## Functional RTL changes

| File | Module/role | R1h behavior | R1i behavior |
| --- | --- | --- | --- |
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | Legacy NVP I²C master | Released SCL and sampled SDA on the same state transition; continued later transaction phases after NACK | Waits for filtered physical SCL high, samples in a later state, stops at first qualified NACK, retries with bounded backoff, and records causal/recovery telemetry |
| `rtl/nvp/nvp6134c_autoinit.vhd` | Initialization sequencer | Legacy NACK/error exports | Exports qualified/retry/recovery telemetry while preserving table behavior |
| `rtl/top/ahd_capture_top_xdma.sv` | Top-level integration | R1h observability through `0x35ff` | Connects R1i telemetry and overlays only unused `0x3600..0x367f` |
| `rtl/v41/control_status_regs.sv` | Read-only control/status mux | No R1i page | Implements the compact read-only R1i scalar page |

The retry limit is three retries (four total attempts), with fixed 100 µs, 500 µs, and 2,000 µs base-clock backoffs. A qualified-high timeout follows the same STOP/retry path. Recovered transactions remain visible without latching terminal `INIT_ERROR`; exhausted transactions preserve terminal error behavior.

## Supporting reproducibility and tests

The range also adds the R1i build script, child-local portable Vivado launcher, read-only decoder, Python fixtures, master adapter, focused simulation runner, and testbenches for qualified ACK/read timing, first-NACK abort, retries, timeout, bank safety, and MMIO compatibility.

## Hypothesis tested

The combined PoC tested whether physically qualified high-phase sampling plus bounded readiness recovery would prevent the autoinit failure observed with R1h. The hardware result confirms the combined implementation functionally, but does not isolate which sub-mechanism was decisive.

## Intentionally unchanged

- NVP initialization table and 25 kHz I²C setting;
- reset/start/final-settle policy;
- SDA/SCL synchronizer and filter implementation;
- R1h failed-transaction record format and tri-phase probe behavior;
- all existing MMIO addresses through `0x35ff`;
- XDC constraints, pins, I/O electrical properties, XDMA XCI/configuration, capture protocol, and unrelated datapaths.

No large payload memory was added. The new telemetry page is read-only.
