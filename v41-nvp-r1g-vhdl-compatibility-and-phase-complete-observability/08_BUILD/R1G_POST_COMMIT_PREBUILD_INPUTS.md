# R1g post-commit prebuild inputs

The manifest generator remains intentionally blocked until all post-commit
items below exist and agree. No placeholder, abbreviated hash, historical R1f
preflight, or precommit candidate identity is accepted.

## Required arguments

```text
RepositoryRoot=
    exact clean R1g Git top

R1gCommit=
    exact lowercase 40-hex direct child of
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1gTree=
    exact lowercase 40-hex tree of R1gCommit

SourceIdentityReceipt=
    expected canonical path:
    07_R1G_SOURCE_IDENTITY/R1G_COMMIT_TREE_PROOF.md

CrossStandardEquivalenceReceipt=
    expected canonical path:
    05_CROSS_STANDARD_EQUIVALENCE/R1G_CROSS_STANDARD_EQUIVALENCE_GATE.md

FinalPreflightEvidenceRoot=
    fresh directory consumed by the one authorized final RTL preflight

FinalPreflightPassLog=
    exact console/batch log from that same sole preflight
```

Invoke only after the final preflight has passed:

```powershell
& 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\08_BUILD\New-R1gPrebuildManifest.ps1' `
  -RepositoryRoot '<exact-clean-r1g-worktree>' `
  -R1gCommit '<40-lowercase-hex>' `
  -R1gTree '<40-lowercase-hex>' `
  -SourceIdentityReceipt 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\07_R1G_SOURCE_IDENTITY\R1G_COMMIT_TREE_PROOF.md' `
  -CrossStandardEquivalenceReceipt 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\05_CROSS_STANDARD_EQUIVALENCE\R1G_CROSS_STANDARD_EQUIVALENCE_GATE.md' `
  -FinalPreflightEvidenceRoot '<fresh-final-preflight-evidence-root>' `
  -FinalPreflightPassLog '<sole-final-preflight-pass-console-log>' `
  -FinalizeAfterCommit
```

## Receipt content required after commit

The source-identity receipt must include exact full lines for the R1g commit,
tree, exact R1f parent, one commit above R1f, and `SOURCE_TREE_CLEAN=YES`.

The consolidated equivalence receipt must finish the complete accepted R1f
matrix and state the required P5 results, including all-output cycle equality,
zero semantic differences, pre-init equality to R1e, transaction-byte/state
identity, zero diagnostic-to-functional fanout, all phase/log/bank/serial/probe
scoreboards, exact 64/65 behavior, inherited power/D2b gates, and the frozen
production timing model.

The final-preflight evidence root must contain exactly the successful outputs
from the prepared one-shot script:

```text
R1G_FINAL_RTL_ELABORATION_PREFLIGHT_CONSUMED.marker
R1G_FINAL_RTL_ELABORATION_RESULT.txt
```

It must not contain `R1G_FINAL_RTL_ELABORATION_FAILURE.txt`. The separate PASS
console log must contain both terminal PASS markers. Result and consumed files
must bind the same exact R1g commit/tree and prove default non-2008 `VHDL`,
Vivado 2025.2 build 6299465, exact top/part, zero Synth 8-2757 or other
unsupported constructs, zero implementation/checkpoint/bitstream invocations,
and process exit 0.

## Inputs already available and revalidated by the generator

```text
exact R1f manifest and all inherited META/source schema
production language contract
complete static compatibility audit
one-file mechanical rewrite scope
production-mode xvhdl iteration-02 PASS receipt and log
final-preflight script static audit
R1g build-script static audit
R1g host-tool gate and inherited/additional fixture logs
R1g task-local build and preflight Tcl identities
```

## Output state now

```text
R1G_PREBUILD_MANIFEST_CREATED=NO
R1G_PREBUILD_MANIFEST_SHA256=NOT_AVAILABLE_BEFORE_POST_COMMIT_GATES
FINAL_RTL_ELABORATION_PREFLIGHTS_CONSUMED_BY_THIS_PREPARATION=0
FULL_CLEAN_BUILDS_CONSUMED_BY_THIS_PREPARATION=0
```

