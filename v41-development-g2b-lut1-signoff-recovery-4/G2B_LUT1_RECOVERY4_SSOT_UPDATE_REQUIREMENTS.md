# Separate META update requirements

SSOT is unchanged at revision 7. This engineering task does not promote project state or authorize hardware access.

Only if the final recovery-4 evidence reports engineering PASS, normal source publication PASS, evidence publication PASS and remote read-back PASS, a separate authorized META task may promote the exact candidate:

- PRODUCT profile: OFFLINE_QUALIFIED.
- G2B implementation: OFFLINE_QUALIFIED.
- Product candidate: READY_FOR_G2B_HW0.
- G2B hardware: NOT_PROVEN.
- Next hardware gate: G2B-HW0 SYNTHETIC DMA BRING-UP, beginning with runtime identity and one deterministic 4096-byte record.

Bind the exact source commit, active XDC hash, signed-off DCP, bitstream hash, evidence commit and current candidate identity. Carry forward the reviewed CDC representative changes, per-warning dispositions, embedded Gen12 runtime fingerprint and lack of hardware throughput proof. No warning is globally waived, and no hardware qualification is implied.

If any final gate or publication is blocked, do not promote the candidate; use the final report's exact continuation point while preserving completed gates.
