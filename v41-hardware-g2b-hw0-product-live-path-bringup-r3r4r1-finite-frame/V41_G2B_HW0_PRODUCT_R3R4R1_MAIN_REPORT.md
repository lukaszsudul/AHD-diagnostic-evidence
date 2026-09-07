# AHD v41 G2B-HW0-PRODUCT-R3R4R1

## Outcome

- Engineering gate: `BLOCKED`
- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `R3R4R1_CAPTURE_TOOL_HARD_GATE_FAILED`
- Failed case: `PARENT_QUIESCENCE_HANDSHAKE_PASS`
- Hardware accessed: `NO`

## Exact stopped gate

The fresh run removed the invalid `part_count > len(records)` assertion and
the corrected partial-read case passed all required semantic checks. Cases 1
through 4 passed. The suite then failed case 5 because the coded expected
quiet-window completions were
`[false,false,false,false,false,false,true]`, while the unchanged runtime
function produced `[false,false,false,false,false,true,true]`.

At t=2.8 seconds, 1.4 seconds had elapsed since the last data event at t=1.4,
so the frozen 1.0-second quiet-window function correctly reported completion.
The test expectation at that position was invalid. Per the directive, the
self-test and capture tool were not patched after this failure, the suite was
not rerun, and no DUT connection occurred.

## Preserved boundaries

PROJECT_STATE_REV remained 8. R3R3 commit `6cff7ad374575df84bc7d8794565dbd7d9cd869f` (98 manifest
entries) and failed R3R4 commit `2bfcba2476a31a06bdf940881cd5d0a20614333e` (40 entries) verified
byte-for-byte. The PRODUCT source, bitstream, DCP, driver authority, and ABI
matched their frozen identities. The immutable before/after snapshot covered
20 roots and 8,680 files with zero new, removed, or changed protected files.

No controller/Linux lock, SSH connection, JTAG, PCIe inventory, driver load,
bind, MMIO, DMA, stream operation, FPGA programming, reboot, power-cycle,
Flash operation, NVP access, or camera operation occurred. No raw camera or
synthetic raw-record files are published.

## Exact corrective action

Use a new governed run root. Correct only the case-5 expected quiet-window
timeline so it agrees with the frozen function, then require all 11/11 cases
before any DUT connection. Do not reinterpret this result as hardware proof.
