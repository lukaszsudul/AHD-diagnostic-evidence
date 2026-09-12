# Final state

- Engineering gate: `BLOCKED`
- Evidence publication: `PASS_ON_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `ACQ1_COMPAT0_R1_REFERENCE_SEQUENCE_AUTHORITY_CONTRADICTION`
- Source branch: `diag/v41-g2b-nvp-camera-acq1-compat0` locally at `c7e16fa3da26545cef960a6c75427a3614c4b655`
- Source file changes/commit/push: `0/NONE/NOT_RUN`
- Functional writes: `0`
- Hardware access: `NO`
- NVP persistent state changed: `NO`
- PRODUCT/SSOT/META changed: `NO`
- Final FPGA profile: `PREVIOUS_PROFILE_UNCHANGED`

Owner decision required: choose and issue one internally consistent governed forward order. Either authorize the pinned dynamic NOVID source order (`0x08 level` then `0x05=A4`) or explicitly define the reversed `0x05` then `0x08` experiment as a non-reference sequence and remove the conflicting exact-reference and fail-on-order requirements.
