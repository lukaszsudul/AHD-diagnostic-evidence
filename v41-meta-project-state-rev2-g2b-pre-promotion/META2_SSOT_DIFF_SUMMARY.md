# AHD v41 META-2 SSOT Diff Summary

## Transaction

`PROJECT_STATE_REV: 1 -> 2`

Reason: G2B-PRE was accepted; the named C2H transport ABI, G2B MMIO contract,
and transport-facing Linux consumer input contract are frozen for later G2B
implementation.

Evidence: `v41-development-g2b-pre-c2h-abi-mmio-freeze` at
`e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e`.

## Semantic changes

| Area | Revision 1 | Revision 2 |
|---|---|---|
| G2B-PRE | not represented | `ACCEPTED`, contract-freeze scope |
| Transport ABI | `PROVISIONAL` | lifecycle `FROZEN`; semantic `FROZEN_FOR_G2B` |
| ABI identity | provisional v41D plan | `AHD_C2H_TRANSPORT_ABI_V1`, version 1 |
| Geometry | planned 4096/~3840 | exact `64 + 3840 + 192 = 4096` |
| Header sequences | encoding provisional | exact 16-word map with epoch/attempt/global semantics |
| MMIO | provisional G2 proposal through `0x3FFF` | frozen `0x3800..0x3BFF`; `0x3C00..0x3FFF` not claimed |
| Linux consumer | future transport/V4L2 topics | frozen transport input/parser contract; V4L2 still not implemented |
| `OD-06` | `OPEN` | closed by accepted G2B-PRE |
| G2B implementation | `PLANNED` | contract readiness `READY`; still `NOT_IMPLEMENTED` |
| G2B hardware | not qualified | qualification `NOT_STARTED` / `NOT_PROVEN` |

## Changed SSOT files

| File | Change class |
|---|---|
| `ACTIVE_BASELINES.md` | live revision pointer only |
| `CHANGELOG.md` | append immutable revision-2 entry |
| `COMPATIBILITY_MATRIX.csv` | ABI/MMIO/G2B-PRE/future-implementation/Linux compatibility rows |
| `CURRENT_ARCHITECTURE.md` | frozen contract and non-implementation boundary |
| `CURRENT_INTERFACES.md` | normative ABI/MMIO/Linux transport input contract |
| `CURRENT_REQUIREMENTS.md` | frozen record/parser/ownership/drop requirements |
| `CURRENT_RESOURCE_STATE.md` | live revision pointer only |
| `CURRENT_STATUS.md` | current gate/ABI/MMIO/implementation summary |
| `CURRENT_TRACKS.md` | G2B-PRE acceptance and G2B contract readiness |
| `EVIDENCE_MAP.md` | immutable G2B-PRE provenance and statements |
| `GOVERNANCE.md` | factual governed-revision pointer only |
| `OPEN_DECISIONS.md` | OD-06 closure and technical closure receipt |
| `PROJECT_STATE.json` | revision-2 machine state and evidence reference |
| `README.md` | revision/current snapshot |
| `SHA256_MANIFEST.txt` | recomputed integrity inventory |
| `TRACK_STATUS.json` | revision, G2B-PRE, readiness, and qualification boundary |

No bytes under `FPGA_AHD`, no FPGA source/RTL/XCI/XDC, and no R-track state
are part of this diff.
