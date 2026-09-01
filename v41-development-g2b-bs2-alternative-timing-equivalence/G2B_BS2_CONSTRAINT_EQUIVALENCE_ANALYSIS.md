# G2B-BS2 Constraint Equivalence Analysis

## Original Group-9 constraint

The final Gen12 source constraint is in `C:\FPGA\V41_G2B\xdc\common\g2b_cdc.xdc` (SHA-256 `2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF`):

```tcl
set g2b_ownership_payload_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(own_slot_hold_axi|own_generation_hold_axi|own_epoch_hold_axi|axis_slot|axis_generation|axis_epoch)_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_ownership_payload_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_req_seen_source|own_ack_toggle_source|own_ok_hold_source)_reg.*}] {IS_SEQUENTIAL == 1}]
set_bus_skew 3.000 -from $g2b_ownership_payload_src -to $g2b_ownership_payload_dst
```

The routed isolated rendering is `09_OWNERSHIP_AXI_TO_SOURCE_ISOLATED.xdc`, SHA-256 `06F27BB2D3E5E6D8691274F7C9D28A8C560F218ADCDD53D173ECFA6AE696A754`. The resolved object inventory has SHA-256 `CE4E8A35CB82CCD0A85AEBF340B997D74FEF9250C86BA76C61769E332079F4DB`.

### Exact original source set

The physical source set is exactly the 58 objects preserved in `G2B_BS2_SOURCE_SET.txt`:

- `G2B_ONECH_C2H/axis_epoch_reg[0..31]`
- `G2B_ONECH_C2H/axis_generation_reg[0..23]`
- `G2B_ONECH_C2H/axis_slot_reg[0..1]`

Source-set SHA-256: `F69E9199EBB6212346DA11AC7EB66D832D2E50CCF8F43C5401806780E15247EE`.

The RTL `own_*_hold_axi` registers are not separate routed launch objects because synthesis merges them with same-edge `axis_*` staging registers.

### Exact original destination set

The original destination set contains 19 objects:

```text
G2B_ONECH_C2H/enable_applied_source_reg
G2B_ONECH_C2H/own_ack_toggle_source_reg
G2B_ONECH_C2H/own_ok_hold_source_reg
G2B_ONECH_C2H/own_req_seen_source_reg
G2B_ONECH_C2H/slot_state_source_reg[0][0]
G2B_ONECH_C2H/slot_state_source_reg[0][1]
G2B_ONECH_C2H/slot_state_source_reg[0][2]
G2B_ONECH_C2H/slot_state_source_reg[1][0]
G2B_ONECH_C2H/slot_state_source_reg[1][1]
G2B_ONECH_C2H/slot_state_source_reg[1][2]
G2B_ONECH_C2H/slot_state_source_reg[2][0]
G2B_ONECH_C2H/slot_state_source_reg[2][1]
G2B_ONECH_C2H/slot_state_source_reg[2][2]
G2B_ONECH_C2H/slot_state_source_reg[3][0]
G2B_ONECH_C2H/slot_state_source_reg[3][1]
G2B_ONECH_C2H/slot_state_source_reg[3][2]
G2B_ONECH_C2H/source_ownership_fatal_deferred_reg
G2B_ONECH_C2H/source_ownership_fatal_event_reg
G2B_ONECH_C2H/source_ownership_fatal_reg
```

These destinations span five roles: slot state, request/ack bookkeeping, ownership result, fatal effects, and admission interlock. BS2 intentionally narrows the destination set to the singleton ownership result.

## Original engineering intent

The XDC comments state that stable-data mailbox payloads are held from request launch through returned acknowledgement, that the toggle supplies coherency, and that timing constraints provide physical delay/skew bounds. For ownership, the intent was to prevent a stale or mixed slot/generation/epoch token from authorizing `COMMITTED -> DMA_OWNED`.

The presence of the constraint is not proof that a 3.000 ns relative spread is the correct safety property. BS2 finds that the ownership data is not captured as 58 parallel destination bits. It is consumed by a request-gated selector/equality cone.

## Absolute delay is not bus skew

`set_max_delay -datapath_only` and `set_bus_skew` prove different properties:

- max delay bounds each path's absolute propagation time;
- bus skew bounds the relative spread between path arrival times.

A 6.000 ns max-delay success cannot be relabeled as a 3.000 ns bus-skew success. Conversely, a 3.000 ns arrival spread would not prove that all data settled before the synchronized request, nor that the payload remained stable until acknowledgement.

For this mailbox, an absolute settling bound becomes appropriate only when combined with structural proof of request/ack ordering and payload stability.

## Strategy evaluation

| Strategy | Exact property proven | Property not proven | Runtime expectation | Implementation impact | Sign-off clarity | False-confidence risk |
|---|---|---|---|---|---|---|
| **A. KEEP_SET_BUS_SKEW as written** | If the report completes, relative spread across the selected 58x19 path population | Payload stability, request/ack ordering, absolute settle-before-consume, semantic comparability | Pathological; exact 58x1 already exceeded 300 s in BS1R | No RTL; no XDC change | Low: five destination roles and deep decision cones are mixed | High |
| **B. KEEP_BUT_SPLIT by semantic source/sink family** | Relative spread within each chosen subset | Absolute settling and handshake correctness | Lower than A, but reconvergent Boolean sinks may remain expensive | XDC-only change | Medium | Medium: splitting can make a structurally invalid skew comparison look authoritative |
| **C. Narrow set_bus_skew per coherent CDC bundle** | Relative arrival spread at a genuinely comparable receiver bundle | Absolute delay, handshake, or correctness of aggregate decision cones | Bounded when applied to shallow parallel capture pins | XDC-only; requires exact bundle discovery | High for real multibit capture bundles | Low for real bundles; high if applied to `own_ok`-style aggregate sinks |
| **D. set_max_delay -datapath_only** | Worst absolute path delay | Relative spread and temporal payload-hold behavior | Fast: exact worst-path report completed in 64.164 s | Existing broad 6 ns constraint already present; revised bound would be XDC-only | Medium by itself | High if called “equivalent bus skew”; low when paired with structural proof |
| **E. Explicit per-family max-delay constraints** | Absolute settling for slot-select, generation-compare, epoch-compare, and each destination family | Relative spread and handshake correctness | Predictable, bounded worst-path queries per family | XDC-only change | High if budgets are derived from the request window | Low to medium |
| **F. CDC structural proof plus no ownership bus-skew requirement** | Stable launch/hold, two-stage request and ack synchronization, consume-after-request/ack protocol | Physical settling margin unless an absolute delay bound is retained | Low runtime for static checks; formal/structural proof cost is bounded separately | No RTL change if proof passes; remove Group-9 bus skew only after replacement review | High | Low when combined with D/E; medium if physical delay is omitted |
| **G. Redesign CDC if unsafe multibit simultaneity is required** | Depends on redesign; a registered capture bank could create a true bundle boundary | Existing design correctness until reimplemented/requalified | Highest | RTL, XDC, implementation, and requalification changes | Potentially high after full proof | High during migration; unnecessary on current evidence |

## Alternative sign-off decision

`ALTERNATIVE_SIGNOFF = FEASIBLE_WITH_CONSTRAINT_CHANGES`

This does not mean the 3.000 ns numerical bus-skew requirement was reproduced. It means the implemented mailbox's actual safety invariant can be signed off more directly by replacing the ownership bus-skew check with a structural-plus-absolute-delay methodology.

## Exact bounded sign-off recipe

1. Freeze and hash the exact ownership payload and all payload-dependent destination families.
2. Prove structurally that slot, generation, epoch, and request launch together; the payload remains stable through acknowledgement; and request/ack each cross two intended synchronizer stages.
3. Derive a maximum data-settling budget from the minimum synchronized-request observation window, including setup, uncertainty, and explicit margin. Do not assume 6.000 ns merely because it exists today.
4. Apply `set_max_delay -datapath_only` per coherent ownership source family and per payload-dependent destination family using the derived budget. Assert nonempty exact counts.
5. Run one bounded worst-path `report_timing -delay_type max -max_paths 1 -nworst 1` for every family. The worst path, not enumerated path count, is the absolute-delay sign-off object.
6. Run focused CDC and methodology checks, including TIMING-32/34/37/38/39, and confirm no asynchronous control bypass or uncovered payload-dependent sink.
7. Remove the current Group-9 `set_bus_skew` only in a separately authorized XDC change after the replacement constraint diff and structural proof are reviewed.

The capped `get_timing_paths` call is useful diagnostic evidence, but it is not part of the proposed pass/fail recipe because `-nworst` did not yield one path per source.

