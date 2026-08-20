# T1 campaign blocker and classification

```text
T1_RUN=NO
T1_VALID_RUNS=0
T1_PASS_COUNT=0
T1_FAIL_COUNT=0
T1_CLASSIFICATION=INCONCLUSIVE_INFRASTRUCTURE
INFRASTRUCTURE_CLASS=INVALID_INFRASTRUCTURE_SSH_AUTHENTICATION
RCA_PROGRAM_OPERATIONS=0
WARM_REBOOTS=0
FORMAL_RESTORE_PROGRAM_OPERATIONS=0
```

The exact RC-A artifact was found and sealed, and fresh read-only JTAG passed. However, the sealed host-key fingerprint matched while all non-interactive authentication paths available to this process failed: the two existing owner keys were rejected, and the cached PuTTY path required an interactive password. The owner-interaction prohibition prevented obtaining a password.

Starting RC-A programming would have made the required single warm reboot and formal restoration unverifiable and potentially impossible. Therefore no programming operation was invoked, no reboot occurred, and the authoritative formal Phase-2 configuration was left undisturbed.

T4 is skipped because its `RCA_CURRENT_HARDWARE_PASS_3_OF_3` entry condition was not met.
