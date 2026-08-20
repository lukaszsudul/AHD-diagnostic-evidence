# PuTTY Plink password-channel preflight

## Outcome

The official portable Plink 0.84 identity gate passed, TCP port 22 was
reachable, and the sealed ED25519 fingerprint was recovered from preserved
local T1 and overnight evidence.

Before any Plink process was started, the task-local helper compared the
in-memory secret against every intended Plink argument. An exact collision was
found in a required non-secret argument. Starting Plink would therefore have
placed the password value in a process argument, contrary to the absolute
secret-handling rule.

The invocation was rejected before creating a password file and before opening
an SSH connection.

    TCP_22_REACHABLE=YES
    SEALED_HOST_KEY_SOURCE=PRIOR_LOCAL_T1_AND_OVERNIGHT_EVIDENCE
    SEALED_HOST_KEY_TYPE=ED25519
    SEALED_HOST_KEY_SHA256=SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8
    PLINK_PROCESS_STARTED=NO
    PLINK_ARGUMENT_SECRET_COLLISION=YES
    PASSWORD_IN_EXECUTED_PROCESS_ARGUMENTS=NO
    PASSWORD_AUTH_SESSION_1=NOT_RUN
    PASSWORD_AUTH_SESSION_2=NOT_RUN
    PASSWORD_AUTH_SESSION_3=NOT_RUN
    PASSWORD_AUTH_3_OF_3=NOT_RUN
    SUDO_AUTH_TRUE=NOT_RUN
    SUDO_REBOOT_PERMISSION=NOT_RUN
    REBOOT_EXECUTED_DURING_PREFLIGHT=NO
    SSH_PREFLIGHT_CLASSIFICATION=FAIL_SECRET_HANDLING_GATE

The T1 hardware campaign was not authorized to proceed past this failed gate.
