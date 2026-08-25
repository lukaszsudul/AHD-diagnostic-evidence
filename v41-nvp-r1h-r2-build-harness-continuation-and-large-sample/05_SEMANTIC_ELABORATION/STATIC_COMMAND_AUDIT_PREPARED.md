# Static command audit preparation

FACT: `Test-R1hR2SemanticElaborationStatic.ps1` completed read-only with PASS.
Both the authoritative one-shot runner and the static checker parse with zero
PowerShell errors.

SOURCE-DERIVED FACT: the prepared runner contains one scripted frontend call
each for `xvhdl`, `xvlog`, and `xelab`. It contains no Vivado synthesis,
optimization, placement, physical optimization, routing, checkpoint,
bitstream, or `xsim` runtime call.

SOURCE-DERIVED FACT: the prepared executable production list contains exactly
four VHDL sources and seventeen SystemVerilog sources. The stale, unused
`rtl/v41/nvp_i2c_address_probe.sv` file is excluded.

FACT: the invocation contract is exactly one scripted call each to `xvhdl`,
`xvlog`, and `xelab`, and zero calls to `vivado`, `xsim`, synthesis,
optimization, placement, routing, checkpoint, or bitstream commands.

FACT: dry-run prerequisite gating binds raw result SHA-256
`F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6`,
then parses exact `KEY=VALUE` records. It accepts only the four frozen wrapper
module/path keys as identical duplicates, each with exact multiplicity two. It
rejects contradictions, every other duplicate, other multiplicities, blank and
malformed rows. Unique extra evidence keys are allowed but never substitute for
one of the 23 exact required keys. No whole-text `.Contains` gate exists.

FACT: the canonical duplicate-normalization audit is bound to SHA-256
`3EBF9874DBD5E78C8105173C6616F541F7F741A6729FF416D6BF52D55B743A4F`.

FACT: the prepared success path emits `R1H_TEST_ELABORATION=PASS` both in the
sealed result receipt and on standard output, only after binding and input
rehash gates have passed.

UNAVAILABLE: semantic elaboration PASS is not claimed. The one-shot runner was
not executed, `run_01` does not exist, and no frontend log exists in this task
directory.
