# R2 Owner DUT Exclusivity Receipt

- Task context: `AHD v41 R2 Hardware Causal Experiment — Owner-Mediated Continuation`
- Authority: `OWNER_CHAT_DECLARATION`
- DUT exclusivity: `PASS`
- Declaration effective: Owner's affirmative response in this conversation
- Confirmation captured UTC: `2026-08-28T10:08:52.027Z`
- Confirmation captured local: `2026-08-28T12:08:52.109+02:00`
- Software lock required: `NO`

## Agent request

> Please confirm that I have exclusive access to the AHD DUT for this R2 hardware campaign and that no other agent, G-track task, R-track task, HDMI task, user action, or external process will program, reset, power-cycle, or otherwise modify the DUT until I explicitly release it.

The chat platform does not expose an independent message timestamp to the agent. The receipt records the first system-clock capture immediately after the affirmative response.

## Exact Owner response

> I confirm you have exclusive access to the AHD DUT for this R2 hardware campaign and that no other agent, G-track task, R-track task, HDMI task, user action, or external process will program, reset, power-cycle, or otherwise modify the DUT until I explicitly release it

## Continuity conditions

The declaration remains valid until Owner revocation, explicit R2 release, an unexplained DUT state change, or evidence of an external programming/reset/power event. Any such event requires an immediate stop and renewed Owner confirmation.
