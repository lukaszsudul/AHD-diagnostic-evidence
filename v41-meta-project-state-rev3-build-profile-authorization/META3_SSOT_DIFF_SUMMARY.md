# AHD v41 META-3 SSOT Diff Summary

## Transaction

`PROJECT_STATE_REV: 2 -> 3`

Reason: G2B-LUT0 was accepted and reversible PRODUCT / RESEARCH_DIAGNOSTIC
build-profile architecture was authorized to recover resource headroom.

Evidence: `v41-development-g2b-lut0-resource-attribution` at
`a70c55eca5f0c0ad349143ad93ab87eb80d11ac4`.

## Semantic changes

| Area | Revision 2 | Revision 3 |
|---|---|---|
| G2B-LUT0 | evidence only | `ACCEPTED` resource architecture |
| G2B-IMPL | contract-ready / not implemented | `BLOCKED_RESOURCE_HEADROOM`; not offline-qualified |
| G2B-LUT1 | absent | `READY` to implement reversible profiles |
| PRODUCT profile | absent | `AUTHORIZED_NOT_IMPLEMENTED` |
| RESEARCH_DIAGNOSTIC profile | absent | `AUTHORIZED_NOT_IMPLEMENTED` |
| R-track | active execution | `HOLD`, valid and resumable, not closed |
| PRODUCT LUT gate | generic development policy | explicit routed hard gate `<=90%` |
| Preferred PRODUCT LUT | `<=85%` development preference | explicit `80–85%` target band |
| Estimated PRODUCT result | absent | 17,512 LUT / 84.192%, estimate only |
| Transport ABI | frozen V1 | unchanged |
| G2B MMIO | frozen `0x3800..0x3BFF` | unchanged |
| G2B hardware | `NOT_PROVEN` | `NOT_PROVEN` |
| V4L2 | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` |

## Changed SSOT files

| File | Change class |
|---|---|
| `ACTIVE_BASELINES.md` | revision pointer, accepted LUT0/profile architecture, held research context |
| `CHANGELOG.md` | append immutable revision-3 entry |
| `COMPATIBILITY_MATRIX.csv` | profile/R1i/ABI/MMIO/hardware compatibility rows |
| `CURRENT_ARCHITECTURE.md` | dual-profile boundary and invariants |
| `CURRENT_INTERFACES.md` | profile selection cannot alter external semantics |
| `CURRENT_REQUIREMENTS.md` | PRODUCT LUT and profile requirements |
| `CURRENT_RESOURCE_STATE.md` | blocked result, estimates, target-vs-proof boundary |
| `CURRENT_STATUS.md` | G2B/R-track/profile current summary |
| `CURRENT_TRACKS.md` | LUT0 acceptance, LUT1 readiness, R-track HOLD |
| `EVIDENCE_MAP.md` | immutable G2B-LUT0 provenance and statements |
| `GOVERNANCE.md` | factual governed-revision pointer only |
| `OPEN_DECISIONS.md` | resource architecture decided; actual LUT/timing/hardware/R2-R3 stay open |
| `PROJECT_STATE.json` | revision-3 machine state |
| `README.md` | revision/current snapshot |
| `SHA256_MANIFEST.txt` | recomputed integrity inventory |
| `TRACK_STATUS.json` | exact gate and track state |

No bytes under `FPGA_AHD`, no FPGA source/RTL/XCI/XDC, no R-track source
branch, and no research evidence are part of this diff.
