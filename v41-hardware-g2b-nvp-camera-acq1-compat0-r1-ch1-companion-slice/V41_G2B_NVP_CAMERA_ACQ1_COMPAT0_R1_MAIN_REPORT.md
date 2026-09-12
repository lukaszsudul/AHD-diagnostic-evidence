# AHD v41 G2B-NVP-CAMERA-ACQ1-COMPAT0-R1 main report

## Result

- Engineering gate: `BLOCKED`
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `ACQ1_COMPAT0_R1_REFERENCE_SEQUENCE_AUTHORITY_CONTRADICTION`

## First failed gate

The accepted source parent, pinned reference repository, and prior SCAN0/SCAN1/ACQ0 evidence identities all passed. Exact semantic extraction then proved that the dynamic reference NOVID branch writes the selected `Bank5/0x08` level before it writes `Bank5/0x05=0xA4`. The R1 atomic forward action and required final literal instead mandate `Bank5/0x05=0xA4` before `Bank5/0x08`.

No implementation can satisfy both mandatory orders. Choosing the source order would violate R1 section 7.3 and its required final literal; choosing the R1 order would differ from the frozen pinned source and trigger the explicit fail-on-forward-order rule. The task therefore stopped before touched-register closure, source editing, tests, build, bitstream, or hardware.

## Non-claims and preserved state

The new local branch/worktree remains clean at the accepted parent. No source commit was created or pushed. No DUT root, lock, programming, autoinit run, reboot, driver load, MMIO access, NVP read/write, camera gate, capture, rollback, or hardware cleanup occurred. Functional writes are `0`; PRODUCT, SSOT, and META are unchanged; the previous volatile FPGA profile is unchanged.

## Required decision

Issue a corrected governed contract with one unambiguous forward sequence. The correction must either follow the pinned dynamic source order (`0x08 level` then `0x05=A4`) or explicitly classify the reversed order as a distinct Owner-designed experiment rather than the exact reference NOVID sequence.
