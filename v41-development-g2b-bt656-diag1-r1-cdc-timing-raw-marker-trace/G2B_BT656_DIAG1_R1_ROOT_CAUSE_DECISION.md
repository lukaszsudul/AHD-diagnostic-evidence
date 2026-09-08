# G2B BT.656 DIAG1-R1 Root-Cause Decision

Decision: `ROOT_CAUSE_PROVEN_VERTICAL_BLANKING_HANDLING`.

The physical trace identifies the exact initiating code predicate: 21 full-length, parity-valid V=0 lines after line 1079 reach `SRC_WAIT_EAV`, but are rejected because `pending_line <= 1079` is false. This produces 21 reason-2 malformed increments and causes the first lock loss. The next frame's line-0 SAV is physically present and parsed, while the now-low lock prevents admission. The replay is required to confirm the enabled-path omission and composed flags.

H1 lock admission is a proven contributing effect, not the sole root. H3 is disproven. H4 remains open as a frontend configuration explanation for why the physical source emits this vertical-boundary shape, but it is not needed to identify the parser condition that generates the observed malformed chain. H5 is not supported.

The run remains operationally BLOCKED by unresolved drain AIO cleanup. No correction worktree or candidate is created while the helper, module reference, nodes, and locks remain intentionally preserved.
