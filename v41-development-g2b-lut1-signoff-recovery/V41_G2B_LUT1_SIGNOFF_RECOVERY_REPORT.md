# AHD v41 G2B-LUT1 Sign-Off Recovery Report

## Executive disposition

| Field | Result |
|---|---|
| Engineering gate | BLOCKED |
| Evidence publication | PENDING |
| Overall result | BLOCKED |
| First blocker | REQUIRED_BUS_SKEW_TIMEOUT:GROUP_13:RESET_RETURN_SOURCE_TO_AXI:QUERY_EXCEEDED_300_SECONDS_FROM_QUERY_STARTED_MARKER |
| Pre-bitstream hard gate | FAIL |
| Bitstream produced | NO |
| Debug probes produced | NO |
| Hardware accessed | NO |
| G2B-HW | NOT_PROVEN |

The promoted Group-9 replacement sign-off passed, and required Groups 10, 11,
and 12 passed their unchanged 3.000 ns bus-skew requirements. Group 13 did not
return a report within its governed 300-second query budget. The external
watchdog recorded 301.094 s, terminated the Vivado process tree, classified
the exact group as REQUIRED_BUS_SKEW_TIMEOUT, and stopped the sequence.
Groups 14-17 and every downstream routed final-signoff phase were therefore
not run. No bitstream or LTX was generated.

## Governance authority

| Authority | Verified identity / state |
|---|---|
| Evidence repository | lukaszsudul/AHD-diagnostic-evidence |
| SSOT | project-current-state, PROJECT_STATE_REV = 4 |
| SSOT state | G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY; G2B-HW = BLOCKED |
| META-4R2 directory | v41-meta-project-state-rev4-ownership-cdc-signoff |
| META-4R2 evidence commit | 27dcf152e862c6db88a365328b92c0fd250f04c2 |
| META-4R2 | VERIFIED |
| Retired Group-9 method | GLOBAL_SET_BUS_SKEW_3NS |
| Promoted Group-9 method | PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC |
| BS3 directory | v41-development-g2b-bs3-ownership-mailbox-settling-proof |
| BS3 evidence commit | 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae |
| BS3 candidate | VERIFIED |

No SSOT file was changed. PROJECT_STATE_REV remained 4. This blocked
engineering result does not authorize a META promotion.

## Governed source change

| Field | Identity |
|---|---|
| Source worktree | C:\FPGA\V41_G2B |
| Branch | integration/v41-g2b-onech-c2h |
| Parent | 224d194e5f82c85bcb29297561c5d5e76d28063b |
| Governed commit | 66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49 |
| Source tree | 1e67e3f1fe06669839fe9ff8573e4d1e0114a889 |
| Commit subject | Implement META-4 ownership CDC sign-off constraints for G2B-LUT1 |
| Active XDC | xdc/common/g2b_cdc.xdc |
| Sealed old active-XDC SHA-256 | 2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF |
| Governed active-XDC SHA-256 | 6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227 |
| BS3 candidate Git blob | 7c146a09feb4b37b55ba7398ff82c19b898b8c4c |
| BS3 candidate SHA-256 | AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087 |

The XDC scope audit passed. Exactly one retired Group-9 set_bus_skew command
was removed and the exact three-family BS3 candidate was inserted. All other
bus-skew constraints, Groups 10-17, clocks, false paths, and max-delay
constraints outside Group 9 remained unchanged. No RTL, XCI, ABI, MMIO, R1i,
R-track, or HDMI source was changed.

## Routed-DCP reuse decision

- RECOVERY_MODE = ROUTED_DCP_REUSE
- DCP_REUSE_VALID = YES
- FULL_REBUILD_EXECUTED = NO
- FULL_REBUILD_TRIGGER = NONE

| Routed input | Identity |
|---|---|
| DCP | C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp |
| Size | 57,900,063 bytes |
| SHA-256 | EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83 |
| Device | xc7a35tcsg325-2 |
| Routed identity | fully routed, 33,985/33,985 routable nets |
| Vivado | 2025.2, SW build 6299465 |
| Full base XDC SHA-256 | 3680EE8998503D10713D930D7D9D44AD0D71B273A9252D364A3BEE2D0D6AD507 |

The source delta is constraints-only, all netlist-bearing Gen12 inputs retain
their sealed identities, and BS3 successfully reloaded the promoted timing
context against this exact routed DCP. No rebuild authorization trigger was
present, and no synthesis, optimization, placement, physical optimization,
or routing command was executed.

## Group-9 promoted sign-off

- GROUP_9_REPLACEMENT_SIGNOFF = PASS
- GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = NO

| Family | Required (ns) | Actual worst (ns) | Slack (ns) | Sources | Destinations | Result |
|---|---:|---:|---:|---:|---:|---|
| Slot | 6.000 | 5.939 | 0.093 | 2 | 17 | PASS |
| Generation | 6.000 | 5.308 | 0.724 | 24 | 17 | PASS |
| Epoch | 6.000 | 5.423 | 0.609 | 32 | 17 | PASS |

The ownership request synchronizer, acknowledgement synchronizer, stable-data
hold, reset/epoch coherency, and ownership structural CDC proof all passed.
Candidate TIMING-34 and TIMING-39 findings were absent. The fresh post-family
validate_all audit reached a bounded timeout only after every required family
result had been written and independently validated; it was not a required
Group-9 family failure.

## Groups 10-17

The unchanged groups were run sequentially with one attempt per group. Each
worker allowed up to 1,800 seconds before QUERY_STARTED.marker and enforced a
300-second external budget from that marker. Each query used:

    report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1
      -warn_on_violation

| Group | Name | Runtime (s) | Required (ns) | Actual (ns) | Slack (ns) | Sources / destinations | Result |
|---:|---|---:|---:|---:|---:|---:|---|
| 10 | DESCRIPTOR_ATTEMPT_SOURCE_TO_AXI | 102.909 | 3.000 | 1.199 | 1.801 | 44 / 32 | PASS |
| 11 | DESCRIPTOR_GENERATION_SOURCE_TO_AXI | 102.835 | 3.000 | 1.070 | 1.930 | 32 / 24 | PASS |
| 12 | DESCRIPTOR_EPOCH_SOURCE_TO_AXI | 82.701 | 3.000 | 1.664 | 1.336 | 128 / 32 | PASS |
| 13 | RESET_RETURN_SOURCE_TO_AXI | 301.094 | 3.000 | N/A | N/A | 7 / 207 pre-query inventory | REQUIRED_BUS_SKEW_TIMEOUT |
| 14 | RELEASE_SLOT_0_AXI_TO_SOURCE | 0.000 | 3.000 | N/A | N/A | not run | NOT_RUN_AFTER_BLOCKER |
| 15 | RELEASE_SLOT_1_AXI_TO_SOURCE | 0.000 | 3.000 | N/A | N/A | not run | NOT_RUN_AFTER_BLOCKER |
| 16 | RELEASE_SLOT_2_AXI_TO_SOURCE | 0.000 | 3.000 | N/A | N/A | not run | NOT_RUN_AFTER_BLOCKER |
| 17 | RELEASE_SLOT_3_AXI_TO_SOURCE | 0.000 | 3.000 | N/A | N/A | not run | NOT_RUN_AFTER_BLOCKER |

Groups 10-12 each recorded two nonblocking project-load warnings: a duplicate
user-strategy definition and an already-present BS3 candidate XDC. Group 13
recorded the same two warnings; neither warning supplied a timing result or
changed the timeout classification.

For Group 13, the full worker elapsed time was 998.628 s, including routed-DCP
initialization. The governed query interval was 301.094 s. No compact bus-skew
report completed, so no actual or slack value exists and no PASS may be
inferred. The watchdog issued process-tree termination; an immediate wrapper
receipt observed one process during termination cleanup, and the subsequent
independent task-list audit confirmed zero Vivado and zero Vivado Lab
processes before this evidence package was finalized.

Aggregate Groups 10-17 receipt:

- GROUPS_PASS = 3
- GROUPS_TIMEOUT = 1
- GROUPS_FAIL = 4, representing the four not-run downstream groups
- GROUPS10_17_GATE = FAIL
- Results CSV SHA-256 =
  666A403FC01DADE0E95D3329D119473CF8D7D0E7EAD2B1E624F495FDAB5FFFF7

## Downstream routed sign-off

The Group-13 hard blocker prevented the finalizer from starting. The following
are current-run dispositions, not inherited results:

| Gate | Disposition |
|---|---|
| Groups 14-17 | NOT_RUN_AFTER_BLOCKER |
| Final routed-signoff finalizer | NOT_RUN |
| Fresh routed setup/hold/recovery-removal qualification | NOT_RUN |
| WNS / TNS / WHS / THS | N/A |
| No-clock, unconstrained endpoints, timing loops, latch loops | NOT_RUN |
| Final DRC | NOT_RUN |
| General CDC report and exact disposition | NOT_RUN |
| Ownership CDC | PASS through the promoted Group-9 gate |
| Final clock review and effective implemented clocks | NOT_RUN |
| PRODUCT utilization and LUT hard gate | NOT_RUN |
| Black-box and other final pre-bit checks | NOT_RUN |

Historical raw timing, DRC, CDC, clock, or resource data is not promoted as a
fresh final result. In particular, the historical raw CDC critical count is
not treated as either a current PASS or an automatic current FAIL; the
required exact general-CDC disposition did not run.

## Offline functional protection and throughput

The independent offline protection gate passed and remains useful supporting
evidence, but it cannot override the Group-13 sign-off blocker.

| Item | Result |
|---|---|
| Transport ABI | AHD_C2H_TRANSPORT_ABI_V1 |
| ABI version | 1 |
| MMIO | 0x3800..0x3BFF |
| ABI/MMIO unchanged | YES |
| R1i protected behavior | PASS |
| PRODUCT profile protection | PASS_HASH_BOUND |
| XDMA configuration preserved | PASS |
| XDMA XCI SHA-256 | 9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F |
| Governed PCIe setting | Gen2 5.0 GT/s, x1 |
| Configured user clock used by offline arithmetic | 62.5 MHz |
| Offline throughput gate | PASS |
| Required payload | 288 MB/s |
| Stall-free useful-payload ceiling | 468.750 MB/s |
| Hardware throughput proven | NO |

The one-channel C2H path, four-slot ring, record formatter, backpressure,
sequence/reset-epoch semantics, host parser, ABI, MMIO, and R1i protected
behavior retain their exact-hash-bound protection evidence. No hardware
performance or functionality is claimed.

## Pre-bitstream hard stop

PRE_BITSTREAM_HARD_GATE = FAIL

The hard gate fails because Groups 10-17 are incomplete and the required
routed timing, DRC, general CDC, clock, resource, and remaining final checks
did not run. Consequently:

- no .bit was generated;
- no .ltx was generated;
- no product bitstream candidate exists; the candidate-identity JSON is a
  fail-closed no-candidate record with null bitstream/LTX fields;
- no FPGA was programmed;
- no DUT, PCIe, DMA, or hardware test was performed;
- G2B-HW = NOT_PROVEN.

## Evidence publication status

The recovery evidence is staged under:

    C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery

Publication to lukaszsudul/AHD-diagnostic-evidence branch main is still
pending. There is no recovery evidence commit yet, no push has been performed,
and remote read-back has not run.

- EVIDENCE_PUBLICATION = PENDING
- REMOTE_READ_BACK = NOT_RUN

## Required next governance action

Do not run a second speculative Group-13 query, do not start the finalizer,
and do not generate a bitstream under this gate. The exact next action is to
obtain a governed decision for recovery or bounded replacement analysis of
required Group 13, then resume Groups 13-17 and the untouched downstream final
gates only under that authority.

FINAL_EXECUTION_POINT = HARD_STOP_AT_GROUP_13_REQUIRED_BUS_SKEW_TIMEOUT
