# R1h independent precommit release audit

## Outcome

The exact uncommitted R1h candidate snapshot identified below satisfies the
fail-closed precommit source, architecture, simulation, host-tool, and static
build-flow gates. This release authorizes only creation of the single direct
child commit of exact R1g. It is not a full-build, resource-margin,
implementation, bitstream, or hardware release.

```text
PRECOMMIT_RELEASE=PASS
BLOCKERS=NONE
R1H_PARENT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
AUTHORIZED_CHANGED_PATHS_ONLY=YES
SOURCE_WORKTREE_DIFF_CHECK=PASS
R1H_BUILD_TCL_STATIC_AUDIT=PASS
```

## Audit identity and action boundary

```text
TASK=V41_NVP_R1H_BRAM_BACKED_PHASE_COMPLETE_OBSERVABILITY_AND_LARGE_SAMPLE_AB
AUDIT_CLASS=INDEPENDENT_FAIL_CLOSED_PRECOMMIT_RELEASE
REFERENCE_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
REFERENCE_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
REFERENCE_PARENT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1E_BASE=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
CANDIDATE_BRANCH=diag/v41-nvp-r1h-bram-backed-large-sample
CANDIDATE_HEAD_DURING_AUDIT=e112a5addb7ac62700a9a71af81bf368fad0bada
VIVADO_EVIDENCE_VERSION=2025.2_BUILD_6299465
R1H_SOURCE_COMMIT=NOT_YET_CREATED
RELEASE_BOUNDARY=EXACT_UNCOMMITTED_SNAPSHOT_HASHES_IN_THIS_REPORT
```

The auditor performed read-only Git/source/evidence inspection and wrote only
this task-local report. The auditor did not edit the source worktree, run a
compiler or simulator, invoke synthesis or implementation, create a commit,
push, or touch hardware.

## P0 exact-input gate

FACT: the exact R1g source topology was independently rechecked. R1g is commit
`e112a5addb7ac62700a9a71af81bf368fad0bada`, tree
`3a59ebec130103055d24a3a32ecda00dedde5534`, directly above exact R1f
`225544084dbfcaadb8592fcecc947aa1cec4970e`; exact R1e is
`f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd`.

FACT: the frozen input identities and fresh read-only verification receipts are:

| Input | Exact identity/result |
|---|---|
| owner prompt | SHA-256 `870B78B78A37AB09486DC63CCADB81C5F4CB1398C02DDE935D35BF89B5DEDB9A` |
| R1g public evidence commit | `31786f351a9b8aab86291b5058ce075da5fba46a` |
| R1g authoritative report | SHA-256 `6BD146E4B8A7C41BB6F407BC9FB4BAA42B4DA7767F6877EFD9DDF6BA3820638B` |
| R1g evidence ZIP | SHA-256 `30B565A17B2E15D60321D549F93C0AA35D509D837A5C9DDCA5E2873915D3A7F5` |
| R1g evidence manifest/ZIP | `PASS_1120_OF_1120_PLUS_EXACT_MANIFEST`; ZIP entries `1121`; public remote and secret scan PASS |
| resource-attribution report | SHA-256 `45A5E7BE82D94BFB781BA6726F3FBD47236CD551703542EE4964C6C392C2ACB6` |
| resource-audit manifest | SHA-256 `776A900D108880230CFFA4CC0BC1AF989858E3A2C0298C5F0B38B0DC310A691F`; `PASS_61_OF_61` |

The resource audit was task-local and had no publication commit or package;
those unavailable identities were not inferred or replaced with the R1g input
identities. P0 is PASS.

## Exact candidate path scope and content boundary

FACT: immediately before this report, the candidate had zero staged paths,
15 modified tracked paths, seven untracked paths, and exactly 22 unique changed
paths. The set equals the authorized R1h production/test path set exactly.
`git diff --check` returned zero.

| SHA-256 | Authorized path |
|---|---|
| `D37A7ECC4C4335149428A75FFE71E0C2FA128F69AEA8E0781658DD22ED65623E` | `rtl/top/ahd_capture_top_xdma.sv` |
| `FAD14CD8E56BCE583FDD643C1828D03A6673ADE22A0B66EE0ED490C48C0F33DD` | `rtl/v41/control_status_regs.sv` |
| `D459FC7AE6D72F1B604974CADDF4D633468334D9D488818746A0C0B5EE22B4DD` | `rtl/v41/nvp_i2c_tri_phase_probe.sv` |
| `F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761` | `rtl/v41/r1f_failed_txn_logger.sv` |
| `EC246486BD0F5DF0966F6DC81BC8A8EAC17741E2641F8DFE68E276EDBE567542` | `rtl/v41/r1f_measurement_regs.sv` |
| `00ECE27375BE07D52E8FA4BF07F535AB29DC39A099AF4FC148BF654E0073BA2B` | `rtl/v41/r1h_mmio_read_service.sv` |
| `67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F` | `rtl/v41/r1h_probe_index_bram_store.sv` |
| `58AB2C44693FA89B60430B583B4FB117FD41EEE5C69359F170BA644B728AC686` | `tests/v41/r1g_measurement_regs_reference.sv` |
| `7B77B07339ADA100B43348316877EF6CCB1C636DFF8671DCCAA6C6045E1A6B82` | `tests/v41/r1h_memory_inference_top.sv` |
| `128EF41613C1B13A4E394D3F1722C085DDDA21CFF702995A0515C1F1248B6A34` | `tests/v41/tb_nvp_i2c_tri_phase_probe.sv` |
| `8539D5378624738EA4D2FBCF94203AE36C8A76526C9FA822E254267AB0615474` | `tests/v41/tb_nvp_i2c_tri_phase_probe_abort_restore.sv` |
| `703B6EF5F2A7EF8DCC464B918677C685F463F07AC2D6A6D63C17391E760B227D` | `tests/v41/tb_nvp_i2c_tri_phase_probe_attempt_limit.sv` |
| `6CC2B42D6B06E46444593F1E78FC7BD8DEAEB18192EEAC267E84176CD9663EA5` | `tests/v41/tb_nvp_i2c_tri_phase_probe_idle_timeout.sv` |
| `2E60DD6FDC4F8F2D1CB94CD26167CD471C8358B9AA755453226CAF0CDECC384E` | `tests/v41/tb_nvp_i2c_tri_phase_probe_index_overflow.sv` |
| `241F8B59392DC893F62F5C5DC231DCA5063655E1F7D292296EEFEA0A9E51481B` | `tests/v41/tb_nvp_i2c_tri_phase_probe_secondary_restore_failure.sv` |
| `E8AFF41C5E43326156CC5E357380B180931606E4F6145CD7ACD1E31AF23FB618` | `tests/v41/tb_nvp_i2c_tri_phase_probe_timeout.sv` |
| `9EC3DD7EDF8BDF1864AFF47E135CF0C6CE85AE5519A31583D830614D20B442A5` | `tests/v41/tb_r1f_failed_txn_logger.sv` |
| `8F64CE2852C2C4325B5B83AFAA3EC945BD4EFD0C59CB385F2B62B390F8C26054` | `tests/v41/tb_r1f_measurement_regs.sv` |
| `AD4884DE8237CED872BBE8779A7488FC0469B4C4DC6B66BF59D64F9AD3B32C94` | `tests/v41/tb_r1f_preinit_arbitration.sv` |
| `6DE31F62629E0C64D35700DD1A57193C5F4240A224B4BF4763D69076FD61BD68` | `tests/v41/tb_r1h_mmio_integration_exhaustive.sv` |
| `2EA788E5A9CA5D9F5663A0A1595009BDB20D7D1F81F8BE917721F79BFE802B40` | `tests/v41/tb_r1h_mmio_read_service.sv` |
| `04203B9DF8874463FFEBB655D74BC2CB5C7E69AFD6F337906BCFBA0D7C7216FB` | `tests/v41/tb_r1h_probe_index_bram_store.sv` |

FACT: all production VHDL units are byte-identical to exact R1g, including
`nvp6134c_i2c_bringup.vhd` SHA-256
`66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024`.
The frozen repository build Tcl remains byte-identical at SHA-256
`53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B`.
The source-scope audit found no XDC, XDMA XCI, NVP table, functional FSM,
POR/start-watchdog, or SDA/SCL-filter change and no new CDC or
diagnostic-to-functional fanout. Its SHA-256 is
`B97C46A1C259D12D6491CF2D997E252433EDFC992E3B447CB5DB08C574E8FCEA`.

## Storage architecture and inference evidence

NETLIST-DERIVED FACT: the bounded precommit OOC inference checkpoint mapped
the failed-record payload to exactly six `RAMB18E1` and the three index
payloads to exactly three `RAMB18E1`. It reported zero payload `RAMB36E1`,
zero failed-record `RAM64M`/`RAMD64E`, 81 FDRE in the complete logger region,
and three FDRE in the index-store region. The result receipt SHA-256 is
`C32709568814661F51F7D7F4C4C534ED390FA63328E14591AC718B7F7C73CA22`;
the RAM and hierarchical utilization reports have SHA-256 values
`4C64B7F1CEF8ECD6158509AA33BA30C65677BD9465A4944E61F777E0F1561EE8`
and `55C9BFED3C59CC9E08E99BA945E2F0EF537742C699FA57A864A2529352A3C40C`.

SIMULATION-DERIVED FACT: the failed-record suite passed all 64 records and all
six words, atomic append, deterministic zero for unused rows, concurrent
append/read, exact overflow on failure 65, and no overwrite. Its accepted XSim
log SHA-256 is
`F294D27395B0FF9B5E9666AE2639861A0DE8BB4DE99A789669845CDF48C01017`.
Three complete 192-bit records on consecutive clocks also passed; that log is
`50BEDA2BF68CB94740608C2D2FFE42A866FF8348D6AC848C75A0F31114E8E5C5`.

SIMULATION-DERIVED FACT: all 1,536 probe-index payload entries were exercised;
the accepted log SHA-256 is
`5251AA1AD0218791F9BB9D04B05BC87273357D6367F4C0419BB8AA94E79254DC`.
Back-to-back same-bank writes and same-bank/different-address concurrent
read/write passed with log SHA-256
`FB0DE6800028E2B67DD3A2699278C7D4F66E1C3B981A44D38899DF45C26E89D2`.
The producer has a source-derived lower bound greater than 1,251 production
clocks between logical probe-index events, while the store accepts one entry
per clock. The logger also accepts one full record per clock. No hidden
serializer/event-spacing loss condition remains.

LIMITATION: this bounded inference evidence is not the authoritative integrated
post-synthesis resource gate. The exact one permitted full build must reproduce
the required primitive mapping and pass the total-device headroom gate.

## MMIO protocol, reset coherence, and host gate

SOURCE-DERIVED FACT: the diagnostic page is served by one synchronous,
one-outstanding response service. Record payload reads issue one synchronous
read; each packed index word issues ordered low/high reads. A response remains
stable until accepted, and writes in the diagnostic range remain forwarded
unchanged rather than becoming local writes.

FACT: the audit found and rejected an earlier reset-liveness hole before this
release. The frozen correction gates `req_ready` and `rsp_valid` with
`!reset` and resets the service with `(~axi_aresetn) || nvp_por_reset`. The
authoritative rerun is regression 02; regression 01 is retained and explicitly
superseded. The superseding report SHA-256 is
`D54CDFD10300EE9CB71D741FE7E7CEDEE5B2A5CD0DF8D80B6A1D561C586AB4FA`.

SIMULATION-DERIVED FACT: the final service and exhaustive integration logs have
SHA-256 values
`4479BD039180B0D7EED39A2963DBBF34B7B85BB549DB8D1DD5B6566CBC0D752D`
and `A26C1F98E17F1DB42E1DBB5ABB677AF8626EBE0F71EA100940A2990E7EBD3977`.
They passed all 1,368 aligned DWORD addresses in `0x20A0..0x35FF`, all 4,104
unaligned byte addresses with deterministic zero, all 1,368 forwarded writes,
ordering, busy rejection, arbitrary backpressure, both reset domains, and
reset recovery. Lost and duplicated response counts are zero. Final top
elaboration passed with log SHA-256
`745A14A9AED2D6B102C6FBB2A5CA2533914AA781005F54276AC62E6AE94E85AE`.

FACT: inherited host and statistical sources are unchanged. The host gate is
`PASS_24_OF_24`, statistical fixtures PASS, and host MMIO writes are zero; the
unit-test log SHA-256 is
`41EE1F68C19168DC80F28073F85614154D35FC1719689EFFE465ADD617260621`.

## Scientific equivalence and complete accepted test matrix

FACT: the final frozen scientific gate is
`05_EQUIVALENCE_AND_SIMULATION/scientific_equivalence/P5_P6_SCIENTIFIC_EQUIVALENCE_GATE.md`,
SHA-256
`6879A5D0F58783D156BD08336FF06B27CFDB6096A2E58A1976A1357C2F343283`.
Its results CSV and diagnostic-audit CSV have SHA-256 values
`B32E8311633808F10EF4BA347E40A4E3B1197A26A44EADA78817A2194E97B980`
and `BE252A333B2A2150501E0F3758B41C6AEB40AFA64003775233AC197A70713B3E`.
The lane manifest SHA-256 is
`011C9C04C49E9A0AB8FD4AD64F1914A7225CD8F8BBF67A5A18CBDFA030CF0E8B`;
this auditor rehashed all 29 manifest rows successfully.

FACT: this auditor independently mapped every one of the 29 authoritative log
hashes to an existing file and scanned each accepted log. All 29 hashes matched
and all 29 had zero start-of-line ERROR/FATAL, assertion/severity-failure,
executed `$fatal`, or standalone FAIL/FAILED diagnostics.

SIMULATION-DERIVED FACT: separate full-duration exact-R1g and R1h-candidate
production pre-init runs both reached `2,121,355,816 ns`, exited zero, emitted
all three required PASS markers, and had byte-identical normalized transcripts
with SHA-256
`850532A5AF3C9776856253D3A3DF5C2A52CD7322F0D78A54D69D2FE6B928AE7C`.
The pair receipt SHA-256 is
`48544003519FD90A844BE860FF5DD7455091A2DF7E26AB98D579E84A8457244A`.

SIMULATION-DERIVED FACT: the strict paired probe harness compared 83 common
outputs on every checked clock plus the functional I2C/FSM event stream, all
block statistics, every injected index-creation event, and every stored index
transactionally. It passed; the XSim log SHA-256 is
`D8440A7A5A5F50764F04D7F21246069B1005F4BDCAC5C9DB783C3FCE7E178BAF`.
All seven inherited probe cases and the 10,000-opportunity-per-phase production
timing run passed with exact terminal/timing transcript matches.

The final scientific classifications are:

```text
R1H_SCIENTIFIC_EQUIVALENCE_GATE=PASS
P5_SOURCE_LEVEL_SCIENTIFIC_EQUIVALENCE=PASS
P6_SCIENTIFIC_SIMULATION_MATRIX=PASS
PRE_INIT_DONE_CYCLE_EQUIVALENCE=PASS
AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
FUNCTIONAL_STATE_SEQUENCE_IDENTICAL=YES
PROBE_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
DIAGNOSTIC_EVENT_STREAM_IDENTICAL=YES
R1H_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0
MMIO_TRANSACTION_LEVEL_EQUIVALENCE=PASS_ALL_ADDRESSES
SCIENTIFIC_SCOPE_REDUCTION=NO
```

## Frozen scientific contract

SOURCE-DERIVED FACT: the exact candidate retains 64 append-only 192-bit failed
records, six 32-bit words per record, no overwrite, overflow on failure 65, and
deterministic zero for unused records. It retains 512 zero-based 16-bit NACK
indices independently for WADDR, REGADDR, and DATA with overflow on index 513.
It retains 10,000 target opportunities per phase, ten blocks per phase, 1,000
opportunities per block, the 12,000-attempt cap, round-robin scheduling, safe
bank/register/data `00/85/00`, every counter/field encoding, and the complete
`0x20A0..0x35FF` map. Only authorized read-response latency and storage
implementation changed.

## Static audit of the one-build Tcl

FACT: task-local `07_BUILD/r1h_build.tcl` has SHA-256
`2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18`,
matching its sidecar and refreshed static reports.

The independent command audit found exactly one active invocation each of
`synth_design` (line 1054), `opt_design` (1265), `place_design` (1269),
`phys_opt_design` (1283), `route_design` (1286), and `write_bitstream` (1585).
The atomic one-build sentinel is created before synthesis. The post-synthesis
mapping/resource gate is written and enforced at lines 1219-1260 before
`opt_design` and `place_design`. There is no retry loop and no VHDL-2008
switch.

The fail-closed gate requires exactly six failed-record RAMB18, one RAMB18 for
each index phase, nine new payload RAMB18 total, zero payload RAMB36,
zero record/index RAM64M and RAMD64E, and no more than 192 FF objects in either
bounded storage region. It independently requires Slice LUTs `<=18720`, Slice
Registers `<=37440`, and exact device availability `20800/41600`. Failure
raises `BLOCKED_R1H_POST_SYNTH_RESOURCE_MARGIN_OR_MEMORY_MAPPING` before any
optimization or placement. The script also binds the exact source commit/tree,
clean branch/topology, all required source hashes, frozen XCI/XDC, build Tcl,
and accepted receipts.

```text
R1H_BUILD_TCL_STATIC_AUDIT=PASS
R1H_BUILD_TCL_EXECUTED_DURING_AUDIT=NO
```

## Static audit of the post-commit manifest finalizer

FACT: task-local `07_BUILD/New-R1hPrebuildManifest.ps1` has SHA-256
`4E9DCDEA092ED2678ECBC89C703FFC858804A4F4C4C52EAB4DCE1F0471F1B884`.
PowerShell parser errors are zero. It was not executed by this auditor and its
three final output files do not yet exist.

SOURCE-DERIVED FACT: the finalizer fails closed unless explicitly invoked with
`-FinalizeAfterCommit`; refuses to overwrite an existing finalized output;
requires the exact build-Tcl hash; proves Git top, exact HEAD/tree, exact R1g
parent/tree, branch, one commit above R1g, and a clean worktree; and requires
the R1g-to-R1h changed path set to equal the same 22-path set frozen above. It
requires exact PASS/BLOCKERS lines in the scientific and precommit receipts,
hashes every tracked repository file, and binds every 27 label required by the
build Tcl plus supplemental source/precommit/static-audit receipts.

SOURCE-DERIVED FACT: outputs are written to unique same-directory temporary
files; existing outputs are rejected; partial published outputs are removed on
a caught failure; and the manifest publication marker is moved into place
last. The finalizer performs no source-repository write.

```text
PREBUILD_MANIFEST_GENERATOR_STATIC_AUDIT=PASS
PREBUILD_MANIFEST_GENERATOR_EXECUTED=NO
PREBUILD_MANIFEST_FINAL_OUTPUTS_PRESENT=NO
```

## Residual mandatory gates

The next action is narrowly bounded:

1. Create exactly one commit, directly above exact R1g, containing exactly the
   22 paths and file contents hashed above; do not amend or rebase.
2. Prove the resulting commit/tree/topology and clean worktree in the source
   identity receipt under `06_SOURCE_COMMIT`.
3. Run the manifest finalizer once with the exact frozen scientific gate, this
   precommit report, and exact post-commit identity receipt; independently
   verify the generated manifest before build.
4. Consume at most the one authorized clean build. The integrated post-synth
   primitive and 10% LUT/FF gates remain mandatory and precede placement.
5. Treat timing, DRC, CDC, provenance, routed checkpoint, bitstream, host
   safety, fresh formal start state, and all hardware campaign gates as
   unavailable until their future exact evidence exists.

No post-synthesis full-project resource result, place/route result, bitstream,
or fresh Formal Phase 2 hardware state is claimed by this release.

## Auditor accounting and release block

```text
PRECOMMIT_RELEASE=PASS
BLOCKERS=NONE
R1H_PARENT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
AUTHORIZED_CHANGED_PATHS_ONLY=YES
SOURCE_WORKTREE_DIFF_CHECK=PASS
R1H_BUILD_TCL_STATIC_AUDIT=PASS
PREBUILD_MANIFEST_GENERATOR_STATIC_AUDIT=PASS
SOURCE_MUTATIONS_BY_AUDITOR=0
COMMITS_BY_AUDITOR=0
PUSHES_BY_AUDITOR=0
FULL_CLEAN_BUILDS=0
SYNTHESIS_RUNS_BY_AUDITOR=0
IMPLEMENTATION_RUNS_BY_AUDITOR=0
BITSTREAMS_BY_AUDITOR=0
HARDWARE_ACTIONS_BY_AUDITOR=0
FORMAL_PHASE2_FRESHLY_RECONFIRMED=NO
AUTHORIZED_NEXT_ACTION=CREATE_ONE_DIRECT_CHILD_R1H_COMMIT_AND_FINALIZE_PREBUILD_MANIFEST
```
