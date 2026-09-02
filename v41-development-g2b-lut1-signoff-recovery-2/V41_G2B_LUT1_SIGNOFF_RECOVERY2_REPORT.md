# AHD v41 G2B-LUT1 Sign-Off Recovery 2 Report

## Outcome

`ENGINEERING_GATE = BLOCKED`

`FIRST_BLOCKER = REQUIRED_BUS_SKEW_TIMEOUT:GROUP_14:RELEASE_SLOT_0_AXI_TO_SOURCE`

The META-5-authorized Group-13 source change was committed and its promoted
replacement sign-off passed. Sign-off then continued at Group 14, where the
required `report_bus_skew` query exceeded its external 300-second budget. The
watchdog terminated that one attempt after `301.299 s`; Groups 15-17 were not
run. In accordance with the bounded-runtime policy, the timeout was not
extended and the query was not retried.

Fresh final routed timing, final DRC, the complete current CDC disposition,
fresh clock review, and fresh PRODUCT utilization were therefore
`NOT_REACHED`. The pre-bitstream requirements were not satisfied, no
bitstream or debug-probe file was generated, and no hardware was accessed.

## Authority and governed source

| Field | Result |
|---|---|
| Project state at start | revision 5 |
| Project state at end | revision 5 |
| META-5 promotion | VERIFIED; evidence commit `bbdeb474ce9d7e5f0db3e8ca8afb5448eef8f314` |
| G13-A authority | VERIFIED; evidence commit `10c7c2898d162af8e2262b3f99861c7d560c4557` |
| Source branch | `integration/v41-g2b-onech-c2h` |
| Source parent | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` |
| Source commit | `64feb60de5d07f400e6b92527bfe54838b3372ee` |
| Source tree | `26399ed456941e26d5ee4b1b2ca50392338fa24a` |
| Active XDC SHA-256 | `C12A371F7F21D350A28C6B310046D543C788D40E805160F12C49FB24C467674C` |
| Active Group-13 update | PASS |
| Unrelated XDC changed | NO |
| Recovery mode | `ROUTED_DCP_REUSE` |
| DCP reuse valid | YES |
| Full rebuild executed | NO |
| Routed DCP SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` |
| Vivado / device | 2025.2 build 6299465 / `xc7a35tcsg325-2` |

The committed delta contains exactly one tracked path,
`xdc/common/g2b_cdc.xdc`, and changes only the authorized Group-13
constraints. RTL, netlist-bearing inputs, IP configuration, ABI, MMIO, R1i,
R-track, and the HDMI project are unchanged. The routed checkpoint therefore
remained the exact logical-design authority and no rebuild trigger existed.

## Preserved sign-off

| Scope | Disposition | Basis |
|---|---|---|
| Group 9 | `PRESERVED_PASS` | Published recovery evidence commit `765f5a5d4760f7a685447651dc68179b2fd96846`; gate SHA-256 `4531FF587FEE60FA99DC6523C7F11E6585945390D1FE5AB66CA4B30E040BB25B` |
| Groups 10-12 | `PRESERVED_PASS` | Prior ledger SHA-256 `666A403FC01DADE0E95D3329D119473CF8D7D0E7EAD2B1E624F495FDAB5FFFF7` |

There was no consistency invalidation reason. Group 9 and Groups 10-12 were
not rerun. Neither the retired global Group-9 nor the retired global Group-13
`report_bus_skew` query was executed.

## Group-13 replacement sign-off

`GROUP13_REPLACEMENT_SIGNOFF = PASS`

| Family | Required | Worst actual | Slack | Sources | Destinations | Runtime | Result |
|---|---:|---:|---:|---:|---:|---:|---|
| `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` | 6.000 ns | 2.634 ns | 3.467 ns | 3 | 32 | 92.149 s | PASS |
| `RESET_COMMIT_PHASE_COMPLETION_BARRIER` | 6.000 ns | 3.756 ns | 1.723 ns | 4 | 207 | 5.862 s | PASS |

The hash-bound G13-A structural proof established stable-data semantics,
handshake/commit completion, reset-return coherency, and bounded settling. Its
79-cell supplemental aggregate coverage also passed and was not treated as a
third semantic family.

`GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED = NO`

## Groups 14-17 bounded execution

| Group | Name | Result | Runtime | Required | Actual / slack |
|---:|---|---|---:|---:|---|
| 14 | `RELEASE_SLOT_0_AXI_TO_SOURCE` | `REQUIRED_BUS_SKEW_TIMEOUT` | 301.299 s | 3.000 ns | unavailable because the query did not complete |
| 15 | `RELEASE_SLOT_1_AXI_TO_SOURCE` | `NOT_RUN_AFTER_BLOCKER` | 0.000 s | 3.000 ns | N/A |
| 16 | `RELEASE_SLOT_2_AXI_TO_SOURCE` | `NOT_RUN_AFTER_BLOCKER` | 0.000 s | 3.000 ns | N/A |
| 17 | `RELEASE_SLOT_3_AXI_TO_SOURCE` | `NOT_RUN_AFTER_BLOCKER` | 0.000 s | 3.000 ns | N/A |

The fresh pre-query Group-14 object inventory contains 56 sources and 20
destinations. Groups 15-17 have the same governed 56-source/20-destination
collection cardinalities, but those collections were not freshly evaluated
after the blocker. The timeout ledger therefore leaves its result-CSV count
fields empty rather than presenting pre-query or definition counts as a
completed query result; `G2B_LUT1_GROUPS14_17_COLLECTION_COUNTS.txt` records
the distinction explicitly.

Group 14 used the governed compact command:

```tcl
report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 -warn_on_violation -file <GROUP_RAW_REPORT>
```

The command did not return source count, destination count, worst actual, or
slack before the watchdog boundary. Its three logged warnings concerned a
duplicate Vivado strategy definition and the already-loaded BS3 and G13 XDC
files; they are query-context warnings, not a substitute for final DRC.

`GROUPS14_17_RESULT = PARTIAL`

`GROUPS14_17_GATE = FAIL`

## Downstream release gates

| Gate | Result | Reason |
|---|---|---|
| Fresh routed timing | `NOT_REACHED` | Hard stop after Group-14 required-query timeout |
| Fresh DRC | `NOT_REACHED` | Hard stop after Group-14 required-query timeout |
| Complete current CDC disposition | `NOT_REACHED` | Targeted Group-9 ownership and Group-13 reset-return proofs passed, but the full current inventory was not completed |
| Fresh clock review | `NOT_REACHED` | Hard stop after Group-14 required-query timeout |
| Fresh PRODUCT utilization | `NOT_REACHED` | Hard stop after Group-14 required-query timeout |
| PRODUCT LUT <=90% | `NOT_REACHED` | No fresh PRODUCT utilization result |
| Pre-bitstream hard gate | FAIL | Groups 14-17 did not pass and downstream release gates were not reached |
| Bitstream generation | NO | Forbidden after the failed pre-bitstream eligibility check |

No historical result is promoted to stand in for any fresh downstream gate.

## Functional and safety protection

The exact hash-bound offline protection receipt remains PASS because the only
source delta is constraints-only. One-channel C2H remains implemented; the
four-slot ring, record formatter, backpressure, sequence semantics, reset
epoch, MMIO, host parser, and ABI golden vectors remain PASS. The transport is
`AHD_C2H_TRANSPORT_ABI_V1`, version 1, with MMIO unchanged at
`0x3800..0x3BFF`. R1i protected behavior, NVP initialization, production
observability, and protected startup behavior remain PASS/unchanged.

Offline throughput remains PASS at a calculated `468.750 MB/s` ceiling versus
the required `288 MB/s`; this is not hardware throughput evidence.

## Terminal state

- `BITSTREAM_PRODUCED = NO`
- `DEBUG_PROBES_PRODUCED = NO`
- `HARDWARE_ACCESSED = NO`
- `HARDWARE_THROUGHPUT_PROVEN = NO`
- `G2B-HW = NOT_PROVEN`
- `SSOT_UPDATE_REQUIRED = NO`
- `PROJECT_STATE_REV_AT_END = 5`

The exact next engineering action is a separately governed continuation for
Group 14. This recovery-2 execution ends at the required timeout and does not
authorize a longer query, redesign, speculative retry, implementation rebuild,
bitstream generation, or hardware access.
