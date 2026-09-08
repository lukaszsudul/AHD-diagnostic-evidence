# Primary and shutdown-window classification

- Rolling descriptor window: PASS
- Primary AIO capture: PASS
- Primary record integrity: PASS
- Primary stream continuity: FAIL
- Primary global sequence: 0..2499
- Primary global gaps: 0
- Primary overflow records: [441]
- BT.656 source qualification: OPEN_RECURRING_BT656_QUALIFICATION_EVENT
- Post-target shutdown tail: UNRESOLVED

The primary window is not classified clean because an OVERFLOW_OCCURRED flag is
already present at primary record 441. Later SP drop/overflow evidence therefore
cannot be used to retroactively relabel the entire failure as guard-only.
