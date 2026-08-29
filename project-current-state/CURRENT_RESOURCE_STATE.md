# AHD Current Resource State

`PROJECT_STATE_REV = 2`

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
result. G2B implementation is `READY` but `NOT_IMPLEMENTED`; hardware
qualification is `NOT_STARTED` and `NOT_PROVEN`. The resource table therefore
remains the qualified R1i result.

The qualified build contains substantial diagnostic/research overhead. The
exact removable diagnostic LUT count is `UNKNOWN`. The R1i–R1h delta mixes
functional and diagnostic changes, so it is not a valid removable-resource
estimate.

## Accepted interpretation

| Statement | Status | Meaning |
|---|---|---|
| Qualified utilization values above | `ACCEPTED` | Exact current routed R1i evidence result |
| Substantial diagnostic/research overhead exists | `ACCEPTED` | Architecture/resource interpretation accepted at G1 |
| Exact removable diagnostic LUT count | `OPEN` | `UNKNOWN` until controlled attribution and accepted reduction |
| Current values as final production requirement | `REJECTED` | No such inference is permitted |
| Current diagnostic retention | `FROZEN` | No removal is authorized while R-track remains active |
| Later controlled reduction | `PLANNED` | Conditional on accepted R-track closure and separate decision |

Named R1h diagnostic islands totaling 2,337 LUT, 3,086 FF, and nine RAMB18 are
a non-additive reference only. They do not prove the exact removable amount in
R1i.

## Resource policy

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

### Retain while R-track is active

Status `FROZEN` pending accepted research closure:

- early/qualified/raw comparisons;
- per-phase and retry-tier detail;
- maximum SCL-wait and first-event identifiers;
- failed-attempt records;
- lifecycle/tri-phase probes;
- deep histories and their MMIO read service; and
- autonomous post-init research campaign support.

### Potential later reduction

Status `PLANNED`, not currently authorized:

- research-only probe campaigns and deep histories;
- research index/failed-record BRAMs; and
- supporting diagnostic read services that an accepted interface decision
  permits to remove.

No diagnostic address may be silently reused. A reduction requires accepted
R-track closure, fanout/behavior proof, explicit Owner/Architect approval,
compatibility review, a controlled A/B evidence gate, and a separate META
update.
