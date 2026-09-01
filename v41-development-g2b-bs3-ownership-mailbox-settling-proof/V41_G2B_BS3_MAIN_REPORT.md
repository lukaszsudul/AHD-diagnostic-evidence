# AHD v41 G2B-BS3 Ownership Mailbox Settling Bounds and Structural CDC Proof

## Executive decision

| Gate | Result |
|---|---|
| Engineering gate | PASS |
| Sealed routed DCP | VERIFIED |
| Ownership CDC structure | PASS_WITH_DISPOSITION |
| Per-family settling validation | PASS |
| Replacement equivalence | SAFER_AND_MORE_SEMANTICALLY_CORRECT |
| RTL change required | NO |
| Group-9 final disposition | REPLACE_GLOBAL_BUS_SKEW_WITH_PER_FAMILY_SETTLING_CHECKS |
| Candidate XDC ready for META | YES_WITH_OWNER_ARCHITECT_REVIEW |
| End-to-end sign-off runtime | MARGINAL |

`OWNERSHIP_AXI_TO_SOURCE` is one acknowledged bundled stable-data mailbox. A request toggle and 58-bit registered `{slot,generation,epoch}` token launch together in `userclk1`; a two-stage synchronizer and registered comparison qualify semantic use in `nvp_vclk1`. The AXI sender/launch registers hold the token through normal acknowledgement/result consumption, or block reuse until explicit reset cancellation/phase retirement. The reverse acknowledgement uses an independent two-stage synchronizer. This is not a 58-bit independently sampled CDC bus and does not functionally require a global 3.000 ns pairwise arrival spread.

The replacement couples structural CDC proof to one 6.000 ns absolute `set_max_delay -datapath_only` deadline for each of the three semantic families. The earliest request-qualified use is 13.468 ns after launch in the qualified STA model, leaving 7.468 ns gross reserve and approximately 7.436 ns after the 0.032 ns FDRE setup term observed on the successful BS3 paths. Both raw datapath delay at or below 6.000 ns and nonnegative slack are required.

## Authority and immutable-input gates

| Item | Qualified value | Result |
|---|---|---|
| `PROJECT_STATE_REV_AT_START` | 3 | PASS |
| `PROJECT_STATE_REV_AT_END` | 3 | PASS |
| Evidence predecessor | BS2 commit `4699632c591238fee46ada3b0de37532fddd0b6f` | PASS |
| DCP path | `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp` | PASS |
| DCP size | 57,900,063 bytes | PASS |
| DCP SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` | PASS |
| Routed state inherited and rechecked from BS2 | 33,985 routable / 33,985 fully routed / 0 routing errors | PASS |
| Part opened in BS3 | `xc7a35tcsg325-2` | PASS |

BS3 reused the BS0 semantic inventory and BS2 exact-scope/timing evidence. It did not redo broad static discovery. BS2's singleton 58-to-1 timing result and non-comparable `get_timing_paths` result were treated exactly as predecessor evidence: they demonstrated feasibility but were not treated as a skew measurement.

## Qualified implementation identity

- RTL: `C:\FPGA\V41_G2B\rtl\g2b\v41_g2b_onech_c2h.sv`, SHA-256 `8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471`.
- Active CDC XDC inspected but not modified: `C:\FPGA\V41_G2B\xdc\common\g2b_cdc.xdc`, SHA-256 `2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF`.
- Primary source repository: `C:\FPGA\FPGA_AHD`, `main`, HEAD `be94f88ee8d179f12928ab791bdae27c22cd1762`.
- G2B implementation worktree: `C:\FPGA\V41_G2B`, `integration/v41-g2b-onech-c2h`, HEAD `224d194e5f82c85bcb29297561c5d5e76d28063b`.

The G2B worktree had pre-existing modified/untracked implementation content and the primary repository had pre-existing `.codex_tmp/` and `reports/` entries. BS3 neither cleaned nor changed them. End hashes, heads, branches, and source indexes match their start values.

## Reconstructed protocol

The detailed model is in `G2B_BS3_OWNERSHIP_PROTOCOL_MODEL.md`; the executable sequence is in `G2B_BS3_REQUEST_ACK_SEQUENCE_PROOF.md`.

Forward control:

`own_req_toggle_axi -> own_req_sync1_source -> own_req_sync2_source -> sync2-vs-seen decision`

Reverse control:

`own_ack_toggle_source -> own_ack_sync1_axi -> own_ack_sync2_axi -> request-phase equality`

All four synchronizer registers resolve exactly and have `ASYNC_REG=TRUE`. The production false paths terminate only on first-stage D pins, leaving stage-to-stage timing intact.

The stable forward payload comprises:

| Family | Routed launch objects | Count | Semantic role |
|---|---|---:|---|
| Slot selector | `axis_slot_reg[0:1]` | 2 | Select one of four slot-state/generation/epoch entries |
| Generation qualifier | `axis_generation_reg[0:23]` | 24 | Reject reused/stale slot identity |
| Epoch qualifier | `axis_epoch_reg[0:31]` | 32 | Reject pre-reset ownership identity |

At `scheduler_pop`, payload and request are registered on the same AXI edge and `axis_state` enters `AXIS_WAIT_OWN`. Thus a literal full-cycle pre-request setup invariant is not implemented. Safety instead follows from common registered launch, a bounded data path faster than the control-recognition window, and overwrite exclusion. Ordinary FSM states exclude another pop; if reset forces `AXIS_IDLE` before ack, `stream_reset_busy_axi` and phase-retirement guards still prevent reuse.

The source decision requires selected state `COMMITTED`, selected generation equality, selected descriptor-epoch equality, and current reset-epoch equality. Success transitions the selected slot to `DMA_OWNED`; failure latches ownership-fatal effects and disables admission. Result and ack launch together.

## Invariant and structural result

The complete classification is in `G2B_BS3_CDC_INVARIANTS.md` and `G2B_BS3_STRUCTURAL_CDC_PROOF.md`.

- Request synchronizer: PROVEN / PASS.
- Ack synchronizer: PROVEN / PASS.
- Same-edge registered payload/request launch: PROVEN.
- Full source-cycle payload setup before request: VIOLATED as a literal property, but not required by this architecture.
- Settle before synchronized semantic use: PROVEN_WITH_ASSUMPTION under the qualified STA clock model and passing physical cap.
- Hold until normal ack/result consumption or reset cancellation/retirement: PROVEN.
- Destination decision only after synchronized request: PROVEN.
- Generation/epoch stale-identity protection: PROVEN_WITH_ASSUMPTION for the stated finite-counter fault model.
- Reset phase retirement and stale-request suppression: PROVEN_WITH_ASSUMPTION for clock progress, normal synchronizer resolution, and configuration initialization.

`OWNERSHIP_CDC_STRUCTURE = PASS_WITH_DISPOSITION`.

Of the 89 exact old-Group-9-overlap `CDC-1` rows, four are direct forward ownership payload rows closed by BS3 settling checks. Sixty-nine launch from reverse `own_ok_hold_source` and are dispositioned by ack qualification plus the retained source-to-AXI 6.000 ns cap. The remaining 16 come from release/transport sources outside the 58 and remain under their separate preserved protocols/constraints. No ownership overlap was found for the two global `CDC-10` or two global `CDC-13` rows. BS3 does not attempt to close the other global CDC findings.

## Reset and epoch proof

Initial `axi_aresetn=0` before `axi_seen_high` is intentionally masked and relies on configuration-zero mailbox phases/writable slot initialization. A later low creates one hard episode; `axi_hard_episode` prevents retrigger while held. Transport reset captures release and ownership phases, installs a new epoch, clears source slot generations/states, and immediately aligns the ownership seen/ack phases to the captured phase. If the request synchronizer still lags, `transport_retire_pending_source` withholds transport acknowledgement until sync2 reaches that phase and then re-aligns seen/ack. A hard reset overlapping an active transport reset is coalesced by `transport_followup_hard_axi`, not expressed as a cancelling toggle.

Product `source_reset` and standalone reset inputs are tied low; readiness loss is not an epoch reset. Reset cancellation may make the old `own_ok_hold_source` result unconsumed, but it also aborts AXIS wait, flushes old commits/enable, and blocks new scheduling until retirement plus a new capture/commit sequence. Therefore the replacement remains valid across reset boundaries under the documented assumptions.

## Timing requirement and margin policy

| Quantity | Value |
|---|---:|
| `userclk1` period | 16.000 ns |
| `nvp_vclk1` period | 6.734 ns |
| Request synchronizer depth | 2 source-clock stages |
| Earliest registered request use | third eligible source edge |
| Minimum launch-to-use window | 13.468 ns |
| Selected per-family datapath cap | 6.000 ns |
| Gross reserve | 7.468 ns |
| Setup-adjusted reserve | approximately 7.436 ns |
| Earliest aligned normal launch-to-ack-consumption | 48.000 ns |
| Minimum ack-launch-to-use window | 32.000 ns |

The 6.000 ns value is retained from the existing aggregate acknowledged-mailbox cap, not invented by BS3. It consumes 44.55% of the theoretical forward window, lies 0.734 ns below one destination period, and leaves more than one full destination period of gross reserve. The proof applies to the routed STA model with `nvp_vclk1=6.734 ns`; any additional clock tolerance/jitter must be incorporated by META before promotion.

## Constraint strategy and exact diff

The six evaluated alternatives and false-confidence risks are recorded in `G2B_BS3_CANDIDATE_STRATEGY_EVALUATION.md`. The selected composite is structural CDC proof plus a bounded physical delay cap, implemented as three per-family max-delay checks.

The original routed full XDC SHA-256 is `586917EE12FF31DDDCA58742E50F8342C8D1A97F2B8400176F916B87AFA5084D` with 17 bus-skew commands. The temporary BS3 base SHA-256 is `3680EE8998503D10713D930D7D9D44AD0D71B273A9252D364A3BEE2D0D6AD507` with 16 bus-skew commands. Line comparison proves that only the ownership Group-9 command was removed; two comments were added and no other constraint changed. The declarative candidate SHA-256 is `AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087` and contains three 6.000 ns `set_max_delay -datapath_only` commands and zero `set_bus_skew` commands.

The exact candidate collections were compared against BS0 reference files and SHA-256s:

| Collection | Count | Reference SHA-256 |
|---|---:|---|
| Slot | 2 | `EEC952FD391CBDE81D7BA5918BB293C1C309C8D3A5E511A86884B3F2FDBC7668` |
| Generation | 24 | `FEBDD92ABC37EBCF3E24F77A5F25F95A46C4724506EAC97ABCB5D417693EF133` |
| Epoch | 32 | `3764639B5C1F5D32DD6719B678DACC3E2AB92DD2F05ABDE6F87AF52B62029067` |
| Payload-dependent destinations | 17 | `F203E7D345FD6B707963F6A27D87508A0480C2249A3E209E15BB023791C12846` |

Vivado XDC does not support procedural `if`; exact identity/count assertions therefore execute in the bounded sign-off Tcl and post-run receipt, not in the declarative XDC.

## Bounded routed-checkpoint validation

The successful run opened only the sealed routed DCP, reset/reloaded timing constraints, and issued timing/methodology/exception reports. It did not synthesize, optimize, place, route, write a checkpoint, generate a bitstream, or run `report_bus_skew`.

Every actual timing/methodology/exception command was supervised from a marker with a 300-second external deadline. The longer setup-only allowance covered Vivado startup, checkpoint restoration, and parsing of the preserved 16 unrelated bus-skew families. No query timed out.

| Family | Sources | Destinations | Constraint | Required | Worst-slack path datapath delay | Slack | Result |
|---|---:|---:|---|---:|---:|---:|---|
| Slot selector | 2 | 17 | MaxDelay datapath-only | 6.000 ns | 5.939 ns | 0.093 ns | PASS |
| Generation qualifier | 24 | 17 | MaxDelay datapath-only | 6.000 ns | 5.308 ns | 0.724 ns | PASS |
| Epoch qualifier | 32 | 17 | MaxDelay datapath-only | 6.000 ns | 5.423 ns | 0.609 ns | PASS |

`Worst_Actual_ns` in the CSV is explicitly the datapath delay of the worst-slack constrained path returned by Vivado. All three result gates additionally require `REQUIREMENT=6.000`, `userclk1 -> nvp_vclk1`, and `MaxDelay Path 6.000ns -datapath_only`. The common exception value and sequential destination D pins make worst slack the sign-off ordering; BS3 does not mislabel the BS2 58-entry duplicated path collection as a skew set.

The candidate max-delay constraints overlap the retained broader 6.000 ns AXI-to-source mailbox cap at an equal value. Coverage positions 50–52 each cover 100% of their exact per-family startpoints and all 17 destinations; none appears as a totally ignored exception. This overlap cannot weaken safety: either exception selected for an overlapping path imposes the identical absolute requirement, while exact per-family path queries prove the intended direction and value. Owner/architect review should decide whether to retain the explicit redundant family scopes for auditability or promote equivalent named queries against the broad cap.

## Methodology comparison

| Scope | TIMING-32 | TIMING-34 | TIMING-37 | TIMING-38 | TIMING-39 |
|---|---|---|---|---|---|
| Old Group 9 / BS2 focused | absent | present (1) | absent | absent | present (1) |
| New candidate isolated from all bus-skew checks | absent | absent | absent | absent | absent |
| Full preserved context with 16 unrelated bus-skew checks | ABSENT | PRESENT (16) | ABSENT | ABSENT | PRESENT (6) |

Candidate-focused methodology reports `Checks found: 0`. Full-context warnings, if present above, belong to separately preserved bus-skew families and are not attributed to the ownership replacement.

## Runtime viability

| Phase | Runtime |
|---|---:|
| Successful end-to-end worker | 847.611 s |
| External supervised process | 922.850 s |
| Slot worst-path query (before report formatting) | 78.473 s |
| Generation worst-path query (before report formatting) | 0.104 s |
| Epoch worst-path query (before report formatting) | 0.077 s |
| Full focused methodology | 23.854 s |
| Candidate focused methodology | 71.379 s |
| Candidate exception coverage | 10.478 s |
| Candidate ignored-exception report | 10.464 s |

The constraint queries themselves are bounded and practical; checkpoint restoration plus the complete preserved-XDC parse makes the whole offline harness `MARGINAL`. It is neither a multi-hour nor a pathological ownership query. A future sign-off runner should reuse an already-open routed checkpoint when possible and preserve the same 300-second per-command watchdog.

## Final decisions

- `REPLACEMENT_EQUIVALENCE = SAFER_AND_MORE_SEMANTICALLY_CORRECT`.
- `RTL_CHANGE_REQUIRED = NO`.
- `GROUP9_FINAL_DISPOSITION = REPLACE_GLOBAL_BUS_SKEW_WITH_PER_FAMILY_SETTLING_CHECKS`.
- `CANDIDATE_XDC_READY_FOR_META = YES_WITH_OWNER_ARCHITECT_REVIEW`.
- `SIGNOFF_RUNTIME = MARGINAL`.

The current mailbox protocol is structurally sound. Only timing/CDC sign-off methodology needs promotion. This conclusion does not authorize a production-XDC edit in BS3.

## Protection and governance audit

| Protected item | Result |
|---|---|
| FPGA_AHD source modified | NO |
| Active production XDC modified | NO |
| Source Git index changed | NO |
| Source branch movement | NO |
| SSOT/project-current-state modified | NO |
| Synthesis/place/route run | NO |
| Bitstream produced | NO |
| Hardware/JTAG/PCIe/DMA accessed | NO |
| DUT programming/reboot/power-cycle | NO |

`PROJECT_STATE_REV` remained 3. Task-local G2B-LUT1 execution remains on HOLD for BS3 (the unchanged SSOT continues to record its META readiness), G2B implementation/hardware remains BLOCKED/NOT_PROVEN, and the R-track remains HOLD. No project-current-state promotion is performed.

## Recommended next action

Owner/architect should review this evidence and authorize one META change that replaces only the ownership Group-9 `set_bus_skew` with the approved absolute-settling sign-off stanza/queries, preserving all unrelated constraints and requiring the recipe in `G2B_BS3_RECOMMENDED_SIGNOFF_RECIPE.md`. G2B-LUT1 and hardware remain held until that decision.
