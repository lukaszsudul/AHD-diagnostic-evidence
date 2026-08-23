# R6 selected-new-JTAG target-selector audit

## Result

```text
R6_SELECTED_JTAG_CANONICAL_ID=Xilinx/80802026a98b01
R6_FULL_JTAG_TARGET_PATH=localhost:3121/xilinx_tcf/Xilinx/80802026a98b01
TARGET_MATCH_MODE=EXACT_CANONICAL_ID_OR_EXACT_PATH_SUFFIX
TARGET_SELECTOR_FIXTURES=PASS_8_OF_8
FALLBACK_TO_FIRST_TARGET=NO
LEGACY_HS2_REQUIRED=NO
TARGET_SELECTOR_STATIC_AUDIT=PASS
LIVE_JTAG_OR_VIVADO_EXECUTED=NO
```

The pure selector accepts one and only one enumerated target whose name is
either the exact canonical ID or ends with the exact canonical suffix. It
rejects zero targets, multiple targets, duplicate canonical matches, the old
Digilent target, shorter near matches, and longer near matches. Live harnesses
add a fail-closed check for the exact known full path.

The selector records the complete property list for every enumerated target
before classification. It contains no programming, design mutation, or JTAG
frequency command.

## Offline fixtures

The final fixture record is
`02_TARGET_SELECTOR/TARGET_SELECTOR_FIXTURE_RESULTS_FINAL.csv`.

| Fixture | Input class | Expected result | Result |
|---|---|---|---|
| A | one exact full path | PASS | PASS |
| B | one exact canonical ID | PASS | PASS |
| C | old Digilent target | FAIL_OLD_TARGET_NOT_SELECTED | PASS |
| D | shorter near match | FAIL_NEAR_MATCH | PASS |
| E | longer near match | FAIL_NEAR_MATCH | PASS |
| F | two targets, one canonical | FAIL_TARGET_COUNT_NOT_ONE | PASS |
| G | two canonical matches | FAIL_DUPLICATE | PASS |
| H | no target | FAIL_NO_TARGET | PASS |

## Frozen hashes

```text
select_r6_jtag_target.tcl_SHA256=3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE
test_select_r6_jtag_target.tcl_SHA256=28F41BD71E51AF5ED537841B066413C483EA405C3588706EC7328B4547119DD8
TARGET_SELECTOR_FIXTURE_RESULTS_FINAL.csv_SHA256=29370DB70767F06B6FAD59197AD707887A82A6249344A4C2BF5E70A789948271
Test-R6SelectedJtagStatic.ps1_SHA256=838BD8B5818834E5BDF773DBB3A0C9EEC674A549C418DBC73C156A491A35E981
```

