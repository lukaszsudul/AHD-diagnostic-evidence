# AHD v41 G2B-IMPL R1i Protection Audit

## Result

`R1I_PROTECTED_BEHAVIOR = PASS`

No functional change to qualified R1i behavior was required or made. The G2B
source tap is additive and the accepted NVP/I2C/legacy capture behavior remains
independent of transport reset.

## Static diff boundary

The comparison base is the exact accepted G2A commit
`224d194e5f82c85bcb29297561c5d5e76d28063b`. The protected-source manifest was
byte-identical for 30 of 32 entries. The only differing protected-boundary files
were the two explicitly reviewed integration points:

| File | Diff | Protection disposition |
|---|---:|---|
| `rtl/top/ahd_capture_top_xdma.sv` | +90 / -15 | G2B instance, frozen MMIO router, and accepted source/AXI wiring only; no NVP/I2C state-machine edit |
| `rtl/video/physical_frontend.sv` | +5 / -1 | additive `frontend_released` output exposing the existing registered ingress-release state |

The following protected functions/files remained byte-identical to G2A:

- NVP autoinit and bring-up sequence;
- I2C master and R1i transaction serial behavior;
- SCL/ACK timing and readiness logic;
- existing NVP timing constraints;
- R1i diagnostic identity and failed-transaction logging;
- legacy control/status MMIO and host bridge;
- accepted BT.656 record producer, capture mailbox, BAR target, and capture
  subsystem outside the necessary observation tap;
- accepted XDMA XCI and configuration helper.

The exact XDMA XCI SHA-256 remained
`9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F`.

## Authoritative focused simulation

The existing R1i focused suite was run against an immutable accepted reference
and the G2B candidate in
`C:\FPGA\G2B_R1I_PROTECTION_20260829_B`.

| Check | Reference | Candidate | Result |
|---|---:|---:|---|
| Complete transactions | 275 | 275 | PASS |
| Bytes transferred | 825 | 825 | PASS |
| Reference/candidate cycles | 651,929 | 710,495 | expected harness-mode difference |
| CASE1..CASE12 | PASS | PASS | PASS |
| Persistent SCL-low behavior | PASS | PASS | PASS |
| Wire trace equality | byte-identical | byte-identical | PASS |

The authoritative trace SHA-256 for both sides is
`7C5D7F767B2E9CAEB1B587D3F258C295AD0F454141B2A8C84240B966133A4B49`.
The terminal marker was `PASS R1I_FOCUSED_WIRE_SEMANTIC_SUITE`; both runs
reported `PASS ALL_ACK_WIRE_SEQUENCE_AND_OUTPUT_CAPTURE` with 275 transactions
and 825 bytes. The cycle counts differ because the accepted reference and
candidate harness modes have different initialization envelopes; the complete
wire/transaction traces are identical.

## Reset and independence audit

Transport epoch/reset logic does not reset or replay the NVP/I2C initialization
state. Source readiness loss and explicit source reset do not create a
transport epoch. Conversely, transport reset retires only G2B ring/stream,
sequence, error, and counter state. The product top does not map NVP reset onto
the standalone formatter-reset input.

Legacy MMIO outside `0x3800..0x3BFF` remains on the original path; exhaustive
router simulation separately checked every 17-bit address and all response
scenarios. This protects legacy byte and response timing behavior rather than
merely comparing address constants.

## Disposition

The protected diff, exact wire-sequence comparison, all focused cases, and
reset-independence audit pass. There is no
`R1I_PROTECTED_BEHAVIOR_CHANGE_REQUIRED` blocker. This protection PASS does not
override the separate post-opt LUT resource blocker and does not constitute
hardware proof.
