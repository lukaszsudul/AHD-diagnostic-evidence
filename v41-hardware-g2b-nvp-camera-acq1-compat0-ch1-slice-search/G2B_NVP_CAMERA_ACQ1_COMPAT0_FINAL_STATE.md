# Final state

- Engineering gate: `BLOCKED`
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `ACQ1_COMPAT0_SLICE_ACTION_EXCEEDS_AUTHORIZED_WRITE_SET`
- Compatibility class: `NVP6134_REFERENCE_ONLY_CONTROLLED_COMPATIBILITY_TEST`
- Touched functional registers in complete reference action: `2`
- Authorized functional registers: `1`
- Source branch/worktree created: `NO`
- Source changed: `NO`
- Build/bitstream/hardware/camera campaign: `NOT_REACHED`
- Functional NVP writes: `0`
- NVP persistent state changed: `NO`
- PRODUCT/SSOT/META changed: `NO`
- Final FPGA runtime profile: `PREVIOUS_PROFILE_UNCHANGED`

Required Owner decision for a future task: explicitly authorize or reject the inseparable `Bank5/0x05=0xA4` companion write and define complete double-read/readback/rollback authority for both private functional registers. The current task must not continue under an enlarged interpretation.
