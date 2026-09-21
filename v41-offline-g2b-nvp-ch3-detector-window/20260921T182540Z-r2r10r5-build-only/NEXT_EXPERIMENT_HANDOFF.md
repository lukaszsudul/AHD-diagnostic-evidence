# Sanitized next-experiment boundary

The exact image is an experimental, untested build. It introduces a bounded
dynamic detector-readiness window while preserving transport failures as hard
errors. A budget-exhaustion result is distinct from NACK and does not prove a
bad profile.

Build success does not establish APPLY success, camera synchronization, frame
availability or the physical cause of any historical failure. The historical
terminal-18 NACK with unknown instruction context and the later localized F0
readback failure remain separate observations. The new physical
implementation is also a changed variable.

Current host visibility does not retain a full history of detector samples.
The existing status provides only latest fields, and the existing sticky
record provides the first hard-failure context. Sample count, complete sample
history and individual boundary reads are not exposed or retained.

Any future activation, PREPARE, single APPLY, record readback, scan or capture
requires a separate Owner authorization. A future host must retain a finite
deadline that includes configuration, the bounded observation window, later
checks and possible recovery, and must recognize the new budget-exhaustion
terminal separately from transport errors.

```text
BUILD_RESULT=BITSTREAM_GENERATED_UNTESTED
FUTURE_APPLY_RESULT=NOT_RUN
WINDOW_SAMPLE_HISTORY=NOT_EXPOSED_NOT_RETAINED
HISTORICAL_REGADDR_NACK_ROOT_CAUSE=NOT_PROVEN
CAPTURE_ADMISSION=NOT_GRANTED
NEXT_HARDWARE_EXPERIMENT=SEPARATE_OWNER_AUTHORIZATION_REQUIRED
```
