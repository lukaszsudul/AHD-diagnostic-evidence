
# Guard and cancel contract

- shutdown guard records: 128
- shutdown guard bytes: 524288
- guard request geometry: one 4096-byte IOCB per logical request
- guard submission begins only after all primary logical requests are submitted
- guard records are excluded from primary qualification
- primary persistence begins after `DISABLE_ISSUED` and is independent of guard
  completion
- cancellation begins only after `PARENT_QUIESCENT`
- cancellation targets only pending guard IOCBs on the normal path
- each pending guard IOCB receives at most one `io_cancel`
- accepted states: `COMPLETED_EXACT_4096`,
  `CANCELED_AFTER_PARENT_QUIESCENCE`
- positive short, duplicate/wrong identity, or final pending request: failure
- completed primary data is preserved before any guard-cleanup failure report

Deterministic native and parent fixtures: `PASS`.
