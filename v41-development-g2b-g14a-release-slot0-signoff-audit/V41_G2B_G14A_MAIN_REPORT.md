# AHD v41 G2B-G14-A RELEASE_SLOT_0_AXI_TO_SOURCE Sign-Off Method Audit

## Final result

- Engineering gate: `PASS`
- Evidence publication: `PASS`
- Overall result: `PASS`
- First blocker: `NONE`
- Final execution point: `HARD STOP AFTER G2B-G14-A RELEASE-SLOT SIGN-OFF AUDIT`

The Group-14 payload is semantically coherent, but the current global path set is not a valid relative-skew comparison bundle. The correct safety invariant is absolute token settling before a two-stage synchronized event is consumed, backed by stable-data lifecycle, fail-closed identity checks, and a reset completion barrier. A temporary three-family `6.000 ns` datapath-only candidate passed against the exact routed DCP. No RTL change is required.

## Governed-state entry gate

- SSOT repository: `lukaszsudul/AHD-diagnostic-evidence`
- SSOT directory: `project-current-state/`
- `PROJECT_STATE_REV_AT_START = 5`
- SSOT manifest: `18/18 PASS`
- Group 9: authoritative PASS, preserved
- Groups 10-12: authoritative PASS, preserved
- Group 13: accepted settling-plus-structural-CDC disposition; recovery-2 PASS, preserved
- Groups 14-17: pending at entry; recovery-2 partial boundary
- G2B-LUT1: governed `PLANNED / READY_FOR_SIGNOFF_RECOVERY`; recovery-2 evidence is immediate execution predecessor
- G2B-HW: `BLOCKED / NOT_STARTED / NOT_PROVEN`

No mismatch was found. SSOT remained unmodified and was re-read at revision 5 at the end.

## Immediate predecessor

- Directory: `v41-development-g2b-lut1-signoff-recovery-2`
- Evidence commit: `a88772c9a36637a5caee9d7d3756e28079074240`
- Group 9: `PRESERVED_PASS`
- Groups 10-12: `PRESERVED_PASS`
- Group 13 replacement: `PASS`
- Group 13 structural CDC: `PASS`
- Groups 14-17: `PARTIAL`
- First blocker: `REQUIRED_BUS_SKEW_TIMEOUT:GROUP_14:RELEASE_SLOT_0_AXI_TO_SOURCE`

The predecessor's Group-14 query start marker, independent 300-second watchdog, `301.299 s` elapsed time, and absent completion marker establish `PREVIOUS_GROUP14_TIMEOUT = VERIFIED`. Its receipt recorded one briefly postexisting Vivado process after taskkill, while the termination log records successful termination of the exact spawned process tree and the current process count is zero. The full Group-14 `report_bus_skew` was not retried.

## Source authority

- Authoritative checkout: `C:\FPGA\V41_G2B`
- Branch: `integration/v41-g2b-onech-c2h`
- HEAD: `64feb60de5d07f400e6b92527bfe54838b3372ee`
- Tree: `26399ed456941e26d5ee4b1b2ca50392338fa24a`
- Required ancestry: present; HEAD equals the required commit
- Active XDC: `xdc/common/g2b_cdc.xdc`
- Active XDC SHA-256: `C12A371F7F21D350A28C6B310046D543C788D40E805160F12C49FB24C467674C`
- Reviewed RTL SHA-256: `8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471`
- Group-13 governed change: present at active-XDC lines 163-179

The authoritative worktree and index were clean at entry and exit; HEAD/tree/branch did not move.

## Routed DCP authority

- Path: `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp`
- Size: `57,900,063 bytes`
- SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`
- Identity: `VERIFIED`
- Part: `xc7a35tcsg325-2`
- Routed state: fully routed, zero route errors

No other DCP was substituted.

## Current Group-14 definition

```tcl
set g2b_release_payload_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(slot_state_source|release_seen_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_release0_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[0\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release0_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[0\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release0_payload_src "$g2b_release0_generation_src $g2b_release0_epoch_src"
set_bus_skew 3.000 -from $g2b_release0_payload_src -to $g2b_release_payload_dst
```

- Required skew: `3.000 ns`
- Source count: `56` (`24` generation + `32` epoch)
- Destination count: `20`
- Source domain: `userclk1`, `16.000 ns`
- Destination domain: `nvp_vclk1`, `6.734 ns`
- Path-set comparability: `INVALID_FOR_SKEW_COMPARISON`

## Independent semantic result

Semantic classification: a stable 56-bit slot-0 generation/epoch release token. Ordinary release is qualified by a one-way release toggle synchronized through two ASYNC_REG stages; reset-overlap accounting is qualified by a separately synchronized transport request and retired against the captured release phase. It is not a request/ack mailbox, Gray code, independent status bits, or a direct multibit destination-register bundle.

The actual same-edge destination closure has three families:

1. `RELEASE_SLOT0_NORMAL_STATE_TRANSITION`: 56 sources to 3 slot-0 state bits.
2. `RELEASE_SLOT0_MISMATCH_CONTAINMENT`: 56 sources to 4 fault/admission registers.
3. `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING`: 56 sources to 3 reset-abandoned counter bits.

The old 20-destination scope contains `release_seen_source[0:3]` and other slots' state bits, which are not slot-0 payload capture endpoints. It also omits the three reset-accounting endpoints. Reconvergent comparators and control logic give the real paths different endpoint roles, depths, and fanout. A global skew number is therefore not the correctness condition.

## Safety invariant and CDC proof

The prevented hardware failure is evaluation of a synchronized release or reset qualifier with a torn, late, or mis-associated generation/epoch token. That could release a newer owner of slot 0, generate false fatal containment, disable admission, or corrupt reset-overlap accounting.

Required invariants are:

- `ABSOLUTE_SETTLING`
- `STABLE_DATA_UNTIL_EVENT_CONSUMPTION`
- `EVENT_ORDERING`
- `SYNCHRONIZER_STRUCTURE`
- `COMPLETION_BARRIER`
- `TOKEN_IDENTITY` (generation and epoch)

The active aggregate mailbox constraint already establishes a governed `6.000 ns` datapath-only cap for these sources and destinations. Both the release-toggle and transport-request qualifier paths have two ASYNC_REG stages; two complete destination periods before their respective semantic use provide `13.468 ns` gross window, leaving `7.468 ns` gross protocol margin at that cap. The RTL lifecycle prevents payload rewrite before consumption; normal invalid tokens fail closed; reset acknowledgement waits for the captured release phase to retire.

`GROUP14_CDC_STRUCTURE = PASS_WITH_DISPOSITION`

## Bounded routed queries

The exact original Group-14 scope was queried once per required method with a 300-second external active-query watchdog. `get_timing_paths` ran first.

| Query | Result | Runtime | Paths | Key result |
|---|---|---:|---:|---|
| Exact-scope `get_timing_paths`, max 64/nworst 7 | PASS | 77.190 s | 49 | 7 endpoint destinations; worst delay 5.554 ns, slack 0.478 ns |
| Exact-scope `report_timing`, max 1/nworst 1 | PASS | 0.184 s | 1 | `release_generation[0][3]` to fatal-deferred; 8 levels; no query warning |

The selected worst paths carried the existing governed `6.000 ns` datapath-only max-delay exception. Available properties included endpoint identity, clocks, arrival, requirement, slack, corner, logic/net delay, fanout, and logic levels. The Vivado session log contains one unrelated pre-query `[Runs 36-547]` duplicate user-strategy startup warning; `report_timing` itself emitted none.

## Candidate and validation

`G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` replaces only Group 14 in an isolated analysis context. It applies `set_max_delay -datapath_only 6.000` to each real semantic family and changes no clock, unrelated timing exception, or other group.

For bounded query isolation, the recovery-2 base intentionally contained zero bus-skew commands; therefore other groups' bus-skew constraints were not loaded or re-executed in memory. That analysis base is not part of the proposed change. The candidate file itself is Group-14-only, and a future governed diff must preserve all other group constraints unchanged.

| Family | Worst actual | Slack | Runtime | Result |
|---|---:|---:|---:|---|
| Normal state transition | 5.467 ns | 0.563 ns | 63.236 s | PASS |
| Mismatch containment | 5.554 ns | 0.478 ns | 0.117 s | PASS |
| Reset-overlap accounting | 4.191 ns | 1.839 ns | 0.111 s | PASS |

Candidate validation: `PASS`.

Focused methodology runtime was `25.501 s`; `TIMING-32`, `TIMING-34`, `TIMING-37`, `TIMING-38`, and `TIMING-39` were all `ABSENT`. No broad global methodology report was run.

The six bounded active queries totaled `166.339 s`; all completed below 300 seconds. The replacement workload is `PRACTICAL`. The old full `report_bus_skew` remains pathological and was not displaced into another unbounded check.

## Engineering disposition

- `PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`
- `SIGNOFF_RUNTIME = PRACTICAL`
- `REPLACEMENT_EQUIVALENCE = SAFER_AND_MORE_SEMANTICALLY_CORRECT`
- `RTL_CHANGE_REQUIRED = NO`
- `GROUP14_FINAL_DISPOSITION = REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`
- `CANDIDATE_XDC_READY_FOR_META = YES_WITH_OWNER_ARCHITECT_REVIEW`

The candidate is temporary evidence only. Owner/architect META review and governed promotion are required before active XDC or SSOT may change.

## Protection receipts

- FPGA_AHD/source repository modified: `NO`
- Active XDC modified: `NO`
- Source git index modified: `NO`
- Source branch movement: `NO`
- Synthesis/place/route run: `NO`
- Bitstream produced: `NO`
- Hardware accessed: `NO`
- JTAG/programming/PCIe/DMA/driver/reboot/power-cycle: `NO`
- SSOT modified: `NO`
- `PROJECT_STATE_REV_AT_END = 5`

## Continuation boundary

- Group 9: `PRESERVE_PASS`
- Groups 10-12: `PRESERVE_PASS`
- Group 13: `PRESERVE_PASS`
- Group 14: future governed promotion and validation of this replacement
- Groups 15-17: `PENDING`
- Then, only after those gates: routed timing, DRC, CDC, clocks, resources, pre-bitstream, and bitstream

Recommended next action: run one governed owner/architect META review to promote `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` for Group 14 only.

## Evidence publication

- Repository: `lukaszsudul/AHD-diagnostic-evidence`
- Branch: `main`
- Directory: `v41-development-g2b-g14a-release-slot0-signoff-audit`
- Commit message: `Audit AHD G2B Group 14 release-slot timing sign-off`
- Push mode: non-force
- Remote read-back: `PASS`
