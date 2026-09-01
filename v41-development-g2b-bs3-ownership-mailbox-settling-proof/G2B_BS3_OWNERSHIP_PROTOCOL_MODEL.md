# G2B-BS3 Ownership Protocol Model

## Scope and authority

This model reconstructs `OWNERSHIP_AXI_TO_SOURCE` from the RTL used by the sealed Gen12 routed checkpoint and from the BS0/BS2 evidence. The relevant RTL is `C:\FPGA\V41_G2B\rtl\g2b\v41_g2b_onech_c2h.sv`, SHA-256 `8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471`. The physical checkpoint merges the logical ownership hold registers with the same-edge AXIS staging registers.

Sender/domain clocks:

- sender: AXI domain, routed clock `userclk1`, period 16.000 ns;
- receiver: source/video domain, routed clock `nvp_vclk1`, period 6.734 ns.

## CONTROL CDC

The request is one toggle crossing a two-stage synchronizer:

`own_req_toggle_axi -> own_req_sync1_source -> own_req_sync2_source`

The acknowledgement is one toggle crossing a two-stage synchronizer in the reverse direction:

`own_ack_toggle_source -> own_ack_sync1_axi -> own_ack_sync2_axi`

All four synchronizer registers have `ASYNC_REG=TRUE`. The production CDC XDC false-paths only first-stage D pins. The routed Gen12 `CDC.rpt` classifies both chains as `CDC-3`, depth 2, with the first-stage false path recognized.

`own_req_seen_source` and `own_ack_toggle_source` are request-phase bookkeeping. Although they were included among the old 19 Group-9 destinations, neither is a semantic payload sink.

## STABLE DATA PAYLOAD

The logical forward payload is one 58-bit ownership token:

| Field | RTL hold identity | Routed launch identity | Width | Role |
|---|---|---|---:|---|
| slot | `own_slot_hold_axi` | `axis_slot_reg[0:1]` | 2 | Select one of four slots |
| generation | `own_generation_hold_axi` | `axis_generation_reg[0:23]` | 24 | Reject a stale/reused slot token |
| epoch | `own_epoch_hold_axi` | `axis_epoch_reg[0:31]` | 32 | Reject a token from an older transport-reset epoch |

The reverse stable result is `own_ok_hold_source`. It is produced with the acknowledgement and consumed only after the acknowledgement has crossed back. Its existing source-to-AXI 6.000 ns aggregate max-delay protection remains in place.

## Launch and receive behavior

At `scheduler_pop`, on one AXI edge, the design:

1. loads `axis_slot`, `axis_generation`, and `axis_epoch`;
2. loads the duplicate logical `own_*_hold_axi` registers with the same values;
3. toggles `own_req_toggle_axi`;
4. changes `axis_state` from `AXIS_IDLE` to `AXIS_WAIT_OWN`.

The request and data therefore launch on the same edge; there is no full AXI cycle of pre-request data setup. Correctness comes from the registered launch, the two-stage control synchronizer plus registered request detection, a bounded payload datapath, and the hold-until-ack protocol.

The source domain recognizes a request only when:

`!transport_retire_pending_source && transport_req_sync2_source == transport_req_seen_source && own_req_sync2_source != own_req_seen_source`

It accepts the token only if all of these are true:

- `slot_state_source[slot] == SLOT_COMMITTED`;
- `slot_generation_source[slot] == generation`;
- `desc_epoch_source[slot] == epoch`;
- `reset_epoch_source == epoch`.

On success it changes the selected slot to `SLOT_DMA_OWNED` and sets `own_ok_hold_source`. On failure it keeps the result low, latches ownership-fatal handling, and disables source admission. On the same source edge it records the request phase and launches the acknowledgement.

## Slot/generation/epoch state

There are four slots, each represented by a 3-bit state with five defined encodings: `WRITABLE`, `FILLING`, `COMMITTED`, `DMA_OWNED`, and `RELEASABLE`. Allocation increments the selected 24-bit generation. Commit publishes descriptor generation and epoch with the commit toggle. Ownership validates both fields before DMA ownership. Release repeats generation, descriptor-epoch, current-epoch, and state qualification before returning a slot toward `WRITABLE`.

The 2-bit slot is selector data, not a control synchronizer. Generation and epoch are equality qualifiers. Their comparator/decode cones reconverge into one registered ownership decision and its failure effects.

## Source hold behavior

The forward payload registers are assigned only in the `scheduler_pop` branch. `scheduler_pop` requires `axis_state == AXIS_IDLE` and all reset/busy guards to be clear. In normal operation the launch changes the state to `AXIS_WAIT_OWN`; later states are `AXIS_PREFETCH`, `AXIS_STREAM`, or `AXIS_ERROR_HOLD`. A reset may force `AXIS_IDLE` before normal acknowledgement consumption, but `stream_reset_busy_axi` and reset-phase retirement keep `scheduler_pop` false. Therefore no second payload write is possible until the normal result has been consumed or the old transaction has been explicitly cancelled and retired by reset.

`own_ok_hold_source` changes only on a later source-domain ownership request. It is consequently stable throughout reverse acknowledgement synchronization and AXI result consumption.

## Reset and phase retirement

Mailbox phases and reset epoch use configuration-time initialization and deliberately survive later `axi_aresetn` episodes. Initial `axi_aresetn=0` before `axi_seen_high` is intentionally masked and relies on configuration-zero phases and writable initial slot state. A later low launches one hard episode; `axi_hard_episode` prevents retrigger while reset remains low. A transport/hard reset captures the current release vector and ownership-request phase. The source-domain transport-reset handler has priority over ordinary ownership decoding, makes slots writable, zeros slot generations, installs the new epoch, and aligns `own_req_seen_source`/`own_ack_toggle_source` to the captured phase. If a captured ownership request has not yet reached sync2, `transport_retire_pending_source` withholds transport acknowledgement until it does. If a hard reset arrives during an active transport reset, `transport_followup_hard_axi` coalesces it into a follow-up episode instead of cancelling the in-flight request toggle.

This retirement barrier prevents a delayed pre-reset request from replaying after reset. Reset initiation aborts the old AXIS transaction; reset busy blocks new scheduling until source retirement/completion and a new enable/capture/commit sequence complete. A new request must toggle away from the aligned acknowledgement phase. Epoch equality prevents an old-reset token from being accepted. Product `source_reset` and standalone reset inputs are tied low; source-readiness loss is not treated as an epoch reset. These safety properties assume both clocks eventually run, supported FPGA configuration initialization, and no arbitrarily retained or corrupted internal token surviving a generation or epoch wrap.

## Model classification

- Control crossing: one bidirectional request/acknowledgement toggle handshake, with one two-stage synchronizer in each direction.
- Data crossing: registered, held, bundled stable data; not 58 independent synchronizers.
- Coherency mechanism: common launch, common absolute settle-before-use deadline, and hold through acknowledgement.
- Required physical property: absolute maximum settling delay to all payload-dependent source-domain state cones.
- Not required by function: a 3.000 ns relative arrival spread across heterogeneous downstream cones.
