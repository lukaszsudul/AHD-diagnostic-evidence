# R6 to R7 programming-observer delta classification

```text
OBSERVER_DELTA_CLASSIFICATION=PREPROGRAM_DONE_MODE_AND_RECEIPT_ONLY
POSTPROGRAM_VENDOR_STARTUP_LOGIC_CHANGED=NO
POSTPROGRAM_DONE_LOGIC_CHANGED=NO
PROGRAM_INVOCATION_COUNT_LOGIC_CHANGED=NO
NO_RETRY_LOGIC_CHANGED=NO
TARGET_SELECTOR_CHANGED=NO
JTAG_FREQUENCY_CHANGED=NO
POSTPROGRAM_TCL_BLOCK_NORMALIZED_EQUAL=YES
MODE_AWARE_OBSERVER_STATIC_AUDIT=PASS
```

R7 adds five-sample stable-DONE mode classification and a role-bound configured-image receipt gate before the unchanged R6 PROGRAM.FILE/program/post-program block. Bootstrap accepts stable DONE 0 or 1; transitions require stable DONE 1 and the phase-appropriate receipt.
