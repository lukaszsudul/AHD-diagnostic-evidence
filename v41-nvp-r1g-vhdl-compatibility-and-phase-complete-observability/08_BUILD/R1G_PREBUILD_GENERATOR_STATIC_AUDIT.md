# R1g prebuild-generator static audit

## Result

```text
AUDIT_RESULT=PASS_PREPARED_GENERATOR_NOT_FINALIZED
GENERATOR=New-R1gPrebuildManifest.ps1
GENERATOR_SHA256=99E6F0B7E16DC0DE3946D78D32F24EA3AB3FA27DEAC7165E62E585202233182B
GENERATOR_BYTES=26042
POWERSHELL_PARSE_ERRORS=0
POWERSHELL_TOKEN_COUNT=3074

EXACT_R1F_MANIFEST_SHA256=34626CAFDF0D2CD6A4DA87B6D7ED6C7146B4C16E7384BD5AA3927BE440859A04
R1F_META_RECORDS=28
R1F_SOURCE_RECORDS=51
R1F_REQUIRED_LOG_LABELS=19
R1G_ADDITIVE_LOG_LABELS=18

SYNTH_DESIGN_COMMANDS=0
CREATE_PROJECT_COMMANDS=0
VIVADO_EXECUTIONS=0
BUILD_TCL_EXECUTIONS=0
SOURCE_EDITS=0
LEDGER_EDITS=0

FINAL_R1G_MANIFEST_CREATED=NO
FINAL_R1G_MANIFEST_HASH_SIDECAR_CREATED=NO
FINAL_R1G_MANIFEST_VERIFICATION_CREATED=NO
FINAL_RTL_ELABORATION_PREFLIGHTS_EXECUTED=0
FULL_CLEAN_BUILDS_EXECUTED=0
```

The generator is a bounded post-commit hash/receipt assembler. It invokes only
read-only Git identity/diff/status queries and local file hashing before it
creates task-local manifest outputs. It has no Vivado, synthesis,
implementation, bitstream, source-edit, commit, push, JTAG, SSH, MMIO, DMA, or
hardware execution path.

## Fail-closed checks exercised

Two non-mutating invocations were made against the current precommit state.
The first omitted the mandatory `-FinalizeAfterCommit` switch and was rejected
by PowerShell parameter binding. The second supplied the switch but pointed to
the reserved future final-preflight evidence path; it stopped because that
post-commit evidence root does not exist.

Both checks left all three reserved final outputs absent:

```text
R1G_PREBUILD_MANIFEST.txt=ABSENT
R1G_PREBUILD_MANIFEST_SHA256.txt=ABSENT
R1G_PREBUILD_MANIFEST_VERIFICATION.txt=ABSENT
```

The generator additionally refuses any existing final output and publishes
the manifest/hash/verification trio atomically with cleanup on failure. The
manifest itself is moved into place last.

## Binding audit

The exact inherited R1f build verifier requires the 28 META records, every
required production/changed source hash, and 19 accepted-log labels. The
generator preserves all inherited META values except the two source-identity
fields, preserves/recomputes all 51 exact source records, and supplies all 19
required labels from final current R1g evidence. Eighteen additive labels bind
the R1g-specific source, language, rewrite, compiler, equivalence, preflight,
build-script, and host-tool evidence.

The source gate is stricter than the inherited parser: Git must prove one clean
direct child of exact R1f, and the only changed tracked path must be
`rtl/nvp/nvp6134c_i2c_bringup.vhd`. Its committed SHA-256 must be
`66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024`;
every other inherited manifest source must retain its exact R1f hash.

The final-preflight gate requires all three mutually corroborating artifacts
from the same post-commit execution: atomic consumption marker, PASS result,
and PASS console log. A failure receipt is a hard stop. This prevents a static
script audit or a precommit parser pass from being substituted for the one
authorized production-front-end RTL elaboration.

```text
R1G_PREBUILD_GENERATOR_STATIC_CONTRACT=PASS
FAIL_CLOSED_BEFORE_EXACT_R1G_COMMIT=YES
FAIL_CLOSED_BEFORE_FINAL_PREFLIGHT_PASS=YES
R1F_MANIFEST_SCHEMA_COMPATIBILITY=PASS
R1G_SPECIFIC_GATES_HASH_BOUND=YES
SAFE_FOR_POST_COMMIT_USE=YES_SUBJECT_TO_LISTED_INPUTS
```

