# R1h Independent One-Clean-Build Monitor Audit

## Scope

This is an independent, read-only audit of the sole authorized R1h full-build
invocation. The monitor did not invoke Vivado, send input to the running
process, alter the source worktree, or create a second build.

## Exact identity

- FACT — Source commit: `c4f4bfcf577c92c3021d1fe83c05878dd12e001c`.
- FACT — Source tree: `161e561f007912d73dba93c5ecd78e3cc3a6955b`.
- FACT — Direct parent: exact R1g commit
  `e112a5addb7ac62700a9a71af81bf368fad0bada`.
- FACT — Branch: `diag/v41-nvp-r1h-bram-backed-large-sample`.
- FACT — Commits above R1g: `1`.
- FACT — Source worktree was clean before launch and remained clean at the
  terminal observation.
- FACT — Prebuild manifest:
  `R1H_PREBUILD_MANIFEST.txt`, SHA-256
  `192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79`.
- FACT — Independent manifest rehash before launch: `224/224` tracked source
  records PASS and `32/32` accepted-log records PASS; zero missing, mismatched,
  or extra tracked source records.
- FACT — Build Tcl SHA-256:
  `2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18`;
  it matched the sidecar and manifest.
- FACT — Installed launcher:
  `C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat`, SHA-256
  `4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994`.
- NETLIST/TOOL-DERIVED FACT — The build's preconsumption receipt reports
  Vivado `2025.2`, software build `6299465`.

## Prelaunch gate

- FACT — Before launch, build root
  `C:\FPGA\BUILDS\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE` did not exist.
- FACT — Before launch, evidence root
  `C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\07_BUILD\FULL_BUILD` did not
  exist and no one-build-consumed sentinel existed.
- SOURCE-DERIVED FACT — Static command audit found exactly one textual command
  invocation each for `synth_design`, `opt_design`, `place_design`,
  `phys_opt_design`, `route_design`, and `write_bitstream`, with no retry path.
- CONCLUSION — `PRELAUNCH_INDEPENDENT_AUDIT=PASS`.

## Observed invocation and one-build consumption

- FACT — The sole invocation started on 2026-08-25 at approximately
  `00:43:09+02:00`.
- FACT — The independent monitor observed one process chain:
  `pwsh.exe PID 18612 -> cmd.exe PID 17280 -> vivado.exe PID 2468`.
- FACT — The Vivado command line bound all seven Tcl arguments to the exact
  source root, new build root, evidence root, source commit, source tree,
  prebuild manifest, and manifest SHA-256 listed above.
- FACT — The atomic marker
  `FULL_BUILD/R1H_ONE_CLEAN_BUILD_CONSUMED.marker` was created exactly once.
- FACT — Marker SHA-256:
  `58E940C3A916564E3A739CC2935AC8480CBB2662451D72AF51D32AA913EF2760`.
- FACT — Marker timestamp: `CONSUMED_UTC=2026-08-24T22:44:11Z`.
- FACT — The marker binds the exact R1h commit/tree, manifest hash, Vivado
  version, and software build, and states
  `CONSUMED_BEFORE_CREATE_PROJECT=YES`.
- CONCLUSION — `FULL_CLEAN_BUILDS_CONSUMED=1`; a retry is not authorized.

## Terminal evidence

- FACT — Terminal receipt:
  `FULL_BUILD/R1H_BUILD_TERMINAL_FAILURE.txt`.
- FACT — Terminal receipt SHA-256:
  `BC21A70F01CDBE4EAAA929326711E3A0E0C48BBF9EE31FF017513C003B2BD363`.
- TOOL-DERIVED FACT — Terminal stage: `PROJECT_SETUP`.
- TOOL-DERIVED FACT — Exact terminal error:
  `R1h probe-index BRAM wrapper is not before its probe consumer`.
- SOURCE-DERIVED FACT — The error is emitted by the frozen build Tcl compile
  order assertion when the queried synthesis compile-order index for
  `rtl/v41/r1h_probe_index_bram_store.sv` is not lower than the index for
  `rtl/v41/nvp_i2c_tri_phase_probe.sv`.
- TOOL-DERIVED FACT — Runtime accounting in the terminal receipt:
  `SYNTHESIS_RUNS=0`, `OPT_DESIGN_RUNS=0`, `PLACE_DESIGN_RUNS=0`,
  `ROUTE_DESIGN_RUNS=0`, `BITSTREAM_RUNS=0`.
- FACT — `R1H_BUILD_RESULT.txt` was not generated.
- FACT — No `.dcp` existed in the build or evidence roots at terminal
  inspection.
- FACT — No `.bit` existed in the build or evidence roots at terminal
  inspection.
- FACT — No `R1H_POST_SYNTH_RESOURCE_GATE.txt` was generated; therefore the
  BRAM primitive and LUT/FF resource gates were not executed and no R1h
  post-synthesis resource result exists.
- FACT — After termination, the independent monitor observed zero active
  `vivado.exe` processes.
- CONCLUSION — The flow failed closed before synthesis and before every
  implementation/bitstream operation. The failure is a build-script
  queried-compile-order assertion, not a synthesis, resource, timing, DRC, CDC,
  routing, or bitstream result.

## Evidence-file hashes at terminal state

| File | SHA-256 |
|---|---|
| `R1H_BOUND_PREBUILD_MANIFEST.txt` | `192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79` |
| `R1H_BUILD_TERMINAL_FAILURE.txt` | `BC21A70F01CDBE4EAAA929326711E3A0E0C48BBF9EE31FF017513C003B2BD363` |
| `R1H_EXPECTED_RUNTIME_PROVENANCE.txt` | `12EF4F38DF4110C92F6F6BA445454E33C1891CCB90E4984D45ACC611C8176EEE` |
| `R1H_FROZEN_INPUT_SHA256.txt` | `255BA77A23AACBB0AC84C56512C519794652DA3AB32B63F4926DF16F0E9166EC` |
| `R1H_ONE_CLEAN_BUILD_CONSUMED.marker` | `58E940C3A916564E3A739CC2935AC8480CBB2662451D72AF51D32AA913EF2760` |
| `R1H_PLANNED_SOURCE_AND_CONSTRAINT_ORDER.txt` | `30F802A1C909DF6DFC48753D809247715D58A6CF6ABE4328C9B13D8CB5AECCBC` |
| `R1H_PREBUILD_MANIFEST_BINDING.txt` | `2518FBD5DB4BB54BFA7619D8319CD87CDE3F6AD841628C8F7180F10122E1BA2E` |
| `R1H_PRECONSUMPTION_IDENTITY.txt` | `E601649552817725D6A334FA0E148AFA8C705B34F86D0F9DFEE6A1171CE114B7` |
| `R1H_XDC_ORDER_AND_SHA256.txt` | `4FD3CFB3E44C0A16048FC37450FA4048B120939228FA696D4A536A01A93C4359` |
| `R1H_XDMA_IMPORTED_PROPERTY_AUDIT.txt` | `B54B95D5B93F57A2FA14CDDED7212206452451F388679CFD5619761101B04A18` |

## Independent classification

```text
INDEPENDENT_BUILD_MONITOR_AUDIT=PASS
FULL_CLEAN_BUILDS_CONSUMED=1
TERMINAL_BUILD_STAGE=PROJECT_SETUP
TERMINAL_CLASSIFICATION=BLOCKED_ONE_CLEAN_BUILD_PROJECT_SETUP_COMPILE_ORDER_ASSERTION
SYNTHESIS_RUNS=0
OPT_DESIGN_RUNS=0
PLACE_DESIGN_RUNS=0
ROUTE_DESIGN_RUNS=0
BITSTREAM_RUNS=0
POST_SYNTH_RESOURCE_GATE=NOT_RUN
R1H_POST_SYNTH_RESOURCE_RESULT=NOT_AVAILABLE
R1H_DCP_GENERATED=NO
R1H_BITSTREAM_GENERATED=NO
BUILD_RETRY_AUTHORIZED=NO
BUILD_RETRY_RUN=NO
HARDWARE_ELIGIBLE=NO
```
