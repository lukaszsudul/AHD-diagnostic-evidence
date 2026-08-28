# AHD v41 G2B Pre-Implementation Blocker

## Disposition

`BLOCKED — G2B_RECORD_ABI_NOT_FROZEN`

This is the first blocker. No C2H RTL, MMIO RTL, testbench, build harness, XCI, protected R1i source, or host/driver source was changed after it was identified.

## Record ABI gaps

G1 freezes the nominal geometry and field locations, but not every mandatory semantic needed for interoperable RTL and a self-checking parser:

1. Offset `0x38` is the per-channel attempt sequence, but G1 does not freeze its initial/reset value, wrap assignment, or whether the stored value is assigned before or after the attempt increment.
2. Offset `0x3C` is the global streamed sequence. The scheduler text says it increments on completion, although the value must be presented in the header before that record completes. The first emitted value is therefore ambiguous.
3. The one-channel contract says the first post-reset record carries a reset epoch in “MMIO/header context,” while the complete 64-byte v41D table has no reset-epoch field.
4. Offset `0x08` is named Firmware/build ID without a frozen G2B value or inheritance rule.

These are not implementation details: different reasonable choices generate different transport bytes and reset/wrap behavior. The task explicitly forbids inventing a mandatory record field or silently deciding ABI.

## MMIO blocker

`BLOCKED — MMIO_ALLOCATION_NOT_FROZEN`

`V41_G1_MMIO_MAP_PLAN.md` labels all new addresses `PROPOSED_FOR_G2`, conditional on later review. More importantly, mandatory registers such as capabilities, global control/state, channel control/state, scheduler state, and error/reject causes do not have frozen bit encodings. Revision-1 SSOT independently classifies the proposed pages as `PROVISIONAL` and requires an accepted final register contract.

Decode-collision review alone cannot choose those bit fields. Nothing in the task explicitly accepts an exact final MMIO ABI.

## Exact authority required to unblock

Owner/Architect should issue an interface decision that freezes:

- initial, reset, wrap, and assignment timing for both sequence fields;
- how reset epoch is represented (specific header field or MMIO-only rule);
- the G2B firmware/build ID value or inheritance rule;
- exact bit definitions and reset/write semantics for every implemented `0x3800..0x3BFF` register; and
- whether that decision supersedes SSOT revision-1 `PROVISIONAL`/`OD-06 OPEN` state, followed by the required META interface update.

After that decision, G2B should restart from the unchanged isolated branch at the accepted G2A base.
