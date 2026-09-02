# AHD v41 G2B-G13-A — RESET_RETURN_SOURCE_TO_AXI Timing Semantics and Replacement Sign-Off Audit

## Decision

`ENGINEERING_GATE = PASS`

`GROUP13_FINAL_DISPOSITION = REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`

`REPLACEMENT_EQUIVALENCE = SAFER_AND_MORE_SEMANTICALLY_CORRECT`

`RTL_CHANGE_REQUIRED = NO`

`CANDIDATE_XDC_READY_FOR_META = YES_WITH_OWNER_ARCHITECT_REVIEW`

This is an offline, routed-checkpoint methodology audit. It does not promote
the candidate constraint and does not close the remaining routed sign-off
gates. Its engineering decision is limited to whether Group 13's current
timing method proves the reset-return safety property and, if not, whether a
bounded replacement is suitable for owner/architect review.

## Authority gate

| Authority item | Required value | Verified value | Result |
|---|---|---|---|
| Project state revision at start | `4` | `4` | PASS |
| G2B-LUT1 state | Sign-off recovery ready/current governed equivalent | `READY_FOR_SIGNOFF_RECOVERY` | PASS |
| Group-9 method | Promoted replacement | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` | PASS |
| G2B-HW | `BLOCKED` | `BLOCKED / NOT_PROVEN` | PASS |
| Evidence predecessor commit | `765f5a5d4760f7a685447651dc68179b2fd96846` | exact | PASS |
| Source branch | `integration/v41-g2b-onech-c2h` | exact | PASS |
| Source commit | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` | exact | PASS |
| Source tree | `1e67e3f1fe06669839fe9ff8573e4d1e0114a889` | exact | PASS |
| Routed DCP SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` | exact | PASS |

The SSOT SHA-256 manifest contains 18 entries and verified 18/18 PASS at
start. The exact JSON authority fields are sealed in
`G2B_G13A_PROTECTION_AUDIT.md` and are rechecked at end.

The governed source worktree is `C:/FPGA/V41_G2B`. The routed checkpoint is
`C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1/sealed_inputs/G2B_ROUTED.dcp`.
No substitute checkpoint was used.

The predecessor proves Group 9 PASS and Groups 10–12 PASS in the same accepted
routed context. It records Group 13 as the first blocker:

`REQUIRED_BUS_SKEW_TIMEOUT:GROUP_13:RESET_RETURN_SOURCE_TO_AXI:QUERY_EXCEEDED_300_SECONDS_FROM_QUERY_STARTED_MARKER`

The full Group-13 `report_bus_skew` was not retried in this audit.

## Exact current Group-13 constraint

Active XDC: `xdc/common/g2b_cdc.xdc`, lines 163–165, SHA-256
`6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227`.

```tcl
set g2b_reset_return_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(reset_abandoned_hold_source|reset_commit_phase_hold_source)_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_reset_return_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(records_abandoned_axi|commit_seen_axi|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|axis_state|snapshot_busy_axi|snapshot_valid_axi|fatal_clear_qualified_axi|axi_hard_episode)_reg.*}] {IS_SEQUENTIAL == 1}]
set_bus_skew 3.000 -from $g2b_reset_return_src -to $g2b_reset_return_dst
```

The routed collections contain seven `nvp_vclk1` source registers and 207
`userclk1` destination registers. The domains are asynchronous. The source
families are the three-bit `reset_abandoned_hold_source` snapshot and the
four-bit `reset_commit_phase_hold_source` snapshot.

The active XDC separately retains a broader source-mailbox relation:

```tcl
set_max_delay -datapath_only 6.000 \
  -from $g2b_source_mailbox_src \
  -to $g2b_axi_mailbox_dst
```

That aggregate relation contains all seven Group-13 source cells and protects
a sink cone broader than the 207-cell Group-13 selector.

## Semantic determination

Group 13 is a held-data reset-return mailbox qualified by a synchronized
request/acknowledgement protocol. It is not a reset net, asynchronous-reset
release synchronizer, Gray bus, or set of independent status controls.

`RESET_CDC_CLASSIFICATION = STABLE_DATA + HANDSHAKE + COMMIT_PHASE_COMPLETION_BARRIER + COMBINATIONAL_AGGREGATION`

Two semantic payload families were derived from RTL and routed objects:

1. `RESET_ABANDONED_COUNT_STABLE_PAYLOAD`: a three-bit binary count consumed
   through the 32-bit `records_abandoned_axi` accounting cone.
2. `RESET_COMMIT_PHASE_COMPLETION_BARRIER`: a four-bit per-slot commit-toggle
   phase snapshot used by direct capture and the reconvergent completion cone.

The source captures both values when it accepts a new transport-request phase
and holds them until a later request. The acknowledgement returns through two
`ASYNC_REG` stages. AXI completion additionally waits until the independently
synchronized live commit vector equals the held commit phase.

The actual invariant is the conjunction of:

- stable payload from source capture through acknowledgement;
- every payload-dependent AXI path settled within the existing `6.000 ns`
  datapath-only bound;
- synchronized acknowledgement before semantic use;
- synchronized live-phase equality before completion; and
- atomic epoch/state publication on the qualified completion edge.

The earliest semantic use is approximately two `userclk1` periods after the
earliest stage-one acknowledgement capture, or about `32.000 ns`. The governed
`6.000 ns` physical cap leaves approximately `26.000 ns` gross reserve in that
earliest-cycle model. A mutual 3 ns arrival spread across unrelated data,
enable, state, and arithmetic paths is not part of the protocol invariant.

`PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`

## Reset and CDC proof

Product `source_reset` and `standalone_transport_reset` are tied inactive.
Both source and AXI reset observations are synchronous process tests, not
asynchronous reset sensitivities. Host reset and a later AXI hard episode are
translated into versioned request/ack transactions.

Focused historical CDC correlation identifies:

- two-stage `CDC-3` request and acknowledgement synchronizers;
- a two-stage `CDC-6` live commit-toggle vector;
- `CDC-15` stable-data findings for the abandoned snapshot; and
- `CDC-1`/`CDC-15` stable-data and reconvergent-control findings for the held
  commit phase.

These findings are not dismissed. They are discharged for Group 13 only by
the combined hold/validity/equality proof and routed absolute-settling bound.
Fresh global CDC closure is outside this audit and remains a later hard gate.

Focused CDC endpoint parsing shows abandoned-hold fanout only in the 32-bit
accounting cone. Commit-phase-hold fanout is exhausted by the original
Group-13 families plus the separately validated transport follow-up/request,
commit-FIFO, and shadow-last-state categories. This is an exhaustive statement
for the cited historical focused CDC evidence, not for future global CDC.
Numerically, the 207 original plus 79 supplemental cells exactly equal all 286
unique historical commit-phase destination cells (`missing = 0`, `extra = 0`);
the 32 abandoned destinations similarly match all 32 historical return
endpoints.

The qualified current XSIM receipt is corroborative: it records PASS for the
commit-phase retirement barrier, simultaneous TLAST/reset release retirement,
and source-reset/transport-request collision scenarios. Simulation does not
replace routed timing evidence.

## Timing-methodology findings

The predecessor's fresh full-context methodology report records:

| Check | State | Focused relevance |
|---|---|---|
| `TIMING-32` | ABSENT | No focused invalid clock-pin endpoint finding |
| `TIMING-34` | PRESENT | Group 13 is item 15; 3 ns is flagged as aggressive/unrealistic |
| `TIMING-37` | ABSENT | No focused max-delay/bus-skew precedence finding |
| `TIMING-38` | ABSENT | No focused bus-skew overlap finding |
| `TIMING-39` | PRESENT | Group 13 is item 6; paths include more than one logic level |

Both present warnings are directly relevant: the original command is costly
and its heterogeneous logic cones violate the intended relative-skew model.

## Bounded alternative routed timing

The first sealed Vivado attempt opened the accepted routed checkpoint and ran
the required A/B alternatives. It then stopped before candidate validation
because a harness membership assertion treated literal cell-name lists as
live Vivado objects. That receipt is classified
`HARNESS_OBJECT_TYPING_ERROR_BEFORE_CANDIDATE_QUERY`, not a candidate timing
failure. A separately sealed candidate-only continuation fixes only the name
resolution (`get_cells` for the same aggregate source/destination lists),
re-verifies all authority hashes and context counts, and does not repeat A/B.
Neither attempt contains a Group-13 `report_bus_skew`. Every active timing or
methodology query has an external 300-second watchdog.

A/B use the predecessor bus-skew-free query base. Candidate validation uses a
separate full preserved context: a derived base retaining Groups 10–12 and
14–17 while omitting Groups 9 and 13, followed by the promoted Group-9
candidate and temporary Group-13 candidate. The continuation requires an
applied inventory of 15 `set_bus_skew`, 14 `set_max_delay`, and zero Group-13
bus-skew relations before accepting any candidate result.

| Query | Bound | Result | Elapsed | Returned paths | Worst datapath |
|---|---|---|---:|---:|---:|
| Exact-scope `report_timing` | `-max_paths 1 -nworst 1` | PASS | 56.827 s | 1 | 3.756 ns |
| Bounded `get_timing_paths` | `-max_paths 64 -nworst 7` | PASS | 0.185 s | 64 | 3.934 ns maximum returned |

The bounded path query observed 1 distinct source and 16 distinct
destinations.
Timing path properties, endpoint roles, and warnings are preserved in the raw
report and machine-readable receipts.

`REPORT_TIMING_WARNINGS = NONE_IN_REPORT`. The attempt-1 Vivado transcript
records only context-loading/tool-environment warnings outside the timing
report; they do not alter the returned path.

## Replacement and routed validation

Strategies A through G are evaluated in `G2B_G13A_CONSTRAINT_ANALYSIS.md`.
Keeping the current global skew is pathological and proves only a relative
number. Splitting relative skew still does not prove settle-before-valid.
Synchronizer proof alone omits the physical payload bound. Redesign is not
justified because the present protocol proves the invariant when paired with
absolute settling.

The selected strategy is structural reset-CDC proof plus absolute settling.
The temporary candidate file declares two explicit `6.000 ns` cell-scoped
max-delay relations. The combined applied context differs from the preserved
recovery context only by replacing Group 13: the derived base temporarily
omits Groups 9 and 13, then reapplies the unchanged promoted Group-9 candidate
and the temporary Group-13 candidate. Groups 10–12/14–17 are preserved, and
active XDC is not modified. Full-context validation also proves containment in
the unchanged broader aggregate constraint and checks aggregate-only
completion fanout. Replacement
equivalence is conditional on retaining that unchanged broad aggregate 6 ns
relation. Removing or changing it invalidates the supplemental-fanout proof
and requires Group-13 validation to be rerun.

| Validation scope | Sources | Target scope | Required | Worst actual | Slack | Result | Runtime |
|---|---:|---|---:|---:|---:|---|---:|
| Abandoned-count family | 3 | 32 semantic cells / all timing endpoints | 6.000 ns | 2.634 ns | 3.467 ns | PASS | 76.881 s |
| Commit-phase family | 4 | 207 original cells / all timing endpoints | 6.000 ns | 3.756 ns | 1.723 ns | PASS | 4.809 s |
| Supplemental aggregate fanout | 4 | 79 aggregate-only completion cells / all timing endpoints | 6.000 ns | 4.681 ns | 0.967 ns | PASS | 0.137 s |

`CANDIDATE_TIMING_VALIDATION = PASS`

`SIGNOFF_RUNTIME = PRACTICAL`

The replacement-specific candidate, supplemental, and focused-methodology
queries total `105.521 s`. The focused methodology run found 20 design-level
items but zero Group-13 object mentions. The only continuation warning is the
benign duplicate installed-strategy warning; it does not affect timing.

The per-family and supplemental routed results are necessary but not treated
as a standalone CDC proof. The replacement decision always includes the RTL
hold/ack/commit-equality proof above.

The raw package retains both attempts, their exact worker identities, the
attempt-1 failure trace, the corrected continuation diff, individual query
runtimes, and candidate-only cold-run elapsed time. Runtime classification uses
the bounded replacement-query workload measured from `QUERY_STARTED` markers,
matching the predecessor timeout criterion. The `998.405 s` cold continuation,
`1,135.069 s` stopped attempt, and `2,133.474 s` combined process runtime are
disclosed separately and are not attributed to the replacement timing
primitive. The gap-containing cross-attempt wall-clock span is not mislabeled
as repeatable sign-off runtime.

## Continuation and project-state decision

Group 9 and Groups 10–12 retain their authoritative PASS results. If the
owner/architect accepts the candidate through governed META/source change,
resume at Group 13 with the replacement method, then run Groups 14–17 and the
remaining routed hard gates. Do not repeat completed groups unless new
evidence invalidates them.

G2B-LUT1 remains blocked in sign-off recovery because this audit does not
promote XDC and does not execute the later hard gates. G2B-HW remains
`BLOCKED / NOT_PROVEN`.

`PROJECT_STATE_REV_AT_START = 4`

`PROJECT_STATE_REV_AT_END = 4`

## Protection record

| Protection | Result |
|---|---|
| Governed FPGA source modified | NO |
| Active XDC modified | NO |
| Governed source index changed | NO |
| Governed source branch moved | NO |
| SSOT modified | NO |
| Bitstream produced | NO |
| Hardware/JTAG accessed | NO |
| FPGA programmed | NO |
| PCIe/DMA accessed | NO |
| Driver/reboot/power-cycle action | NO |

## Publication

The prepared publication directory is
`v41-development-g2b-g13a-reset-return-signoff-audit` in the evidence
repository. Publication to branch `main` is permitted only after all decision
fields are resolved, the SHA manifest is sealed, and remote read-back succeeds.
The state/index use the non-circular `CONTAINING_GIT_COMMIT` convention; the
exact containing SHA and remote read-back result are returned by the final
execution response. The SHA manifest covers every published artifact except
the manifest itself.
