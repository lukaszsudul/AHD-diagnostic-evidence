# CONT1R3R2 evidence index

This append-only package documents offline requalification of one *unchanged* existing routed DCP. The prior FAIL and do-not-program records remain historical and unmodified. `DCP_CLOSURE_RECEIPT.md` becomes effective only after this package is pushed and its files are read back at the actual remote commit SHA.

| File/group | Purpose |
| --- | --- |
| `V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R2_MAIN_REPORT.md`, `DCP_CLOSURE_RECEIPT.md`, `STATE.json` | Decision, limits and exact checkpoint identity. |
| `AUTHORITY_AND_INPUTS.json`, `HASH_FLOW.csv`, `A_B_DIFFERENCE_FINDINGS.md` | Frozen source/tool/DCP authority and historical A/B producer-consumer chain. |
| `COMPARISON_CONTRACT.md`, `COMPARISON_CONTRACT_ADDENDUM.md`, `REPORT_COMPARISON.csv`, `PHYSICAL_IDENTITY_FINDINGS.md` | Frozen comparison rules, raw/body report dispositions and physical identity summary. |
| `HARNESS_PATCH_AND_TESTS.md`, `HARNESS_BEHAVIORAL_DIFF.md`, `host-source/` | Readable before/after behavior, task-local project-owned comparator/collector, focused regression tests and artifact validator. |
| `NEXT_FIRST_FRAME_HANDOFF.md` | One-page next-step governance and genuine-frame target. |
| `SHA256_MANIFEST.txt` | Sorted relative path, size and SHA-256 of intended public files, excluding the manifest itself and this index to avoid self-reference. |

Private raw A/B XDC exports, complete route-property files, full report pairs, DCPs, Vivado logs and old scripts remain in task/prior roots with their source paths and hashes recorded by the published summaries. No bitstream, driver, credential, vendor source/PDF, camera pixel or raw video is in this package. The public package itself is not a replacement FPGA source tree or a newly generated checkpoint.
