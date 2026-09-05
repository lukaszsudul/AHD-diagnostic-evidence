# AHD Current Resource State

`PROJECT_STATE_REV = 8`

## Qualified routed result

| Resource | Used | Device total | Utilization | Status |
|---|---:|---:|---:|---|
| LUT | 18,181 | 20,800 | approximately 87.41% | `ACCEPTED` as qualified-build evidence |
| FF | 20,083 | 41,600 | approximately 48.28% | `ACCEPTED` as qualified-build evidence |
| BRAM tile equivalents | 26 | 50 | 52% | `ACCEPTED` as qualified-build evidence |

BRAM corresponds to 10 RAMB18 plus 21 RAMB36, or 26 tile equivalents.

> **87.41% LUT is the current R1i diagnostic qualified-build result, not the
> final production resource expectation.**

The table above remains the R1i hardware-qualified PoC result. The separate
exact PRODUCT result below is accepted offline; G2B-HW PLANNED / NOT_PROVEN.

## Accepted G2B-LUT0 resource architecture

| Quantity | Value | Evidence boundary |
|---|---:|---|
| Accepted/reference G2A routed LUT | 18,178 / 20,800 | Reference only; mixed-stage comparison warning applies |
| Blocked G2B post-opt LUT | 21,412 / 20,800 (102.942%) | Resource-blocked evidence snapshot; no bitstream |
| Estimated research/diagnostic LUT | approximately 3,900 (range 3,500–4,300) | Planning attribution, not a measured removal result |
| Estimated PRODUCT after Plan B | approximately 17,512 (84.192%) | Estimate only; not qualification evidence |

Actual PRODUCT utilization is 17,366 LUT with offline R1i/functional
regression PASS. Paired-profile diagnostic resource attribution remains
outside this promotion.

## Accepted interpretation

| Statement | Status | Meaning |
|---|---|---|
| Qualified utilization values above | `ACCEPTED` | Exact current routed R1i evidence result |
| Substantial diagnostic/research overhead exists | `ACCEPTED` | Architecture/resource interpretation accepted at G1 |
| Research/diagnostic LUT planning estimate | `ACCEPTED` | Approximately 3,900, range 3,500–4,300; not achieved recovery |
| Current values as final production requirement | `REJECTED` | No such inference is permitted |
| PRODUCT profile reduction architecture | `ACCEPTED` | Reversible exclusion of G2B-LUT0-classified research-only instrumentation is authorized |
| PRODUCT source/sign-off | `ACCEPTED` | Exact Recovery-4 offline candidate; no META-8A source/XDC edit |
| PRODUCT hard gate achieved | `ACCEPTED` | Actual 17366/20800 (83.490%); <=90% and preferred 80–85% PASS |

Named R1h diagnostic islands totaling 2,337 LUT, 3,086 FF, and nine RAMB18 are
a non-additive reference only. They do not prove the exact removable amount in
R1i.

## PRODUCT resource policy

Required routed-build gate: LUT utilization `<= 90%` (`<= 18,720 / 20,800`).

Preferred routed PRODUCT target: `80–85%` (`16,640–17,680 LUT`).

The historical 17,512 LUT / 84.192% remains an estimate. Actual PRODUCT
utilization is 17,366 LUT / 83.490%, meeting both hard gate and preferred band.

## Accepted PRODUCT offline result

Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.

Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.

Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.

Evidence: `6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4`. Bitstream SHA-256 `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`.
No diagnostic-profile resource or hardware claim.

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

PRODUCT implementation accepted offline; research preservation obligations remain:

- research-only probe campaigns and deep histories;
- research index/failed-record BRAMs; and
- supporting diagnostic read services that an accepted interface decision
  permits to remove.

No diagnostic address may be silently reused. PRODUCT functional/MMIO
preservation is accepted offline. Paired diagnostic-profile qualification is
not promoted; excluded research instrumentation must remain recoverable. No
research evidence is deleted, and R-track closure is not claimed.
