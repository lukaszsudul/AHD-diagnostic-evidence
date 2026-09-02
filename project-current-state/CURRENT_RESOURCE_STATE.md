# AHD Current Resource State

`PROJECT_STATE_REV = 5`

## Qualified routed result

| Resource | Used | Device total | Utilization | Status |
|---|---:|---:|---:|---|
| LUT | 18,181 | 20,800 | approximately 87.41% | `ACCEPTED` as qualified-build evidence |
| FF | 20,083 | 41,600 | approximately 48.28% | `ACCEPTED` as qualified-build evidence |
| BRAM tile equivalents | 26 | 50 | 52% | `ACCEPTED` as qualified-build evidence |

BRAM corresponds to 10 RAMB18 plus 21 RAMB36, or 26 tile equivalents.

> **87.41% LUT is the current R1i diagnostic qualified-build result, not the
> final production resource expectation.**

The accepted G2B-PRE contract freeze adds no implementation or routed-resource
result. G2B-IMPL is not offline-qualified, and G2B-HW is lifecycle `BLOCKED`
and remains `NOT_PROVEN`. The qualified table above therefore remains the R1i
result.

## Accepted G2B-LUT0 resource architecture

| Quantity | Value | Evidence boundary |
|---|---:|---|
| Accepted/reference G2A routed LUT | 18,178 / 20,800 | Reference only; mixed-stage comparison warning applies |
| Blocked G2B post-opt LUT | 21,412 / 20,800 (102.942%) | Resource-blocked evidence snapshot; no bitstream |
| Estimated research/diagnostic LUT | approximately 3,900 (range 3,500–4,300) | Planning attribution, not a measured removal result |
| Estimated PRODUCT after Plan B | approximately 17,512 (84.192%) | Estimate only; not qualification evidence |

The exact achieved recovery remains unknown until controlled paired profile
builds and post-route requalification. The R1i functional fix is separable
from research instrumentation, but mixed counters still require signal-level
fanout proof during G2B-LUT1.

## Accepted interpretation

| Statement | Status | Meaning |
|---|---|---|
| Qualified utilization values above | `ACCEPTED` | Exact current routed R1i evidence result |
| Substantial diagnostic/research overhead exists | `ACCEPTED` | Architecture/resource interpretation accepted at G1 |
| Research/diagnostic LUT planning estimate | `ACCEPTED` | Approximately 3,900, range 3,500–4,300; not achieved recovery |
| Current values as final production requirement | `REJECTED` | No such inference is permitted |
| PRODUCT profile reduction architecture | `ACCEPTED` | Reversible exclusion of G2B-LUT0-classified research-only instrumentation is authorized |
| Profile source/sign-off recovery | `PLANNED` | G2B-LUT1 `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-2`; no source or active-XDC change implemented by META-5 |
| PRODUCT hard gate achieved | `OPEN` | Must be demonstrated by actual post-route utilization |

Named R1h diagnostic islands totaling 2,337 LUT, 3,086 FF, and nine RAMB18 are
a non-additive reference only. They do not prove the exact removable amount in
R1i.

## PRODUCT resource policy

Required routed-build gate: LUT utilization `<= 90%` (`<= 18,720 / 20,800`).

Preferred routed PRODUCT target: `80–85%` (`16,640–17,680 LUT`).

The estimated 17,512 LUT / 84.192% point lies inside the preferred band, but
the estimate is not qualification evidence and the target is not marked
achieved. `G2B-LUT1-SIGNOFF-RECOVERY-2`/G2B-IMPL must measure actual post-route
utilization.

The META-4R2 Group-9 and META-5 Group-13 sign-off-method promotions change no
measured or estimated resource value in this document. Group 9 PASS and Groups
10–12 PASS are preserved; the Group-13 candidate implementation, Groups 14–17,
and remaining routed resource hard gate are still pending.

## Existing G1 resource policy

The accepted G1 resource policy is `FROZEN`:

### Development hard stops

Stop on any of:

- post-opt or routed LUT greater than 90%;
- FF greater than 80%;
- BRAM greater than 80%;
- unroutable design or severe congestion;
- non-positive setup or hold margin; or
- unexplained resource movement that invalidates the accepted decomposition.

Preferred development LUT utilization is at or below 85%.

### Release-candidate targets

- routed LUT at or below 85%, with 80% or below as the objective;
- FF at or below 70%;
- BRAM at or below 75%;
- no level-5-or-higher congestion;
- WNS at least max(0.25 ns, 3% of the shortest relevant period);
- WHS at least 0.02 ns;
- zero TNS and THS; and
- clean DRC, CDC, clock, routing, and provenance evidence.

These thresholds are policy, not proof that the current product meets a future
release target.

## Diagnostic preservation and reduction

### Must remain functional

Status `FROZEN`:

- qualified ACK timing and physical-SCL behavior;
- STOP/BUS_FREE behavior;
- retry/backoff and timeout behavior;
- recovered-versus-terminal error distinction;
- bank verification/invalidation and safety; and
- product-critical NVP, DMA, drop, reset, and channel-state telemetry.

### Retain in RESEARCH_DIAGNOSTIC

Required for reproducible R2/R3 resumability:

- early/qualified/raw comparisons;
- per-phase and retry-tier detail;
- maximum SCL-wait and first-event identifiers;
- failed-attempt records;
- lifecycle/tri-phase probes;
- deep histories and their MMIO read service; and
- autonomous post-init research campaign support.

### Authorized PRODUCT exclusion boundary

Lifecycle `PLANNED`, authorization state `AUTHORIZED_NOT_IMPLEMENTED`:

- research-only probe campaigns and deep histories;
- research index/failed-record BRAMs; and
- supporting diagnostic read services that an accepted interface decision
  permits to remove.

No diagnostic address may be silently reused. G2B-LUT1 must prove fanout and
functional equivalence, preserve externally visible MMIO behavior, produce
paired profile resource/functional evidence, and keep all excluded research
instrumentation reproducibly recoverable through RESEARCH_DIAGNOSTIC. No
research evidence is deleted, and R-track closure is not claimed.
