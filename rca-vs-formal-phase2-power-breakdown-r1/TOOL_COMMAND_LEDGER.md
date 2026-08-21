# Tool command ledger

This ledger records the report-only Vivado launcher, scripts, adaptations, and
command outcomes. No checkpoint was saved or rewritten.

```text
REPORT_SEQUENCE_STATUS=PASS_TWO_IDENTICAL_COMPLETE_SEQUENCES
FORMAL_PHASE2_REPORT_SEQUENCE=PASS
RCA_REPORT_SEQUENCE=PASS
REPORT_COMMANDS_PER_COMPLETE_SEQUENCE=25
SUCCESSFUL_REPORT_POWER_FORMS_PER_ROLE=6
SUCCESSFUL_REPORT_POWER_INVOCATIONS_TOTAL=12
FAILED_REPORT_POWER_INVOCATIONS=0
SUPPLEMENTAL_CLOCK_INVENTORY_STATUS=PASS_BOTH_EXACT_DCPS
SUPPLEMENTAL_CLOCK_INVENTORY_ATTEMPTS=5
SUPPLEMENTAL_CLOCK_INVENTORY_FAIL_CLOSED_ATTEMPTS=3
SUPPLEMENTAL_CLOCK_INVENTORY_PASSES=2
OPERATING_CONDITION_CHANGES=0
SWITCHING_ACTIVITY_CHANGES=0
IMPLEMENTATION_COMMANDS=0
HARDWARE_COMMANDS=0
```

## Vivado identity and launcher

```text
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
SUPPORTED_WRAPPER=C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat
ENVIRONMENT_SCRIPT=C:\AMDDesignTools\2025.2\Vivado\settings64.bat
RAW_UNWRAPPED_EXECUTABLE_USED=NO
PROMPT_STYLE_DUPLICATED_VERSION_PATH_PRESENT=NO
INSTALLED_LAYOUT_ADAPTATION=USE_VERIFIED_VIVADO_SUBDIRECTORY_WRAPPERS
```

## Help capture adaptations

Three help-capture attempts occurred before any checkpoint was opened. The
first semantically failed because `help -output` is unsupported, the second
failed because Tcl `redirect` is unavailable, and the third passed by writing
each `help` return string with Tcl file I/O. All raw outputs are retained.

```text
ATTEMPT_1=FAIL_HELP_OPTION_OUTPUT_UNAVAILABLE
ATTEMPT_2=FAIL_TCL_REDIRECT_COMMAND_UNAVAILABLE
ATTEMPT_3=PASS_HELP_RETURN_STRING_WRITTEN_BY_TCL
CHECKPOINTS_OPENED_DURING_HELP_CAPTURE=0
```

Installed help confirms `report_power -file`, `-hier all`,
`-hierarchical_depth 0`, `-l 0`, `-verbose`, `-advisory`, `-format xml`,
and `-rpx`. The suite does not use `-no_propagation`, `-vid`, `-xpe`, or
any operating-condition/activity setter.

## Common report suite

Both successful DCP audits used one byte-identical Tcl script and the same
ordered 25-label procedure. Only the authorized role, exact DCP path, output
root, and expected-top read-only gate differed. After normalizing DCP/output
paths, the retained command sequences are identical.

```text
FORMAL_PHASE2_TOP=ahd_capture_top_xdma
FORMAL_PHASE2_ROUTED_NETS=24926_OF_24926
FORMAL_PHASE2_ROUTING_ERRORS=0
RCA_TOP=ahd_capture_top_pcie
RCA_ROUTED_NETS=7385_OF_7385
RCA_ROUTING_ERRORS=0
PART=xc7a35tcsg325-2
REPORT_POWER_STANDARD=PASS_BOTH
REPORT_POWER_HIERARCHY_ALL_VERBOSE=PASS_BOTH
REPORT_POWER_HIERARCHY_POWER=PASS_BOTH
REPORT_POWER_ADVISORY=PASS_BOTH
REPORT_POWER_XML=PASS_BOTH
REPORT_POWER_RPX=PASS_BOTH
```

XML is the supported machine-readable power format. No unsupported CSV power
output was requested.

## Preserved pre-power adaptations

Two formal suite starts stopped before any `report_power` call:

```text
FORMAL_ATTEMPT_1=STOP_IDENTITY_CHECK_USED_SESSION_LABEL_INSTEAD_OF_TOP_PROPERTY
FORMAL_ATTEMPT_2=STOP_SWITCHING_ACTIVITY_ALL_REQUIRES_TYPE_OR_OBJECT
FORMAL_ATTEMPT_3=PASS_COMPLETE_REPORT_SEQUENCE
RCA_ATTEMPT_1=PASS_COMPLETE_REPORT_SEQUENCE
FAILED_PREPOWER_ATTEMPTS_AFFECT_POWER_RESULTS=NO
REPORT_POWER_INVOCATIONS_IN_FAILED_ATTEMPTS=0
```

The first adaptation compares the `TOP` property while retaining
`current_design` separately. The second uses documented, read-only top-port
and default-activity reports instead of the invalid bare `-all` form. No
activity setter, reset, or SAIF command was introduced.

## Supplemental clock-domain fallback

The same final `clock_inventory.tcl` was used for both DCPs. It contains only
clock/cell/property queries, `all_registers`, evidence-file writes, and
`close_design`. It traced all report-power roots to exact clock objects and
source pins and emitted representative sinks plus primitive/hierarchy counts.

```text
FORMAL_EXACT_CLOCK_OBJECTS=9
RCA_EXACT_CLOCK_OBJECTS=7
FORMAL_CLOCK_INVENTORY=PASS
RCA_CLOCK_INVENTORY=PASS
LOGIC_POWER_BY_CLOCK_DOMAIN=NOT_DIRECTLY_AVAILABLE_FROM_UNMODIFIED_DCP
SEQUENTIAL_AND_UTILIZATION_FALLBACKS_ARE_COUNTS_NOT_POWER=YES
```

Three formal supplemental starts stopped fail-closed and remain preserved:

```text
SUPPLEMENTAL_ATTEMPT_1=FAIL_TCL_SUMMARY_CSV_BRACKET
SUPPLEMENTAL_ATTEMPT_2=FAIL_EMPTY_REGISTER_COLLECTION_GUARD_MISSING
SUPPLEMENTAL_ATTEMPT_3=FAIL_GENERATED_CLOCK_PATTERN_RETURNED_MULTIPLE_OBJECTS
SUPPLEMENTAL_ATTEMPT_4=PASS_FORMAL_PHASE2
SUPPLEMENTAL_ATTEMPT_5=PASS_RCA
SUPPLEMENTAL_FAILED_ATTEMPT_DCP_WRITES=0
SUPPLEMENTAL_FAILED_ATTEMPT_POWER_REPORTS=0
```

The three failed Tcl processes unloaded their in-memory DCPs on exit without
save. The two passing inventories used explicit `close_design`.

## Script identities

```text
capture_vivado_2025_2_help.tcl_SHA256=6E0C767AC396F061FFD80FE81F2B996699FACBBD87A272A21B8D025E2556C8D3
run_help.cmd_SHA256=C2CDE0B3AB2A5606E4B2660F35EF348D49A1B8FFBCEA82E0CD05344D2825C1A5
run_power_breakdown.tcl_SHA256=5B11D9AAE10A34819CF0463E0E39828DB7BE34F8EFB4DDFD844F75CBFB45BB67
run_report_suite.cmd_SHA256=E83865389E2BC5E97255F4B15B1F0DF2841FF9498A92CC90FE8616F996F41D1A
clock_inventory.tcl_SHA256=8681850DDB69F4142DAC580A541E0191D380351600F5A7EDD920305A7A93C917
run_clock_inventory.cmd_SHA256=CBE4A46EA03EEEC2CEC6325B2C884147FD2AB19692F96A6B8DB6BB78043BF19D
parse_power_reports.ps1_SHA256=F204F9DD0C5494D0A18CA371254404E6EC8F0F2F6B0106BFD61784F40F597C00
finalize_comparison.ps1_SHA256=364680CAE4E5F7DE74047BE10FF337CBBF06B70139353E44773C632193CE2264
enrich_clock_inventory.ps1_SHA256=53EC0C226B92403CFDC6F74594DBE2C4B3E0416EDD849E2D296B8F81DC438CC5
package_evidence.ps1_SHA256=B492B5963444A3A6E9596F52E0AC5803C50F4632D29064FA961F110C51EDE726
```

## Pre/post invariance and no mutation

Within each image, core-voltage and default-activity inputs are byte-identical
before and after power analysis. Clock definitions and networks are
semantically identical after removing report headers. Derived junction
temperature and propagated vectorless averages are results, not setter actions.

```text
OPERATING_CONDITION_SETTER_CALLS=0
SWITCHING_ACTIVITY_SETTER_CALLS=0
SAIF_READS=0
CHECKPOINT_WRITES=0
SET_PROPERTY_CALLS=0
SYNTHESIS_COMMANDS=0
IMPLEMENTATION_COMMANDS=0
HARDWARE_COMMANDS=0
TASK_ISSUED_FORMAL_GIT_COMMANDS=0
```

`FORMAL_REPOSITORY_MUTATIONS=0` is task operation accounting: the formal
repository was not accessed or mutated by this audit.
