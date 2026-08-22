# Informational future measurement-gap note

No future build or hardware action was run or authorized by this task.

If the owner later authorizes a clean counter-instrumented A/B experiment, the
least-confounded concept is:

- Arm A: derive from historical R1 source commit
  `0af44dee3bc091eaff805704dd5c687eeaa01bbd`, retain the R1 lifecycle-counter
  instrumentation, and change only the top-level `I2C_HZ` connection from
  50,000 to 25,000.
- Arm B: reuse the exact existing R1 50-kHz lifecycle-counter bit, SHA-256
  `4C169486BCEA09F0C76213C88CF675317C8F30C4DD887EDC4B8989D8E72EF5DB`.

An ordered host-visible NACK log would additionally be needed to assign a
measured net count deficit to individual path-changing NACK events when the
FSM cost decomposition is not unique.

```text
FUTURE_COUNTER_INSTRUMENTED_25KHZ_BUILD=NOT_RUN
FUTURE_HARDWARE=NOT_RUN
```

