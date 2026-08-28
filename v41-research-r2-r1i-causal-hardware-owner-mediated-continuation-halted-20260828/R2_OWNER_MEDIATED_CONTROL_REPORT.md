# R2 Owner-Mediated Control Report

## Authority substitution

For this continuation, the Owner prospectively replaced the unavailable technical/shared mutex requirement with `OWNER-MEDIATED DUT EXCLUSIVITY`. The frozen scientific design was not changed.

- Hardware authority: `PASS`
- Hardware authority mechanism: `OWNER_CHAT_DECLARATION`
- DUT exclusivity confirmation: `PASS`
- Owner confirmation capture UTC: `2026-08-28T10:08:52.027Z`
- authority receipt SHA-256: `2DEC89DBC82EBE4361288BBC1557766C2225162BD86C63ADA56F38A5B06BE002`
- software mutex required: `NO`
- software mutex created: `NO`

## Exclusivity continuity

The authority remained valid until revocation, release, or an unexplained DUT state change. The sealed record shows no unexplained external programming, reset, power event, PCIe identity change, or host reboot. All observed mutations and warm host transitions were task-owned and receipt-bound.

No G-track, G2B, HDMI, or other R-track hardware activity was started or interleaved.

## Manual cold-reset control

- control mechanism: `OWNER_MEDIATED_MANUAL_RESET`
- pre-existing Owner reset recognized: `YES`
- pre-existing Owner reset counted in formal denominator: `NO`
- formal reset requests issued: `0`
- formal reset confirmations received: `0`
- manual cold-reset receipts: `0`
- exact-C3 formal cold starts: `0/10`

The primary campaign used its frozen warm program/reboot recipe. It suspended at primary run 10 before the separate cold-start qualification and timing phases. No future Owner reset was batch-assumed, and no unconfirmed reset was counted.

## Campaign control response

At `R2OM-R03-P2-C3`, exact C3 produced a countable but non-clean frame-rate result. The frozen R0 C3 control rule required immediate suspension after safe restoration. The orchestrator:

1. preserved the run as `INCONCLUSIVE`;
2. authorized only the exact Formal safe restore;
3. restored Formal Phase-2;
4. independently verified DONE and runtime identity;
5. sealed the safe baseline;
6. halted before sequence 11.

Halt receipt SHA-256: `5939346939DBAA7B934662A4718095045BAE22CA3A341847032335E22B36062B`.

Final safe-baseline receipt SHA-256: `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF`.

## End-of-task release

Status: `DUT_EXCLUSIVITY_RELEASED=YES`.

After initial evidence publication and remote read-back completed at commit `2ddb3a6d7bebcc96235b0263b337916a7d70627d`, the executing agent told the Owner, “R2 hardware operations are complete. DUT exclusivity is released.” The first system-clock capture after that declaration was `2026-08-28T18:49:33.6866517Z`. No DUT operation occurred after release.
