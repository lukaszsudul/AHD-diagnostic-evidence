# R1h terminal evidence secret scan

Result: `PASS_NO_ACTIONABLE_SECRETS`

Scope was restricted to
`C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE`. The external credential file
`C:\FPGA\VCDE-DUT-1.txt` was not opened, copied or read.

Fresh binary-aware scan before manifest/package creation:

```text
TASK_FILES_SCANNED_OR_CLASSIFIED=1799
TEXT_FILES_SCANNED=1083
TEXT_BYTES_SCANNED=5634719
BINARY_FILES_CLASSIFIED_AND_SKIPPED_AS_TEXT=716
BINARY_BYTES_CLASSIFIED=33952760
HIGH_CONFIDENCE_SECRET_FINDINGS=0
STANDALONE_PLINK_PW_FINDINGS=0
CREDENTIAL_NAMED_FILES=0
CREDENTIAL_PATH_REFERENCE_FILES=2
REPARSE_POINTS=0
NONDEFAULT_ALTERNATE_DATA_STREAMS=0
```

High-confidence patterns covered private-key headers, GitHub personal tokens,
AWS access keys, Google API keys, Slack tokens, OpenAI-style tokens and URLs
containing embedded credentials. The credential-path references are the
verbatim owner prompt's path-only declaration and this scan report's
disclosure of that same path. Neither contains a credential value. No archive
was present in the scanned task root at this stage.

The final ZIP must be scanned independently after creation because it is not
part of this pre-package scan.
