# AHD v41 G2B-IMPL CDC Audit

## Result and boundary

`CDC_AUDIT = PASS`

The RTL/static CDC design and focused CDC/reset simulations pass for the sealed
source snapshot (`v41_g2b_onech_c2h.sv` SHA-256
`8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471`;
`g2b_cdc.xdc` SHA-256
`CF04780F16EDAD391393D15E6033E96EC89CC3CE31A6DF48ADF1C05408FA5246`).

The clean build stopped at the post-opt LUT resource gate before placement and
routing. Therefore the build-time routed endpoint re-resolution,
`report_cdc`, `report_bus_skew`, and exception-coverage gates are `NOT_RUN`.
This report is a static/focused-simulation PASS, not routed CDC qualification.

## Domains

| Domain | Clock/reset | Role |
|---|---|---|
| Source | `source_clk = nvp_clk`; explicit source-local reset | active-line validation, admission, formatter, slot ownership source bank, source counters |
| AXI/MMIO | `axi_clk = axi_aclk`; `axi_aresetn` episode handling | MMIO, scheduler, AXI4-Stream, global counters/sequences, reset coordinator |

The product top ties the explicit source-reset and standalone-formatter-reset
causes low; both protocols are exercised in simulation. NVP/source reset is not
a transport epoch cause.

## Crossing inventory

| Source → destination | Signal/group | Method | Reason and constraint | Verification |
|---|---|---|---|---|
| AXI → source | enable request toggle and held enable value | two `ASYNC_REG` stages plus acknowledged stable-data mailbox | MMIO write must complete only after source application; first-stage false path, mailbox max delay 6 ns / bus skew 3 ns | enable/disable, reset-overtake, response-timing tests PASS |
| Source → AXI | enable acknowledgement | two-stage acknowledged toggle | closes enable mailbox transaction | enable completion tests PASS |
| AXI → source | transport-reset request; epoch, hard/soft cause, release phase, ownership phase | two-stage toggle plus held mailbox | all-domain reset must retire prior ownership/release tokens before acknowledgement; first-stage false path and 6 ns/3 ns bundled-data constraints | hard/soft/overlap/reset-retirement tests PASS |
| Source → AXI | transport acknowledgement; abandoned/filling/commit phase/ownership result holds | two-stage toggle plus stable mailbox | coalesced reset completion and exact abandoned-record accounting | reset overlap, final-beat/reset, commit-retirement tests PASS |
| Source → AXI | standalone reset request episode | source level converted to acknowledged toggle, then two stages | one request per level episode with no lost repeated episode | standalone/host overlap fixture PASS; product cause not instantiated |
| AXI → source | standalone acknowledgement | two-stage phase return | permits source to retire/reissue a later level episode | reset-overlap test PASS |
| AXI → source | statistics-clear request | two-stage request/ack toggle | coherent source-domain clear with no premature MMIO completion | statistics-reset legality/timing tests PASS |
| Source → AXI | statistics-clear acknowledgement | two-stage toggle | completes W1C/control transaction only after source clear | MMIO test PASS |
| AXI → source | snapshot request and held requested epoch | two-stage toggle plus stable mailbox | freezes one source-domain counter bank at a defined epoch | snapshot request/ack/epoch tests PASS |
| Source → AXI | snapshot acknowledgement | two-stage toggle | qualifies stable held Gray values | settling/barrier tests PASS |
| Source → AXI | attempted, committed, dropped, overflow snapshot words | source-registered binary-to-Gray holds, two vector synchronization stages, full settling edge, decode into shadow registers | no raw live multibit counter exposure; max delay 6 ns and bus skew 3 ns to first stages | coherent snapshot and reset invalidation tests PASS |
| Source → AXI | snapshot epoch echo | held stable qualifier through two vector stages | before/after epoch consistency rule; same 6 ns/3 ns constraints | epoch mismatch/late-token tests PASS |
| AXI → source | ownership request with slot, generation, epoch | two-stage toggle plus stable mailbox | generation/epoch-protected `COMMITTED → DMA_OWNED` transition | valid/stale/illegal ownership tests PASS |
| Source → AXI | ownership acknowledgement and `own_ok` hold | two-stage toggle plus held response | scheduler cannot offer beat 0 before source ownership approval | own-retirement and stale-request tests PASS |
| Source → AXI | per-slot commit toggles and descriptor attempt/generation/epoch holds | two-stage commit phase plus stable descriptor mailbox | atomic publication of an immutable committed slot; no multibit descriptor sampling before phase settling | commit FIFO/order/prefetch tests PASS |
| AXI → source | per-slot release toggle with generation/epoch holds | two-stage release phase plus held data | release only after beat-511 handshake; stale release rejected | final-beat and generation protection tests PASS |
| Source → AXI | registered ring-empty/ring-full, source-ready, source-locked | source-domain registered predicates, individual two-flop single-bit synchronizers | avoids raw ownership-vector CDC; status is live advisory state | registered-predicate latency/status tests PASS |
| Source → AXI | overflow, drop, formatter-fatal, ownership-fatal event phases | acknowledged event toggles through two stages | sticky events cannot be lost when domains run independently | overflow/drop/fatal priority and W1C tests PASS |
| AXI → source | event acknowledgements and fatal admission stop | individual two-stage synchronizers | retires event phases and stops new source admission on fatal | fatal/recovery/deferred-event tests PASS |
| Source → AXI | hard-clear event baseline plus clear-boundary token | held 4-bit stable mailbox, two vector stages, synchronized qualifier; dedicated 6 ns/3 ns constraint | masks pre-hard-reset event history without losing post-boundary events | hard-reset baseline/priority tests PASS |
| Source memory write → AXI memory read | four 4,096-byte record memories | four XPM simple dual-port RAMs with independent clocks; ownership/descriptor handshake surrounds access | payload is not crossed as raw logic; AXI reads only after committed ownership and one prefetch settling state | byte-exact records, no tear/overwrite, arbitrary-stall tests PASS |

## Reset integrity

Cross-domain request/ack phases are persistent protocol state rather than
single-cycle pulses. Transport reset captures both release and ownership
phases, waits for their source-domain retirement, captures the final commit
phase, and only then acknowledges completion. Epoch/generation checks reject
stale ownership or release. A final beat coincident with reset is counted once
and is not falsely abandoned. Overlapping PCIe/host/standalone causes coalesce
into one epoch increment. Source reset restarts only the source-local capture
bank and does not replay NVP initialization.

## Constraint audit

`g2b_cdc.xdc` is additive to the accepted legacy `cdc.xdc` and names only the
G2B hierarchy. It applies false paths only to explicit first-stage
synchronizer D pins. Snapshot Gray/epoch, stable mailboxes, and the hard-clear
baseline additionally receive 6 ns datapath-only maximum delay and 3 ns bus
skew limits. The build harness contains matching nonempty routed endpoint
queries and would fail unresolved collections; that routed gate was not reached
because of the earlier resource blocker.

## Disposition

No unsafe raw multibit CDC was identified. The required static CDC audit and
focused verification are PASS. A future resource-closed candidate must still
pass routed CDC, bus-skew, exception coverage, and timing checks before offline
qualification.
