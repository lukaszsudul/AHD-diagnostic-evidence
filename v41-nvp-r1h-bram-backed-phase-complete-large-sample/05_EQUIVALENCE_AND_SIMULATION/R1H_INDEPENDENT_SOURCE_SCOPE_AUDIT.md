# R1h independent source-scope and architecture audit

## Result

```text
AUDIT_CLASS=INDEPENDENT_READ_ONLY_SOURCE_AUDIT
R1G_PARENT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1G_PARENT_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
R1H_BRANCH=diag/v41-nvp-r1h-bram-backed-large-sample
AUTHORIZED_PRODUCTION_FILES_CHANGED=7
UNAUTHORIZED_PRODUCTION_FILES_CHANGED=0
SCIENTIFIC_CONSTANT_CHANGES=0
REGISTER_ADDRESS_OR_FIELD_CHANGES=0
FUNCTIONAL_PROBE_FSM_CHANGES=0
DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0_SOURCE_LEVEL
NEW_CLOCK_DOMAIN_CROSSINGS=0
SOURCE_SCOPE_AUDIT=PASS
SOURCE_COMMIT_RELEASE_BLOCKERS=0
FULL_BUILD_OR_IMPLEMENTATION_CLAIM=NOT_MADE
```

FACT: This audit was performed while `HEAD` was the exact clean R1g commit
`e112a5addb7ac62700a9a71af81bf368fad0bada`, tree
`3a59ebec130103055d24a3a32ecda00dedde5534`, with the proposed R1h delta still
uncommitted. The exact parent of R1g is
`225544084dbfcaadb8592fcecc947aa1cec4970e`.

FACT: Input identities carried into this audit are:

```text
R1G_EVIDENCE_COMMIT=31786f351a9b8aab86291b5058ce075da5fba46a
R1G_AUTHORITATIVE_REPORT_SHA256=6BD146E4B8A7C41BB6F407BC9FB4BAA42B4DA7767F6877EFD9DDF6BA3820638B
R1G_EVIDENCE_PACKAGE_SHA256=30B565A17B2E15D60321D549F93C0AA35D509D837A5C9DDCA5E2873915D3A7F5
RESOURCE_ATTRIBUTION_REPORT_SHA256=45A5E7BE82D94BFB781BA6726F3FBD47236CD551703542EE4964C6C392C2ACB6
RESOURCE_AUDIT_MANIFEST_SHA256=776A900D108880230CFFA4CC0BC1AF989858E3A2C0298C5F0B38B0DC310A691F
```

FACT: No source file was edited by this audit. No compile, synthesis,
`opt_design`, placement, routing, checkpoint write, bitstream, or hardware
action was run by this audit.

FACT: The existing simulation artifacts cited below identify Vivado Simulator
2025.2, SW build 6299465. This audit did not start a Vivado process.

## Exact change scope

SOURCE-DERIVED FACT: `git status --porcelain` and `git diff` against exact R1g
show five modified production files and two new production files:

| File | Classification | Audit result |
|---|---|---|
| `rtl/v41/r1f_failed_txn_logger.sv` | replace payload LUTRAM with six XPM block memories and a synchronous word read | authorized |
| `rtl/v41/nvp_i2c_tri_phase_probe.sv` | replace three index arrays with BRAM wrapper ports; make 30x32 block statistics resetless payload plus valid/live metadata | authorized |
| `rtl/v41/r1f_measurement_regs.sv` | classify record/index ranges without exporting payload data combinationally | authorized |
| `rtl/v41/control_status_regs.sv` | delegate diagnostic reads to the one-outstanding service while preserving write forwarding | authorized |
| `rtl/top/ahd_capture_top_xdma.sv` | integrate the storage read ports and read service | authorized |
| `rtl/v41/r1h_mmio_read_service.sv` | new synchronous one-outstanding diagnostic read sequencer | authorized |
| `rtl/v41/r1h_probe_index_bram_store.sv` | new three-bank 512x16 XPM block-memory wrapper | authorized |

SOURCE-DERIVED FACT: Ten modified and five new files under `tests/v41/` are
testbench/oracle/inference-wrapper files only. They adapt inherited tests to
synchronous reads or add the required architecture and protocol tests. No
other production path is modified.

SOURCE-DERIVED FACT: The following critical paths have no working-tree delta
from exact R1g:

```text
rtl/nvp/nvp6134c_i2c_bringup.vhd
rtl/nvp/r1f_transaction_serial_counter.vhd
scripts/v41/r1f_build.tcl
ip/v41/xdma_v41_m1.xci
xdc/**
```

The unchanged critical identities include:

| Path | SHA-256 | R1g equality |
|---|---|---|
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024` | exact |
| `rtl/nvp/r1f_transaction_serial_counter.vhd` | `FA92E1B52A5BB870EDBEDA5457A7021DB882AE9FF31DF880CBD97A6C7549019E` | exact |
| `scripts/v41/r1f_build.tcl` | `53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B` | exact |
| `ip/v41/xdma_v41_m1.xci` | `EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C` | exact |
| `xdc/boards/current/nvp_control.xdc` | `B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318` | exact |
| `xdc/boards/current/xdma_pcie.xdc` | `65568DD132FE9C65231BCE50CA5F7364702E303659DB36AAAA1057C318282F6A` | exact |
| `xdc/boards/current/pins.xdc` | `A8849CD13E75CAB2F509449617440ABE359BAA2B42ACAAE869BA25B581E6F8B9` | exact |
| `xdc/boards/current/vdo_input_timing.xdc` | `6B5E11BBB1556449CF00C85986FE77903B7852B495FCC3BE65D553C08E6E2E78` | exact |
| `xdc/common/cdc.xdc` | `E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62` | exact |
| `xdc/common/configuration_bank.xdc` | `3F94073A8054B28FA4168FC6137430058FAE4EA46B3C5D035AFE637D2A135C68` | exact |

SOURCE-DERIVED FACT: The NVP table, functional autoinit FSM, POR/start
watchdog, and SDA/SCL filter implementation are contained in the unchanged
`nvp6134c_i2c_bringup.vhd`; therefore their source text is exact R1g.

## Scientific constants and register contract

SOURCE-DERIVED FACT: An extracted signature containing every diagnostic map
case address, range boundary, magic/version/capability declaration, and the
frozen numerical map constants is identical between R1g and R1h:

```text
R1G_MAP_CONTRACT_EXTRACT_SHA256=5AD0F6F06FEE12558A13E889FDD9AFA92BCE558C53B9E1543444345889E0485D
R1H_MAP_CONTRACT_EXTRACT_SHA256=5AD0F6F06FEE12558A13E889FDD9AFA92BCE558C53B9E1543444345889E0485D
MAP_CONTRACT_EXTRACT_LINES=64
```

SOURCE-DERIVED FACT: An extracted signature containing all probe parameters,
safe-target bytes, phase encodings, divider/tick/block constants, and abort
codes is also identical:

```text
R1G_PROBE_CONSTANT_EXTRACT_SHA256=8B5D043EE4BEA702EDA33994B89DC09EF8C31AAED5D2768F37FE6627DAE94E5E
R1H_PROBE_CONSTANT_EXTRACT_SHA256=8B5D043EE4BEA702EDA33994B89DC09EF8C31AAED5D2768F37FE6627DAE94E5E
PROBE_CONSTANT_EXTRACT_LINES=83
```

Consequently the source retains 64x192 failed records, six words per record,
three 512x16 index logs, 10,000 target opportunities per phase, ten blocks of
1,000, the 12,000-attempt cap, the safe target bank/register/data 00/85/00,
and every address from 0x20A0 through 0x35FF.

SOURCE-DERIVED FACT: The complete low-level and high-level tri-phase probe FSM
case bodies are byte-identical to R1g:

```text
LOW_LEVEL_FSM_SHA256=27DCCBDE995D8D654B853C3E40C608032CC05F01D6C0BA0335F561A6AE082CA4
LOW_LEVEL_FSM_LINES=129
HIGH_LEVEL_FSM_SHA256=769F0ECC58C798CFA6C511904881CCEAF72BB67AD84832FC77028BFD23C37863
HIGH_LEVEL_FSM_LINES=106
```

## Failed-record store

SOURCE-DERIVED FACT: The logger contains six generated
`xpm_memory_sdpram` instances. Each is 64x32 (`MEMORY_SIZE=2048`), common
clock, simple dual port, forced block primitive, one-cycle synchronous read,
and one full-width write enable. All six see the same write enable and row;
their data inputs are the six disjoint 32-bit slices of one finalized 192-bit
record.

SOURCE-DERIVED FACT: `payload_write_enable` is asserted exactly when the R1g
record event is valid and `stored_count < 64`; the write row is
`stored_count[5:0]`. Thus events 1..64 write rows 0..63 atomically. Event 65
does not assert any payload write, leaves `stored_count` at 64, and sets
overflow. No path writes an already-stored row.

SOURCE-DERIVED FACT: The payload memories are not cleared. Reset clears the
write/count/overflow/first/last metadata and the output pipeline. A read
captures `(word < 6) && (index < stored_count)` at request time. The returned
word is forced to zero unless that captured predicate and response-valid are
both true. Old physical payload after reset and a simultaneous append to the
requested next row therefore remain logically invisible.

SOURCE-DERIVED FACT: Metadata update code for total count saturation, first
and last transaction indices, input record validation, stored count, and
overflow is semantically unchanged; the diff only nests it alongside the new
read pipeline.

SOURCE-DERIVED FACT: `WRITE_MODE_B="read_first"` defines a deterministic
read-during-write policy, but scientific correctness does not rely on it:
append-only operation never rewrites a valid row, and a concurrent read of the
new row uses the request-time `stored_count` snapshot and returns zero.

## Probe index stores and block statistics

SOURCE-DERIVED FACT: `r1h_probe_index_bram_store` has three independent
`xpm_memory_sdpram` banks, one per phase. Each bank is 512x16
(`MEMORY_SIZE=8192`), common clock, simple dual port, forced block primitive,
one-cycle synchronous read, and no payload reset. Invalid read/write phase
does not enable a bank; invalid reads complete with zero.

SOURCE-DERIVED FACT: On each NACK, the probe emits one delayed one-cycle write
pulse containing the pre-increment zero-based `target_opportunities` index.
It increments the retained stored count only while the configured capacity is
not full. Entry 512 (human count 512, address 511) is stored; NACK 513 produces
no payload write and sets overflow. Each phase has independent write enable,
count, overflow, and physical RAM.

SOURCE-DERIVED FACT: The read service captures the selected phase's stored
count at request acceptance, performs entry `2w`, then entry `2w+1`, and packs
`{odd,even}`. Each half is separately masked against the captured count, so an
unused half is zero and an append between the two BRAM cycles cannot alter the
transaction snapshot.

SOURCE-DERIVED FACT: The 30x32 completed-block payload is the only retained
`ram_style="distributed"` array. Its payload is not reset; 30 valid bits
provide logical zero. Three live counts, within-block positions, and block
indices replace the R1g division/modulo address calculation.

INFERENCE: The block-stat rewrite is equivalent by induction over target
outcome number `n`. Before outcome `n`, `block_current_index=floor(n/B)` and
`block_opportunity_position=n mod B`, where `B=1000`; the live count equals
the number of NACKs already observed in that partial block. A non-boundary
outcome updates the same live block. A boundary outcome first includes its own
NACK in `next_block_nack_count`, commits that value, marks it valid, and moves
to the next empty block. This is exactly the R1g rule that increments
`block_nack_count[floor(n/B)]` on a NACK. After the 10,000th opportunity all
ten blocks are committed and reads select the same counts. Reset clears valid
and live metadata, making stale payload invisible.

## MMIO protocol and write forwarding

SOURCE-DERIVED FACT: `v41_r1h_mmio_read_service` has exactly five states:
IDLE, RECORD_WAIT, INDEX_LOW_WAIT, INDEX_HIGH_WAIT, and RESPONSE.
`req_ready` is true only in IDLE. `rsp_valid` is true only in RESPONSE, and
RESPONSE is retained until `rsp_ready`. Therefore a second request cannot be
accepted while a memory read or response is pending; data and valid remain
stable under backpressure.

SOURCE-DERIVED FACT: Scalar data is registered at acceptance. A record read
issues one BRAM request and waits for its valid pulse. An index word issues
two ordered reads and waits for each valid pulse. Response order cannot differ
from request order because there is no queue and only one request can be
outstanding.

SOURCE-DERIVED FACT: The unchanged `v41_axi_lite_host_bridge` is itself a
single-transaction state machine. It cannot have a local, R1h, and app
response outstanding simultaneously. This justifies the fixed response
priority in `control_status_regs` and prevents cross-source response
consumption.

SOURCE-DERIVED FACT: `r1h_read_select` contains `!host_req_write`. Every write
in 0x20A0..0x35FF therefore has `local_select=0`, drives `app_req_valid`, and
cannot assert `r1h_req_valid`. Address, data, byte enables, and direction are
passed unchanged. The diagnostic page remains locally read-only.

SOURCE-DERIVED FACT: Alignment behavior is preserved inside
`r1f_measurement_regs`: any `offset[1:0] != 0` clears all submodule selects and
returns zero. Reserved aligned addresses likewise retain the R1g scalar-zero
default. The response status remains the bridge's unchanged OKAY status.

## Functional isolation, clock, and reset

SOURCE-DERIVED FACT: `autonomous_clk` is an exact wire alias of `axi_aclk` in
the top level. All new request, response, logger-read, and index-read signals
are synchronous to that same net. No new clock-domain crossing is introduced.

SOURCE-DERIVED FACT: Host-originated record/index read signals fan out only to
payload read ports and the MMIO response service. BRAM read data fans out only
to that response service. The new block-stat state fans out only to the
diagnostic read value. None of these signals reaches the low-level or
high-level probe state transition conditions, NVP autoinit, SCL/SDA release
outputs, reset/power controls, or functional video path.

SOURCE-DERIVED FACT: The probe-index payload and failed-record payload response
pipelines are reset by `nvp_por_reset`. The final top-level integration resets
the R1h service with `(~axi_aresetn) || nvp_por_reset`, so the service cannot
issue or consume a payload response while either its AXI protocol domain or
the storage response pipelines are reset. `req_ready` and `rsp_valid` are also
combinationally gated with `!reset`; a pending response is cancelled and no
request can be accepted during reset.

SOURCE-DERIVED FACT: Payload RAM bits intentionally are not cleared by reset.
Count/valid metadata masks those bits, and the XPM output pipelines receive
`nvp_por_reset`. On a later AXI-only reset the storage metadata remains valid,
the read service is cancelled, and the one-cycle memory-valid outputs
self-clear whenever its request pulse is absent. A stale memory-valid pulse
cannot be consumed in IDLE; only a fresh accepted request can enter a WAIT
state.

FACT: The independent audit rejected reset regression run 01 despite process
exit zero and a trailing PASS footer because its log contained a `FAIL:` token.
The failure was a stale test assertion against global `host_req_ready`, not a
production RTL failure. The assertion was corrected to check the R1h service
ready/valid interface. Run 02 completed with exit zero, a PASS footer, and no
`FAIL`, `Fatal`, or `ERROR` token. This history demonstrates that log-content
gating, not exit/PASS alone, was used.

## Existing verification evidence checked by this audit

FACT: The exact R1g map oracle in
`tests/v41/r1g_measurement_regs_reference.sv` is byte-identical to the R1g
source after only two module-name substitutions. The normalized SHA-256 is
`51057B8BF4BCC31B67AF112A45665FF3B95469FFF7034D06B46A71130858E8E2`.

FACT: Existing simulation logs for the frozen source hashes report:

```text
FAILED_RECORD_64_X_6_WORDS_AND_ATOMIC_WRITE=PASS
FAILED_RECORD_OVERFLOW_ON_65=PASS
FAILED_RECORD_UNUSED_ZERO=PASS
MMIO_SERVICE_BACKPRESSURE_AND_RESET=PASS
MMIO_COMPLETE_RANGE_ALIGNED_READS=1368_OF_1368
MMIO_COMPLETE_RANGE_UNALIGNED_ZERO_READS=4104_OF_4104
MMIO_COMPLETE_RANGE_FORWARDED_WRITES=1368_OF_1368
PROBE_INDEX_DIRECT_STORE_READS=1536_OF_1536
INHERITED_TRI_PHASE_PROBE_MATRIX=PASS_7_OF_7
PRODUCTION_BLOCK_CURSOR_AND_30_BLOCK_VALUES=PASS
PRE_INIT_OPEN_DRAIN_ARBITRATION=PASS
```

The principal exact log/report identities are:

| Evidence | SHA-256 |
|---|---|
| failed-record XSim log | `F294D27395B0FF9B5E9666AE2639861A0DE8BB4DE99A789669845CDF48C01017` |
| final reset-coherent MMIO-service XSim log | `4479BD039180B0D7EED39A2963DBBF34B7B85BB549DB8D1DD5B6566CBC0D752D` |
| final reset-coherent exhaustive MMIO XSim log | `A26C1F98E17F1DB42E1DBB5ABB677AF8626EBE0F71EA100940A2990E7EBD3977` |
| probe BRAM/block-stat verification report | `2A41F04EFE929256148C2B411ECBB40852C5178FFFB6FEDD63C129460816D9A4` |
| 1,536-entry store XSim log | `5251AA1AD0218791F9BB9D04B05BC87273357D6367F4C0419BB8AA94E79254DC` |
| main probe XSim log | `A49D7F72F6320BE399188A5ACF7BFF71CB7AC3F28007D8ED1F91FFA992AEDE04` |
| production-timing XSim log | `27AC9B4AB2CA92CCFFECFC4FBCA12F6B909525B5DBCC5AC9D92FD574030D5A10` |

The final reset-coherent transaction tests used:

```text
2EA788E5A9CA5D9F5663A0A1595009BDB20D7D1F81F8BE917721F79BFE802B40  tests/v41/tb_r1h_mmio_read_service.sv
6DE31F62629E0C64D35700DD1A57193C5F4240A224B4BF4763D69076FD61BD68  tests/v41/tb_r1h_mmio_integration_exhaustive.sv
```

Both `reset_liveness_regression_02/service/xsim.exit.txt` and
`reset_liveness_regression_02/integration/xsim.exit.txt` record
`PROCESS_EXIT_CODE=0`.

## Frozen proposed production-file hashes

```text
D37A7ECC4C4335149428A75FFE71E0C2FA128F69AEA8E0781658DD22ED65623E  rtl/top/ahd_capture_top_xdma.sv
FAD14CD8E56BCE583FDD643C1828D03A6673ADE22A0B66EE0ED490C48C0F33DD  rtl/v41/control_status_regs.sv
D459FC7AE6D72F1B604974CADDF4D633468334D9D488818746A0C0B5EE22B4DD  rtl/v41/nvp_i2c_tri_phase_probe.sv
F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761  rtl/v41/r1f_failed_txn_logger.sv
EC246486BD0F5DF0966F6DC81BC8A8EAC17741E2641F8DFE68E276EDBE567542  rtl/v41/r1f_measurement_regs.sv
00ECE27375BE07D52E8FA4BF07F535AB29DC39A099AF4FC148BF654E0073BA2B  rtl/v41/r1h_mmio_read_service.sv
67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F  rtl/v41/r1h_probe_index_bram_store.sv
```

FACT: These hashes are the acceptance boundary for this audit. Any later
source edit invalidates `SOURCE_SCOPE_AUDIT=PASS` and requires rerunning this
audit before the one permitted commit.

## Limitations and mandatory later gates

UNAVAILABLE: This source-only audit does not prove integrated primitive counts,
total LUT/FF headroom, timing, DRC, CDC report results, or commit-to-bit
provenance. Those remain mandatory post-synthesis/full-build gates.

UNAVAILABLE: The unchanged repository file `scripts/v41/r1f_build.tcl` does
not by itself name the two new R1h modules. The separately audited task-local
R1h build driver must read both new files before their consumers. This is a
prebuild command-list gate, not a source-scope defect.

INFERENCE: Existing bounded OOC evidence is consistent with the requested
physical architecture (six record RAMB18 plus three index RAMB18), but only
the one permitted full-project post-synthesis checkpoint may satisfy the
authoritative primitive and total-resource gates.

## Final classification

```text
SOURCE_CHANGE_CLASS=AUTHORIZED_STORAGE_MMIO_AND_TEST_ONLY
SCIENTIFIC_SCOPE_REDUCTION=NO
FAILED_RECORD_APPEND_OVERFLOW_ZERO_SEMANTICS=PRESERVED
PROBE_INDEX_APPEND_OVERFLOW_ZERO_SEMANTICS=PRESERVED
BLOCK_STATISTICS_SEMANTICS=PRESERVED_SOURCE_PROOF_AND_TEST
MMIO_READ_SERVICE=SYNCHRONOUS_ONE_OUTSTANDING
MMIO_VALUES_ORDER_STATUS=PRESERVED_BY_TRANSACTION_TEST
R1H_RANGE_WRITES_FORWARDED=YES
NEW_CDC=NO
DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0_SOURCE_LEVEL
XDC_CHANGED=NO
XDMA_XCI_CHANGED=NO
NVP_TABLE_CHANGED=NO
FUNCTIONAL_FSM_CHANGED=NO
POR_WATCHDOG_CHANGED=NO
SDA_SCL_FILTERS_CHANGED=NO
INDEPENDENT_SOURCE_SCOPE_AUDIT=PASS
BLOCKERS=NONE_AT_SOURCE_SCOPE
```
