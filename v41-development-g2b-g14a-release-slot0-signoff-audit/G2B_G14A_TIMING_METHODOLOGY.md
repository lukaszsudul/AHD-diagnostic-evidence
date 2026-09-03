# G2B-G14-A timing methodology

## Frozen routed authority

- DCP: `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp`
- Size: `57,900,063 bytes`
- SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`
- Routed signature: `ROUTED_FULLY=1`, route errors `0`
- Part: `xc7a35tcsg325-2`
- Tool: Vivado `2025.2`, SW build `6299465`, IP build `6300035`
- Bounded worker SHA-256: `1C988A8A2390DCF489C5AEA9BBB23DBD2FB5DEE8DBA08B80375E0784A8E3821B`
- External supervisor SHA-256: `BA6024116B0041361A975ADE21007D511AA320B28C66B9D8F7B260DEF184BAC8`

No alternate DCP was used. The analysis opened the routed checkpoint and read timing constraints only. It did not synthesize, place, route, write a checkpoint, or produce a bitstream.

## Previous timeout authority

`PREVIOUS_GROUP14_TIMEOUT = VERIFIED`

Recovery-2 wrote `QUERY_STARTED.marker` immediately before the exact Group-14 `report_bus_skew`. Its independent PowerShell supervisor measured from the active marker to a validated completion marker, applied a 300-second command deadline, and terminated the worker after `301.299 s`. There was no completion marker and no retry. The predecessor receipt reported one briefly postexisting Vivado process after taskkill; its termination log identifies successful termination of the exact spawned process tree, and the present audit found zero Vivado processes. This caveat does not change timeout verification. Copies of the object receipt, start marker, watchdog, disposition, and warnings are under `raw/predecessor_group14_timeout/`.

`FULL_GROUP14_REPORT_BUS_SKEW_RETRIED = NO`

## Isolated analysis context

The worker opened the sealed DCP, verified DCP identity and routed state, loaded the recovery-2 bus-skew-free base, included the accepted Group-9 and Group-13 replacement checks, resolved and identity-checked the exact `56/20` Group-14 scope, then applied only the temporary Group-14 candidate. The recovery base and applied context intentionally contain zero `set_bus_skew` commands, so Groups 10-12 and 15-17 bus-skew constraints were absent from this in-memory query-isolation context and were not executed. This omission is not a candidate or proposed source change. Preservation of every other group is established by the Group-14-only candidate stanza and future replacement-diff boundary, while their completed/pending statuses remain governed by predecessor evidence. The applied in-memory context is captured in `raw/timing/G2B_G14A_APPLIED_CANDIDATE_CONTEXT.xdc`.

An initial cold invocation failed during Tcl list construction before any timing-query start marker existed. It loaded the checkpoint/XDC but executed none of the required timing queries. The failure is retained under `raw/attempt0_initialization_failure/`; the harness was corrected and a fresh isolated invocation performed the one permitted attempt of each query.

The successful supervisor externally enforced each active-query marker's 300-second deadline and post-run validated all six completion-marker identities and PASS statuses. It had one post-run validation defect: launching through `vivado.bat` exposed a null PowerShell `ExitCode`. The watchdog receipt was written successfully with a blank exit-code field, after which the null-exit-code validation failed. It did not affect execution. `TIMED_OUT=NO`, six start markers pair with six completion markers, `WORKER_COMPLETED.marker` is PASS, the Vivado transcript contains `exit 0`, and no Vivado process remained. The raw locale text `917,602` normalizes to `917.602 s`. `raw/timing/G2B_G14A_SUPERVISOR_POSTRUN_CORRECTION.txt` records this metadata-only interpretation. No timing query was rerun.

## Required exact-scope queries

The exact original 56-source/20-destination scope was used. `get_timing_paths` ran before `report_timing` as required.

### get_timing_paths

Command:

```tcl
get_timing_paths -delay_type max -sort_by slack -max_paths 64 -nworst 7 -from <all 56 Group-14 sources> -to <all 20 Group-14 destinations>
```

- Result: `PASS`
- Runtime: `77.190 s`
- Returned paths: `49` (cap `64`)
- Returned source diversity: `1`
- Returned destination diversity: `7`
- Selected startpoint: `G2B_ONECH_C2H/release_generation_axi_reg[0][3]/C`
- Endpoint set: slot-0 state bits plus fault/admission endpoints
- Clocks: `userclk1 -> nvp_vclk1`
- Logic levels: `8`
- Existing exception: `MaxDelay Path 6.000ns -datapath_only`
- Worst datapath delay: `5.554 ns`
- Worst slack: `0.478 ns`

Available properties included start/end pins, source/destination clocks, requirement, slack, arrival, corner, datapath logic and net delay, logic levels, fanout, and exception. The limited returned source diversity is a consequence of worst-path selection, not a reduction of the asserted 56-source query scope.

### report_timing

Command:

```tcl
report_timing -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <all 56 Group-14 sources> -to <all 20 Group-14 destinations>
```

- Result: `PASS`
- Runtime: `0.184 s`
- Returned paths: `1`
- Worst path: `release_generation_axi_reg[0][3]/C -> source_ownership_fatal_deferred_reg/D`
- Clocks: `userclk1 -> nvp_vclk1`
- Datapath delay: `5.554 ns` (`1.667 ns` logic, `3.887 ns` route)
- Logic levels: `8` (`CARRY4=2`, `LUT4=2`, `LUT6=4`)
- Requirement: `6.000 ns` datapath-only max delay
- Slack: `0.478 ns`
- Query warnings: none from `report_timing`; the Vivado session log contains one unrelated pre-query `[Runs 36-547]` duplicate user-strategy startup warning

## Candidate family validation

| Family | Required ns | Worst actual ns | Slack ns | Runtime s | Result |
|---|---:|---:|---:|---:|---|
| RELEASE_SLOT0_NORMAL_STATE_TRANSITION | 6.000 | 5.467 | 0.563 | 63.236 | PASS |
| RELEASE_SLOT0_MISMATCH_CONTAINMENT | 6.000 | 5.554 | 0.478 | 0.117 | PASS |
| RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING | 6.000 | 4.191 | 1.839 | 0.111 | PASS |

Each family was capped, marker-bounded, and completed once. The candidate-results CSV and worst-path property files provide the detailed endpoints, clocks, exception, and logic levels.

## Focused methodology warnings

Only the requested checks were invoked:

```tcl
report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39}
```

Runtime was `25.501 s`; Vivado reported zero checks found and zero Group-14 object mentions.

| Check | Result |
|---|---|
| TIMING-32 | ABSENT |
| TIMING-34 | ABSENT |
| TIMING-37 | ABSENT |
| TIMING-38 | ABSENT |
| TIMING-39 | ABSENT |

No broad global methodology report was run.

## Runtime qualification

The six active bounded queries consumed `166.339 s` in total. Candidate-family validation plus focused methodology consumed `88.965 s`; every individual query completed below 300 seconds. Cold checkpoint/XDC setup made successful worker runtime `852.108 s` and supervisor wall time `917.602 s`, but it did not move the pathological computation to another query.

`SIGNOFF_RUNTIME = PRACTICAL`

This classification applies to the bounded replacement sign-off workload. The retired full-scope `report_bus_skew` behavior remains pathological.
