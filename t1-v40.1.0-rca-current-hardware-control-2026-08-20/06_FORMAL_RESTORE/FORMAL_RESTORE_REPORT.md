# Formal restore disposition

RC-A was never programmed, so a restoration image transition and warm reboot
were neither required nor permitted after the SSH-gate hard stop.

```text
RC_A_PROGRAM_INVOCATIONS=0
FORMAL_RESTORE_PROGRAM_INVOCATIONS=0
FORMAL_RESTORE_EOS=NOT_RUN
FORMAL_RESTORE_DONE=NOT_RUN
FORMAL_RESTORE_WARM_REBOOT=NOT_RUN
FORMAL_PHASE2_ACTIVE_AT_END=AUTHORITATIVE_START_PRESERVED_BY_ZERO_MUTATION_NOT_FRESHLY_VERIFIED
```
