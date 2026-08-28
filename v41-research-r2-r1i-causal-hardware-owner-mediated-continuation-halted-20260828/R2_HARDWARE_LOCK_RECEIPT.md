# R2 Hardware Authority Receipt

The filename is retained for compatibility with the original R2 evidence contract. No software hardware lock was created or used in this continuation.

## Authority result

- Hardware authority: `PASS`
- Hardware authority mechanism: `OWNER_CHAT_DECLARATION`
- DUT exclusivity: `PASS`
- Software `FPGA_AHD_HW_LOCK` required: `NO`
- Software `FPGA_AHD_HW_LOCK` created: `NO`
- Task: `AHD v41 R2 Hardware Causal Experiment — Owner-Mediated Continuation`
- Confirmation captured UTC: `2026-08-28T10:08:52.027Z`
- Source authority receipt SHA-256: `2DEC89DBC82EBE4361288BBC1557766C2225162BD86C63ADA56F38A5B06BE002`

## Exact Owner declaration

> I confirm you have exclusive access to the AHD DUT for this R2 hardware campaign and that no other agent, G-track task, R-track task, HDMI task, user action, or external process will program, reset, power-cycle, or otherwise modify the DUT until I explicitly release it

The chat platform did not expose an independent message timestamp. The receipt uses the first system-clock capture immediately after the affirmative response.

## Continuity

The declaration remained valid unless revoked, explicitly released, or contradicted by an unexplained programming/reset/power/state event. No such continuity-loss event appears in the sealed campaign record. All recorded host reboots, FPGA programs, and restores were task-owned steps.

## Release status

`DUT_EXCLUSIVITY_RELEASED=YES`

After exact Formal restoration, final live read-only verification, initial evidence publication, and initial remote read-back, the agent declared in chat:

> R2 hardware operations are complete. DUT exclusivity is released.

First system-clock capture after that declaration: `2026-08-28T18:49:33.6866517Z`.
