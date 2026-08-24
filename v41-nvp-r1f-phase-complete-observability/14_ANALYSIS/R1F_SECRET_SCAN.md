# R1f post-report secret scan

```text
TASK=V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY_AND_REPLICATED_PAIRED_AB
AUDIT_UTC=2026-08-24T11:31:51.6890773Z
SCAN_MODE=LOCAL_READ_ONLY_POST_REPORT_CONTENT_SCAN
FINAL_REPORT_INCLUDED_IN_SCAN=YES
FINAL_REPORT_SHA256=2F0D7997B2226C7A770F9221ED2BB095B1C2A53EB5BB74882629C5900544C09D
AUDIT_OUTPUT_EXCLUDED_BY_CONSTRUCTION=YES_CREATED_AFTER_SCAN

TASK_ROOT_INPUT_FILES=1522
TASK_ROOT_TEXT_FILES_SCANNED=737
TASK_ROOT_TEXT_BYTES_SCANNED=1727123
TASK_ROOT_LATIN1_FALLBACK_TEXT_FILES=1
TASK_ROOT_BINARY_FILES_EXCLUDED_FROM_TEXT_DECODING=784
TASK_ROOT_XSIMK_EXECUTABLES_EXCLUDED_FROM_TEXT_DECODING=61
TASK_ROOT_OTHER_UNSCANNED_FILES=0
TASK_ROOT_REPARSE_POINTS=0
TASK_ROOT_SUSPICIOUS_CREDENTIAL_FILENAMES=0
TASK_ROOT_HIGH_CONFIDENCE_SECRET_FINDINGS=0
```

All 61 executable files under the task root were `xsimk.exe` simulation
binaries. They and the other simulator databases, debug images, bitstreams,
checkpoints, waveform files, images, PDFs and archives were classified as
binary and were not decoded as text. The one non-UTF-8 Vivado build log was
decoded losslessly for ASCII secret-pattern coverage using a Latin-1 fallback;
it was not treated as a binary executable.

The text scan covered Markdown, plain text, logs, Tcl, PowerShell, shell,
Python, SystemVerilog/VHDL, XDC, CSV/TSV, JSON, patches, journals, resource
fixtures, marker/version files and extensionless text support files. Rules
covered private-key blocks, GitHub/OpenAI/AWS/Slack/Google/Stripe key formats,
HTTP URL user-info, bearer credentials, literal password/secret/token
assignments, `sshpass -p`, and executable PuTTY inline-password forms.

## Immutable R7 archive

The exact historical R7 package was opened with read-only ZIP streams. Nothing
was extracted or changed. Its two nested R6/R5 ZIP packages were likewise
opened recursively from memory so no nested archive content was omitted.

```text
R7_INPUT_ZIP=C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\00_R7_INPUT\V41_NVP_R1E_R7_COMPLETE_MEASUREMENT_EVIDENCE.zip
R7_INPUT_ZIP_SHA256=A1864DA7EC52AEE852169656808510C42D98FDCE27816D82449946B610DD2A56
ZIP_ARCHIVES_OPENED_READ_ONLY_IN_MEMORY=3
NESTED_ZIP_ENTRIES=2
ZIP_FILE_ENTRIES_RECURSIVE=432
ZIP_TEXT_ENTRIES_SCANNED=424
ZIP_TEXT_BYTES_SCANNED=2033190
ZIP_LATIN1_FALLBACK_TEXT_ENTRIES=22
ZIP_BINARY_ENTRIES_EXCLUDED_FROM_TEXT_DECODING=6
ZIP_EXECUTABLE_ENTRIES_EXCLUDED_FROM_TEXT_DECODING=0
ZIP_OTHER_UNSCANNED_ENTRIES=0
ZIP_RAW_INLINE_PW_HEURISTIC_MATCHES=2
ZIP_RAW_INLINE_PW_MATCHES_MANUALLY_CLEARED=2
ZIP_ACTIONABLE_INLINE_PW_FINDINGS=0
ZIP_HIGH_CONFIDENCE_SECRET_FINDINGS=0
```

The two raw inline-`-pw` heuristic matches were the phrases “no executable
PuTTY -pw form” in a historical static-audit result and in its test source.
Neither is a command or credential. Sixteen suspicious archive filenames were
also reviewed: they were prior secret-scan reports/scripts or deliberately
negative parser fixtures such as `missing_token.resource`; none contained a
secret.

## SSH and credential handling

```text
CURRENT_SSH_TOOL_SCOPE=08_HOST_TOOLS_PLUS_09_HARDWARE_PRECHECK
CURRENT_SSH_TOOL_SCOPE_FILES=28
CURRENT_SSH_TOOL_SCOPE_STANDALONE_PW_LITERALS=0
CURRENT_SSH_TOOL_SCOPE_PWFILE_LITERALS=0
CURRENT_SSH_TOOL_SCOPE_SEND_PASSWORD_STDIN_CALLS=7
CURRENT_SSH_TOOL_SCOPE_ACCEPTED_HELPER_HASH_REFERENCES=2

ACCEPTED_CONTEXTUAL_PLINK_SHA256=5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9
R7_ARCHIVE_CONTEXTUAL_HELPER_COPIES=2
R7_ARCHIVE_CONTEXTUAL_HELPER_HASH_MATCHES=2_OF_2
R7_ARCHIVE_HELPER_PWFILE_LITERALS=4
R7_ARCHIVE_HELPER_STANDALONE_PW_LITERALS=2_STATIC_REJECTION_CHECKS
R7_ARCHIVE_HELPER_EXECUTABLE_STANDALONE_PW_INVOCATIONS=0

TASK_ROOT_PWFILE_POLICY_TOKENS=1
TASK_ROOT_STANDALONE_PW_POLICY_TOKENS=1
TASK_ROOT_CREDENTIAL_PATH_OR_FIELD_REFERENCES=2
CREDENTIAL_NAMED_FILES_COPIED_INTO_TASK_ROOT=0
CREDENTIAL_FILE_OPENED_BY_THIS_AUDIT=NO
CREDENTIAL_VALUE_LEAKAGE_FINDINGS=0
```

The current R1f wrappers delegate transport to the exact hash-pinned R7
contextual helper, so they do not reproduce its Plink option list. Both
in-archive copies of that helper are byte-identical to the accepted hash. Each
constructs the actual Plink call with `-pwfile`; its only standalone `-pw`
literal is a fail-closed argument-structure check that rejects any occurrence.
The helper passes authorized sudo input through redirected stdin, removes the
temporary password file, and emits only sanitized transport metadata plus
command stdout/stderr. Scanning the complete current evidence tree found no
credential value in those materials.

The two current-tree credential references are policy text naming the approved
credential file/field, not its contents. The credential file is outside this
task root and was deliberately not opened by this audit.

```text
SECRET_SCAN_HIGH_CONFIDENCE_MATCHES=0
SSH_FORBIDDEN_INLINE_PW_INVOCATIONS=0
CREDENTIAL_VALUE_LEAKAGE_FINDINGS=0
SECRET_SCAN_GATE=PASS_POST_REPORT_CURRENT_TREE_AND_IMMUTABLE_R7_ARCHIVE
```
