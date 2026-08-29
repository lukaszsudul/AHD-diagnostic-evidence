# AHD v41 META-3 SSOT Consistency Report

## Result

`LOCAL_SSOT_CONSISTENCY = PASS`

`SSOT_CONSISTENCY = PENDING_REMOTE_READBACK`

This report is generated from the staged revision-3 transaction and is
finalized after non-force publication and exact remote read-back.

## Required invariant matrix

| Invariant | Expected | Local result |
|---|---|---|
| Project-state revision | `3` everywhere required | `PASS` |
| JSON parsing | both SSOT JSON documents valid | `PASS` |
| Lifecycle `status` values | normative enum only | `PASS` |
| G2B-LUT0 | `ACCEPTED` | `PASS` |
| R-track | `HOLD`, not closed/cancelled/superseded | `PASS` |
| PRODUCT | `AUTHORIZED_NOT_IMPLEMENTED` | `PASS` |
| RESEARCH_DIAGNOSTIC | `AUTHORIZED_NOT_IMPLEMENTED` | `PASS` |
| PRODUCT hard gate | routed LUT `<=90%` | `PASS` |
| Preferred PRODUCT target | `80–85%` | `PASS` |
| Target evidence boundary | 17,512 / 84.192% is estimate, not achievement | `PASS` |
| R1i functional equivalence | required across profiles | `PASS` |
| Research functional dependency | forbidden | `PASS` |
| Transport ABI | unchanged `AHD_C2H_TRANSPORT_ABI_V1` | `PASS` |
| G2B MMIO | unchanged `0x3800..0x3BFF` | `PASS` |
| G2B-IMPL | `BLOCKED_RESOURCE_HEADROOM`; not offline-qualified | `PASS` |
| G2B-LUT1 | `READY` | `PASS` |
| G2B hardware | `NOT_PROVEN` | `PASS` |
| G2B bitstream | no existence claim | `PASS` |
| V4L2 | `NOT_IMPLEMENTED`; no implementation claim | `PASS` |
| Actual LUT/timing/hardware | remain open | `PASS` |
| R2/R3 scientific closure | remains open | `PASS` |
| Research reversibility | RESEARCH_DIAGNOSTIC required; no evidence deletion | `PASS` |
| SSOT manifest | 18 non-manifest files, sorted, uppercase SHA-256 | `PASS` |
| Revision-2 changelog prefix | byte-identical | `PASS` |
| FPGA source repository | unchanged and clean at original HEAD/tree/content | `PASS` |
| Remote read-back | remote HEAD and affected hashes match | `PENDING` |

## Interface identity receipt

The revision-2 and revision-3 interface identities remain:

```text
TRANSPORT_ABI_NAME: AHD_C2H_TRANSPORT_ABI_V1
TRANSPORT_ABI_VERSION: 1
TRANSPORT_ABI_STATUS: FROZEN_FOR_G2B
G2B_MMIO_BASE: 0x3800
G2B_MMIO_END: 0x3BFF
FROZEN_ABI_CHANGED: NO
FROZEN_MMIO_CHANGED: NO
```

## Overclaim audit

Current-state statements distinguish requirements/estimates from results.
Historical changelog statements are retained verbatim and interpreted in
their original revision context.

```text
LUT_LE_90_ALREADY_ACHIEVED_CLAIM: NONE
G2B_BITSTREAM_EXISTS_CLAIM: NONE
G2B_HARDWARE_PROVEN_CLAIM: NONE
V4L2_IMPLEMENTED_CLAIM: NONE
R_TRACK_CLOSED_CLAIM: NONE
RESEARCH_EVIDENCE_DELETED: NO
```

## Validation receipt

```text
JSON_PARSE: PASS
LIFECYCLE_STATUS_ENUM: PASS
COMPATIBILITY_CSV: PASS
REVISION_MIRRORS: PASS
EVIDENCE_PATHS_AND_COMMIT: PASS
SSOT_MANIFEST_ENTRIES_VERIFIED: 18
GIT_DIFF_CHECK: PASS
LOCAL_RESULT: PASS
PUBLICATION_PAYLOAD_COMMIT: PENDING
PUSH_WITHOUT_FORCE: PENDING
REMOTE_FILES_CHECKED: 0
REMOTE_READBACK_FAILURES: 0
REMOTE_RESULT: PENDING
```
