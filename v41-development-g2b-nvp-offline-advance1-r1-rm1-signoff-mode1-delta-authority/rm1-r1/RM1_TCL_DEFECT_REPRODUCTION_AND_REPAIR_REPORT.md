# RM1-R1 Tcl publication-receipt defect reproduction and repair

## Original failure identity

- Script: `harness-original/g2b_nvp_diag2_rm1_build.tcl`
- SHA-256: `C5E5E1C0BB79F600F861122526A198D563B90C2BE0DB5EEF86AE71FB47130132`
- Size: `62286` bytes
- Failing line: original line `1079`, publication-receipt pattern list
- Triggering input: `"SourceCommit": "a7436eb81f69f09ee84301bcf214fcaa2b680ee8"`
- Exception: `invalid command name "\\t"`

The deterministic reproducer proves that `[ \\t]` inside a Tcl
double-quoted word undergoes square-bracket command substitution. After
backslash processing, Tcl attempts to invoke a command named `\\t`. This is
not TSV parsing and is not caused by the receipt value; it is unsafe regex
construction in a double-quoted Tcl word.

Reproducer:
`reproduce_rm1_publication_receipt_tcl_defect.tcl`

Reproducer SHA-256:
`5403F2D0765A4D3A2610027491CBD17EFD1C6256ECF981A37725AEF9EE30DA7C`

## Exact task-local correction

- Corrected script: `harness-corrected/g2b_nvp_diag2_rm1_build.tcl`
- SHA-256: `145A410AF61EBC06A0AB18FC2470DCCD78ED647821A46B43857A2E61CF828CE4`
- Size: `62301` bytes
- RM1 RTL/XDC/source commit changed: `NO`

Only two dynamic identity patterns changed. Each now uses Tcl `format` with a
brace-quoted regex template:

`[format {"SourceCommit"[ \\t]*:[ \\t]*"%s"} $source_commit]`

`[format {"SourceTree"[ \\t]*:[ \\t]*"%s"} $source_tree]`

The commit/tree inputs are already restricted to exact 40-hex identities.
Braces prevent command substitution while `format` inserts the identity as
data; Tcl does not recursively substitute the returned string. No `eval` is
used.

The second and final harness-only iteration changed only the R1 artifact names
and classification literals required by the governing R1 prompt. It did not
change the receipt fix, test expectations, source, RTL, XDC or build content.

Harness-only iteration count before synthesis: `2/2`.
