# R1g fail-closed prebuild-manifest plan

## Status

```text
PLAN_STATUS=PREPARED_NOT_FINALIZED
FINAL_R1G_MANIFEST_CREATED=NO
SOURCE_COMMIT_CREATED_BY_THIS_WORK=NO
FINAL_PREFLIGHT_EXECUTED_BY_THIS_WORK=NO
FULL_BUILD_EXECUTED_BY_THIS_WORK=NO
```

`New-R1gPrebuildManifest.ps1` is a post-commit generator. It is deliberately
unusable for the current precommit candidate: generation requires the exact
40-hex R1g commit/tree, a clean worktree on the frozen branch, direct-parent
proof, a source-identity receipt, the final consolidated equivalence receipt,
and the result, atomic consumed marker, and PASS console log from the sole
post-commit RTL-elaboration preflight. It also requires the explicit
`-FinalizeAfterCommit` switch.

The generator refuses to overwrite any manifest or sidecar. It performs every
gate before creating a temporary file and atomically publishes the manifest
only after all checks pass. No build sentinel, Vivado project, synthesis,
implementation, checkpoint, bitstream, source, or ledger is touched.

## Exact inherited schema

The generator starts from the exact R1f manifest at SHA-256
`34626CAFDF0D2CD6A4DA87B6D7ED6C7146B4C16E7384BD5AA3927BE440859A04`.
That source contains 28 `META`, 51 `SOURCE_SHA256`, and 19
`ACCEPTED_LOG_SHA256` records. The R1g output retains the exact three-record
grammar understood by the frozen/adapted build verifier:

```text
META|KEY|VALUE
SOURCE_SHA256|repository/relative/path|64_HEX_SHA256
ACCEPTED_LOG_SHA256|LABEL|absolute_path|64_HEX_SHA256
```

All 26 scientific/build R1f META gates are retained byte-for-value. Only the
two source-identity values are replaced by the exact R1g commit/tree. Additive
R1g metadata records bind language mode, rewrite scope, compiler result,
semantic equivalence, the sole final preflight, host-tool gates, and the
provenance-only build-script delta.

All 51 inherited source paths are rehashed from the clean committed R1g
worktree. The generator requires every hash other than
`rtl/nvp/nvp6134c_i2c_bringup.vhd` to remain exactly equal to R1f, and requires
the mechanical bringup result to equal
`66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024`.
Git must report that as the sole R1f-to-R1g changed tracked path.

## Log-label mapping

The complete mapping is frozen in `R1G_PREBUILD_LABEL_MAP.csv`. The 17
simulation/scoreboard/timing labels required by the inherited build verifier
bind to the final current R1g cross-standard/full-matrix gate receipt.
`TOP_INTEGRATION` binds to the post-commit production-frontend RTL-elaboration
PASS result. `HOST_TOOL_FIXTURES` binds to the current R1g host-tool gate.

Additional log records bind the underlying source identity, language contract,
static construct audit, mechanical scope, production-mode compiler receipt and
log, full equivalence gate, preflight static audit/result/consumption/PASS log,
build-script static audit and Tcl, and host fixture/tooling evidence. These
additive records are accepted by the R1f-derived manifest parser and make the
R1g-specific release claims hash-bound.

## Fail-closed release conditions

The generator checks all of the following before emitting any final file:

1. exact R1f manifest, R1g build Tcl, and final-preflight Tcl hashes;
2. exact branch, clean Git top, HEAD/tree arguments, exact R1f parent/tree,
   one commit above R1f, and the one-file compatibility diff;
3. exact language/static/source-scope/compiler markers and no VHDL-2008 mode;
4. complete R1f-reference/R1g-candidate equivalence and every inherited
   scoreboard/timing marker;
5. current host-tool hash and 24+3 fixture gates;
6. one consumed final preflight, a PASS result bound to the same commit/tree,
   zero unsupported-language errors, zero downstream commands, and a separate
   PASS console log;
7. exact inherited META values and source cardinality/hashes.

Only then may it create:

```text
08_BUILD/R1G_PREBUILD_MANIFEST.txt
08_BUILD/R1G_PREBUILD_MANIFEST_SHA256.txt
08_BUILD/R1G_PREBUILD_MANIFEST_VERIFICATION.txt
```

These files do not exist as part of this preparation.

