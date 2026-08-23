# R6 selected-target programming-adapter audit

## Result

The R6 adapter changes only target discovery/selection and target/device
property evidence relative to the accepted R5 programming observer.

```text
ACCEPTED_R5_OBSERVER_SHA256=7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653
R6_SELECTED_ADAPTER_SHA256=00B612413A5322C4FC94003BDF2E6E48318DA61D0D8362D028D70035B03C47AC
ACCEPTED_OBSERVER_PARSER_SHA256=6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66
PROGRAM_ADAPTER_NORMALIZED_DIFF=TARGET_SELECTION_AND_PROPERTY_EVIDENCE_ONLY
PROGRAM_HW_DEVICES_COMMAND_COUNT=1
PROGRAM_FILE_ASSIGNMENT_COUNT=1
PROGRAM_RETRY_PATHS=0
JTAG_FREQUENCY_CHANGE_COMMANDS=0
OLD_TARGET_BINDING_PRESENT=NO
PREPROGRAM_DONE_GATE_PRESERVED=YES
STATIC_AUDIT=PASS
LIVE_JTAG_OR_VIVADO_EXECUTED=NO
```

The normalized comparison removes only the R5 target-selection block, the R6
selector import/full-path gate, and the R6 selected-device property-evidence
line. The remaining Tcl is byte-for-byte equal after newline normalization.
This preserves the accepted invocation counter, startup/DONE transcript
contract, single `program_hw_devices`, exit handling, and no-retry behavior.

The accepted observer's pre-program `DONE == 1` gate is deliberately retained
unchanged. The read-only stability qualification permits a stable readable
DONE value of either 0 or 1. Therefore, a live stability result of DONE=0
would pass transport stability but cause the unchanged programming observer to
fail before consuming a program invocation. Per the parent coordination
ruling, that case is a fail-closed implementation-contract contradiction; it
is not resolved by broadening the target-selection-only adapter.

