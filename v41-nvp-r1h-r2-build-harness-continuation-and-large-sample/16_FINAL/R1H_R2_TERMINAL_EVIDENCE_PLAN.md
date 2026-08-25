# R1h-R2 terminal evidence and sealing plan

Status: `READY_NOT_EXECUTED`

The terminal path is now evidence sealing, publication and hard stop. This
plan authorizes no build, source change, branch push or hardware action.

## Frozen independent inputs

1. The independent full-build monitor audit is PASS and has SHA-256
   `0B1047FA437375890C0BF2D81F8F1C385B552CB38358091B9C990571F6EF1856`.
2. The independent post-synthesis audit is PASS and has SHA-256
   `7AC5BA922A2C4F3DB9C7301BBB81DD7EF74BF0889B3EBC2A26C3C7B0D641224E`.
3. The raw build log, journal, sentinel, terminal receipt, resource
   gate, primitive inventory, utilization reports and synthesis DCP.
4. Exact source worktree post-build identity/cleanliness proof is PASS.
5. Explicit NOT-RUN receipts exist for stages 08 through 15.

## Final report promotion

- The independently reconciled draft has been promoted to the task-local final
  authoritative report.
- The report incorporates both independent audits' exact SHA-256 identities.
- Retain the historical R1h terminal fields required by §21 and add the current
  R1h-R2 terminal classification outside that fixed block.
- Preserve `SYNTHESIS=PASS` while keeping every implementation/hardware result
  explicitly NOT-RUN or NOT-AVAILABLE.
- Keep the Formal Phase 2 values historical; do not claim a fresh board read.
- Run an independent 178-key order/value audit against the verbatim prompt.

## Evidence manifest and package

After the report is frozen:

1. generate one deterministic task evidence manifest covering safely available
   artifacts only;
2. secret-scan the public payload;
3. create
   `V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION_AND_LARGE_SAMPLE_EVIDENCE.zip`;
4. create its external non-circular SHA-256 sidecar;
5. verify every manifest member and ZIP entry count;
6. commit/push one new evidence path normally, with no force-push, tag or
   Release;
7. re-download/stream the commit-pinned public report and package and record
   public remote verification.

The source branch is not eligible for publication because the full build did
not pass. Only the evidence repository may be published.

## Hard-stop accounting to preserve

```text
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
FULL_CLEAN_BUILDS=1
SYNTHESIS_RUNS=1
OPT_DESIGN_RUNS=0
PLACE_DESIGN_RUNS=0
ROUTE_DESIGN_RUNS=0
BITSTREAMS=0
SOURCE_BRANCH_PUSHES=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_READS=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS=0
FORMAL_PHASE2_FRESHLY_RECONFIRMED=NO
SECOND_FULL_BUILD=0
```
