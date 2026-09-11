# AHD v41 G2B-NVP-CAMERA-ACQ1-COMPAT0 main report

## Result

- Engineering gate: `BLOCKED`
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `ACQ1_COMPAT0_SLICE_ACTION_EXCEEDS_AUTHORIZED_WRITE_SET`

## Authority result

The accepted SCAN1 evidence activates the conditional compatibility authorization. The frozen reference identity and SCAN0 semantic artifacts were verified without fetching a moving branch. Their clean-room trace shows that the NOVID slice branch does not consist solely of the three `Bank5/0x08` values: it also unconditionally writes `Bank5/0x05=0xA4` on every no-video execution. The current Owner authorization covers only functional data writes to `Bank5/0x08`.

Section 4 of the task states that if another functional write is inseparable, execution must stop as `ACQ1_COMPAT0_SLICE_ACTION_EXCEEDS_AUTHORIZED_WRITE_SET` and the authorization must not be enlarged automatically. That exact condition is present. The compatibility classification remains `NVP6134_REFERENCE_ONLY_CONTROLLED_COMPATIBILITY_TEST`; the lack of public private-register semantics is not itself the blocker.

## Stop boundary and non-claims

No diagnostic source branch/worktree, executor, runtime bundle, build, DCP, bitstream, DUT run root, connection helper, lock, programming, reboot, driver, MMIO access, NVP read/write, physical camera gate, or capture was performed. Functional NVP writes are `0`. PRODUCT, transport, SCAN1, XDC, SSOT, and META remain unchanged. The prior FPGA runtime profile remains unchanged.

## Required decision

A future governed task requires an explicit Owner decision on whether to authorize the inseparable `Bank5/0x05=0xA4` companion write. If authorized, it must add complete read-safety, double-read baseline, exact readback, runtime-derived rollback, and post-rollback verification authority for both `Bank5/0x05` and `Bank5/0x08` before implementation or hardware access.
