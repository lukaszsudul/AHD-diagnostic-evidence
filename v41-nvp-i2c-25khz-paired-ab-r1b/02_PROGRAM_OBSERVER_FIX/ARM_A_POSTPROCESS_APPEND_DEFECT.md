# Arm-A postprocess append defect

```text
ARM_A_SUPERVISOR_SHA256=8522F4128762EB860D193F843C2E6B2A30B1313B2BC3F8D0FF8C8BB564D40353
ARM_A_RAW_LOG_SHA256=B635EC7C6343370C0560E3DA8A29242FDE418D1E7D4895E8A6DE1E23CEC8D67D
PROGRAM_INVOCATION_CONSUMED=1
VENDOR_STARTUP_STATUS=HIGH
PROGRAM_RETURN_MARKER_COUNT=1
SAME_SESSION_DONE=1
PROGRAM_INVOCATIONS=1
PROGRAM_TCL_RESULT=PASS_DONE_1
VIVADO_PROCESS_EXIT_CODE=0
RAW_COUNT_GATE=PASS
RAW_ORDER_GATE=PASS
ORIGINAL_SUPERVISOR_POSTPROCESS=FAIL_DOTNET_APPENDALLLINES_OVERLOAD
FPGA_PROGRAM_RETRY=NO
OFFLINE_RECOVERY_ATTEMPTS=2
OFFLINE_RECOVERY_ACCEPTED=ATTEMPT_02
ACCEPTED_WAIT_SECONDS=223.944751400
ACCEPTED_WAIT_EPOCH=SAME_WINDOWS_QPC
POSTFIX_SUPERVISOR_SHA256=2F6CF02E14E5461F9710C3F1E803F0DC325628C04D64E3C925502E88BFA315AF
POSTFIX_STATIC_AUDIT=PASS
POSTFIX_FIXTURES=PASS_11_OF_11
POSTFIX_PRIOR_R1_REPLAY=FAIL_POST_PROGRAM_OBSERVER_BIT4
```

The Arm-A Vivado/Tcl process completed before the task-local Windows script
raised a .NET overload error while appending the already-derived verdict.
The immutable raw log contains the complete required single-session sequence,
including process exit code zero. The pinned parser replayed that raw log with
all count and ordering gates passing. A separate postprocess-only script used
the same system-wide monotonic QPC epoch and proved the five-second wait had
elapsed before reboot. Neither recovery attempt opened Hardware Manager or
invoked programming.

The first recovery output is preserved even though its key/value formatting
was defective. Attempt 02 is the accepted recovery record. Before the exact
formal restoration, the supervisor's evidence-appending calls were corrected,
the full static audit and 11 fixtures were rerun, and the immutable prior R1
failure log remained correctly classified as a failure.
