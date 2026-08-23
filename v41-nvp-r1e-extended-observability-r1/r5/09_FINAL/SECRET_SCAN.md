# R5 evidence secret scan

SCAN_UTC=2026-08-23T19:35:50.2978203Z

The task-local evidence tree was scanned without reading or copying the
external credential file. Binary FPGA artifacts were excluded from text
inspection and remained protected by their exact size and SHA-256 identity
gates.

```text
CREDENTIAL_FILE_INCLUDED=NO
PRIVATE_KEY_FILE_INCLUDED=NO
PASSWORD_TEMP_FILE_COUNT=0
EXECUTED_COMMAND_STANDALONE_PUTTY_PW_OPTION_COUNT=0
HIGH_CONFIDENCE_SECRET_TOKEN_PATTERN_COUNT=0
ASSIGNMENT_SHAPED_OCCURRENCE_COUNT=20
REVIEWED_SENSITIVE_ASSIGNMENT_FINDINGS=0
SECRET_SCAN_RESULT=PASS
```

The 20 assignment-shaped occurrences were reviewed in context. They are
variable declarations or expressions, parser token variables, sanitized audit
fields, and secret-handling control flow in the frozen credential-safe helper.
No literal credential or secret value was present. The live phase evidence
directories contain no executed SSH record because R5 stopped at the JTAG
stability gate.

The scan also verified that the R5 tree contains no `VCDE-DUT-1.txt`, private
key file, `pw-*.tmp` file, or standalone PuTTY `-pw` option in live phase
evidence. The permitted `-pwfile` mechanism is only present in prepared,
unexecuted tooling and guidance.
