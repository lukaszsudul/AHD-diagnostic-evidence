# G2B-BS2 CDC Semantic Review

## Classification

The ownership crossing is an **acknowledged stable-data mailbox using toggle/ack, with combinational aggregation after synchronized control**.

It is not Gray-coded, not a direct 58-bit synchronized capture, and not 58 independent synchronized controls.

## Mechanism

The source build is identified by:

- RTL: `C:\FPGA\V41_G2B\rtl\g2b\v41_g2b_onech_c2h.sv`, SHA-256 `8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471`
- XDC: `C:\FPGA\V41_G2B\xdc\common\g2b_cdc.xdc`, SHA-256 `2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF`

Those hashes match the sealed Gen12 build-input manifest.

The architecture is:

1. On one `userclk1` edge, the scheduler loads slot, generation, and epoch and toggles `own_req_toggle_axi`.
2. `own_req_toggle_axi` crosses into `nvp_vclk1` through `own_req_sync1_source` and `own_req_sync2_source`, both marked `ASYNC_REG`.
3. On observing a new synchronized request, source logic selects the slot and compares state, generation, descriptor epoch, and reset epoch.
4. Source logic registers `own_ok_hold_source`, updates state/fatal effects, records the request phase, and returns the acknowledgement toggle.
5. The acknowledgement crosses back through `own_ack_sync1_axi` and `own_ack_sync2_axi`.
6. AXI consumes the held result only after the acknowledged phase matches.

The payload-hold signals have no intervening assignment before the later transaction. The transaction protocol, not direct parallel sampling, supplies coherency.

## Safety-property classification

The functional requirement is category **D: another invariant**:

> The slot/generation/epoch payload must be launched with the request, remain stable through acknowledgement, and settle through each payload-dependent decision cone before the synchronized request is consumed.

Consequences:

- **A — absolute arrival skew of all 58 signals:** not the primary invariant. A 3 ns spread at one reconvergent Boolean D pin does not prove payload stability or request ordering.
- **B — per-family bounded delay:** useful physical evidence. Slot selection, generation comparison, and epoch comparison can be bounded separately or under one justified absolute settling limit.
- **C — synchronizer/handshake correctness only:** necessary but not sufficient if implementation delay could exceed the minimum request-observation window.
- **D — stable-data ordering plus an absolute settling bound:** the best match to the implemented protocol.

## Relation to the 6.000 ns max-delay constraint

The source XDC already applies a broad 6.000 ns `set_max_delay -datapath_only` from AXI mailbox payload registers to source-domain mailbox destinations. The exact worst `S_FULL` to `K_OWNERSHIP_RESULT` path is 4.868 ns, leaving +1.162 ns slack under that constraint.

This is relevant because max delay constrains the absolute time for data to propagate. It is still not automatically equivalent to a 3.000 ns bus-skew constraint, which constrains relative path-arrival spread. The 6.000 ns number must be justified against the minimum synchronized-request observation window and implementation margin; its mere presence is not a structural proof.

## Structural proof obligations

An ownership-mailbox sign-off should establish all of the following:

1. slot, generation, epoch, and request are launched by the same transaction event;
2. the payload cannot change until the corresponding acknowledgement returns;
3. request and acknowledgement each cross through the intended two-stage synchronizers;
4. the destination decision is enabled only by the synchronized request phase;
5. every payload-dependent destination family is included in a justified absolute settling constraint;
6. no asynchronous combinational control bypasses the synchronized request;
7. reset behavior cannot release or reinterpret a partially completed ownership transaction.

BS2 confirms the relevant routed clocks and worst absolute path, but it is a diagnostic timing-methodology gate, not a formal proof of every RTL temporal obligation.

## Redesign decision

No evidence shows that the architecture depends on unsafe simultaneous capture of an unsynchronized 58-bit bus. Redesigning the CDC is therefore not recommended by BS2. A redesign would be warranted only if a later structural proof finds that payload stability, request ordering, or reset behavior is not guaranteed.

