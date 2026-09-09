# Bounded vertical-tail policy

- LAST_ACTIVE_LINE = 1079
- FIRST_VERTICAL_TAIL_LINE = 1080
- LAST_BENIGN_VERTICAL_TAIL_LINE = 1100
- MAX_BENIGN_VERTICAL_TAIL_LINES = 21

Active lines 0..1079 retain normal record behavior. A complete, parity-valid
V-low line-shaped interval 1080..1100 advances only the source-local capture
sequence once, creates no transport attempt, allocation, record, drop,
overflow, or malformed increment, preserves lock, and returns to SRC_IDLE. A
complete interval beyond 1100 is classified exactly once as an unexpected
format/boundary event, follows the existing bounded malformed behavior, and
never creates an active record. NVP configuration is unchanged.
