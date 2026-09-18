# Gate summary

| Gate | Result | Evidence |
|---|---|---|
| Exact source and static profile/host checks | PASS_OFFLINE | Source commit and tree pinned; two reference PN variants prepared; offline host checks passed |
| Candidate 1 synthesis | COMPLETE_UNQUALIFIED | 23,426 post-synthesis Slice LUTs |
| Candidate 1 post-opt resource | **FAIL** | 21,828 Slice LUTs; strict ceiling 20,384; deficit 1,444 |
| Candidate 2 | NOT_BUILT | No evidence-backed one-revision correction capable of closing the measured deficit within scope |
| Placement, route, timing, DRC, CDC, bus-skew, signed reopen | NOT_REACHED | Stopped at first failed gate |
| Bitstream and DUT admission | NOT_REACHED | No qualified image |
| CH3 F0/NOVID, PN A/B, CH2 comparison | NOT_RUN | No DUT contact |
| CH3 output gate, C2H, frame and PNG | NOT_RUN | Conditional gates not reached |

The resource failure is an engineering FAIL. Publication is a separate evidence gate.
