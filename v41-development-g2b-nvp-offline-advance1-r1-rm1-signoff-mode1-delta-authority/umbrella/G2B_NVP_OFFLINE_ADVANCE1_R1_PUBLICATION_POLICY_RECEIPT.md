# OFFLINE-ADVANCE1-R1 publication-policy receipt

Result: `PASS`.

- Publication scope: only `v41-development-g2b-nvp-offline-advance1-r1-rm1-signoff-mode1-delta-authority/`.
- Public subdirectories: `rm1-r1/`, `mode1-auth1/`, `camera-carry-forward/`, `continuation-prompts/`, `umbrella/`.
- Included: hashes, receipts, reports, task-local harness, clean-room RM1 source/tests/XDC, and independent semantic MODE1 ledgers/tests.
- Excluded: vendor source, vendor PDFs, private KiCad files, proprietary schematics, bitstreams, DCPs, drivers, credentials, camera images and raw video.
- Prohibited binary extension scan: `0 findings`.
- Credential/private-key marker scan: `0 findings` (the policy word `credentials` in the continuation prompt is not a credential).
- JSON parse validation: `PASS`.
- CSV parse validation: `PASS`.
- SHA-256 manifest validation: `PASS`.
- DUT/hardware access: `NO`.
