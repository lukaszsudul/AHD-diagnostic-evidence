# Static audit and synthetic-test results

## Script identities

```text
FILE=Seal-ControlFlowShorteningEvidence.ps1
SIZE_BYTES=33844
LINE_COUNT=681
SHA256=B66FD87BB9B8ED12A5684E9CC8E331DCD3DC6BF1BD8736554ABB497796E1E18B
POWERSHELL_PARSE_ERRORS=0
AST_UNIQUE_COMMAND_COUNT=29
AST_EXTERNAL_NETWORK_COMMAND_COUNT=0
AST_EXTERNAL_HARDWARE_COMMAND_COUNT=0

FILE=Test-Seal-ControlFlowShorteningEvidence.ps1
SIZE_BYTES=14568
LINE_COUNT=309
SHA256=E1A57C1311CCE732219717ED73CF3C2DEB453E4A403C4CA8DA051EBC6DE13899
POWERSHELL_PARSE_ERRORS=0
AST_UNIQUE_COMMAND_COUNT=17
AST_EXTERNAL_NETWORK_COMMAND_COUNT=0
AST_EXTERNAL_HARDWARE_COMMAND_COUNT=0
```

## Synthetic suite

The test suite completed locally without touching the real task root:

```text
STATIC_AUDIT=PASS
POWERSHELL_PARSE=PASS
SYNTHETIC_SUCCESS_FIXTURE=PASS
DETERMINISTIC_TWO_ROOT_ZIP_HASH=PASS
INDEPENDENT_ZIP_ENTRY_AUDIT=PASS
SIDECAR_HASH_CORRESPONDENCE=PASS
MANIFEST_AND_SECURITY_INCLUDED=PASS
OUTPUTS_AND_RECEIPTS_EXCLUDED=PASS
SECRET_NEGATIVE_FIXTURE=PASS
BIT_DCP_NEGATIVE_FIXTURE=PASS
NESTED_ARCHIVE_NEGATIVE_FIXTURE=PASS
TEMP_FILE_NEGATIVE_FIXTURE=PASS
TOCTOU_NEGATIVE_FIXTURE=PASS
SEAL_TESTS=PASS_ALL
DETERMINISTIC_FIXTURE_ZIP_SHA256=79966BB3777C6ED1A5ED1C6C7A0506DB38EB767D4A0188C2C5CD22A168225C02
```

The deterministic fixture hash is a test-vector identity only. It is not the
hash of the future real evidence package.

## Production status

```text
REAL_TASK_ROOT_SEALED_AT_STATIC_TEST_TIME=NO
REAL_EVIDENCE_ZIP_CREATED_AT_STATIC_TEST_TIME=NO
PRODUCTION_SEAL_RESULT=RECORDED_BY_GENERATED_08_FINAL/EVIDENCE_ZIP_INTEGRITY.txt
NETWORK_ACTIONS=0
PUBLICATION_ACTIONS=0
HARDWARE_ACTIONS=0
```

## Production fail-closed adaptation

The first production invocation stopped before snapshot or output creation
because its report guard incorrectly equated the archive/root name
`V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1` with the owner-exact report
task `V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1`.  No ZIP,
manifest, security file, integrity file, or sidecar was created.

The task-local guard now keeps those two authorized identities separate.  The
fixture also uses the owner-exact task value and the validated
`R1_61_TICKS_HAS_MULTIPLE_VALID_DECOMPOSITIONS` result.  The complete synthetic
suite was rerun after that narrow change and again passed every gate.  A later
production run is therefore a seal retry after a pre-output validator stop,
not a reuse or overwrite of any evidence package.
