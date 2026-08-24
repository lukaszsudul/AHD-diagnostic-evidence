# R1g independent post-commit preflight and prebuild release audit

Audit time: `2026-08-24T16:51:11.3327665Z`

## Outcome

```text
INDEPENDENT_POSTCOMMIT_RELEASE_AUDIT=PASS
INDEPENDENT_AUDIT_BLOCKERS=0
FINAL_RTL_ELABORATION_EVIDENCE=PASS
R1G_PREBUILD_MANIFEST_INDEPENDENT_VERIFICATION=PASS
FULL_CLEAN_BUILDS_CONSUMED_AT_AUDIT=0
NEXT_ACTION=CONSUME_EXACTLY_ONE_AUTHORIZED_CLEAN_BUILD
```

This audit was read-only with respect to the R1g source worktree, task
ledgers, generated manifest, preflight/build scripts, and all existing
evidence. It did not invoke Vivado, a build, JTAG, SSH, or hardware.

## Exact source identity and topology

Independent Git queries returned:

```text
R1G_SOURCE_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1G_SOURCE_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
R1G_PARENT_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1G_COMMITS_ABOVE_R1F=1
SOURCE_TREE_CLEAN=YES
```

The sole child commit changes only
`rtl/nvp/nvp6134c_i2c_bringup.vhd`: five additions and one deletion. The
committed file SHA-256 is
`66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024`,
matching the source-identity receipt and prebuild manifest.

## Sole final RTL-elaboration preflight

Exactly one consumed marker exists under `06_FINAL_FRONTEND_PREFLIGHT`, and
no final-preflight failure receipt exists.

```text
CONSUMED_MARKER_COUNT=1
CONSUMED_MARKER_SHA256=9D0CD9CF96F86F27C61FDB23F55C37FDE9798930324C34D2EC1CC9A18F724BD2
CONSUMED_BEFORE_CREATE_PROJECT=YES
RESULT_SHA256=CB8A6C9DE7CC8841038EFE73109B08BBC00057C9C8D0ECA7FA444B9504F61DED
PASS_CONSOLE_SHA256=AF9B671DC95F17C4DBA303B72F2DBD5E9154A5CAE1C74ECA46B8EE9F5DAA90C9
PREFLIGHT_TCL_SHA256=98EB91E4F39ECF41E47A62CC626514F6E1B091A6F99DD0127FDA7F51E514E26F
FINAL_RTL_ELABORATION_PREFLIGHTS=1
FINAL_RTL_ELABORATION=PASS
PROCESS_EXIT_CODE=0
SYNTH_8_2757_COUNT=0
UNSUPPORTED_LANGUAGE_CONSTRUCT_ERRORS=0
TOP_ELABORATED=ahd_capture_top_xdma
PART=xc7a35tcsg325-2
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
```

The preflight Tcl has exactly one executable `create_project` and exactly one
executable `synth_design -rtl -name r1g_rtl_preflight` statement. The console
independently contains exactly one matching `Command: synth_design -rtl`, one
`Starting synth_design`, one successful completion, and one normal Vivado
exit. It contains zero `ERROR:` or `CRITICAL WARNING:` lines, zero
`[Synth 8-2757]` occurrences, and zero unsupported-VHDL-2008 error text.

Both static source inspection and the executed console show zero commands for
`opt_design`, `place_design`, `phys_opt_design`, `route_design`,
`write_checkpoint`, and `write_bitstream`.

The queried compile-order receipt contains the four repository VHDL design
files in the required order. Each has `FILE_TYPE=VHDL` and library
`xil_defaultlib`; the script enforces those properties before elaboration.
There is no `read_vhdl`, `-vhdl2008`, `--2008`, or `FILE_TYPE=VHDL 2008`
production setting. Therefore:

```text
PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008
GLOBAL_VHDL_STANDARD_CHANGE=NO
FILE_TYPE_VHDL2008_CHANGES=0
READ_VHDL_VHDL2008_OPTION_ADDED=NO
```

## Generated R1g prebuild manifest

The finalized files independently hash as follows:

```text
R1G_PREBUILD_MANIFEST_SHA256=F31220B039E26C29C994A6F9B60A5416DE6EE0231C9C9E78CE81E013ECA473B9
R1G_PREBUILD_MANIFEST_SHA256_SIDECAR_SHA256=874975E768FACFBF4084FD6E92455975061108FCAD917CC15D0ED19F056DC7FE
R1G_PREBUILD_MANIFEST_VERIFICATION_SHA256=C62A59F0FD258CA057F9515C835F1EC3CE9D14020DF9A06CE4416D84D1D97378
```

The sidecar exactly names `R1G_PREBUILD_MANIFEST.txt` and contains the
independently calculated manifest hash. The verification receipt repeats that
same hash and binds the exact commit/tree/parent, one-commit topology, sole
preflight PASS, preflight evidence hashes, and zero full clean builds consumed.

Manifest schema and live-file verification:

```text
UNKNOWN_RECORDS=0
META_RECORDS=61
META_DUPLICATE_KEYS=0
SOURCE_RECORDS=51
SOURCE_DUPLICATE_KEYS=0
SOURCE_MISSING_FILES=0
SOURCE_SHA256_MISMATCHES=0
ACCEPTED_LOG_RECORDS=37
ACCEPTED_LOG_DUPLICATE_KEYS=0
ACCEPTED_LOG_MISSING_FILES=0
ACCEPTED_LOG_SHA256_MISMATCHES=0
```

The 28 inherited R1f metadata keys remain in the same order. The two source
identity values are correctly replaced with the exact R1g commit/tree; the
other 26 inherited values are byte-exact. The 51 inherited source paths are
identical. Exactly one source hash differs from R1f: the predeclared mechanical
rewrite in `nvp6134c_i2c_bringup.vhd`; all other 50 hashes are unchanged.

All 19 inherited accepted-log labels remain present and 18 R1g-specific labels
are added. Every referenced path exists and every one of the 37 recorded
SHA-256 values matches its current file. The task-local R1g build Tcl is bound
as accepted evidence at SHA-256
`C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A`;
the frozen tracked R1f build Tcl remains unchanged in the source inventory.

## Equivalence mapping receipt audit

The manifest adapter receipt SHA-256 is
`A4AE11515CA1E0F1F4E06249F2253DDF3D6EE2AF8EF9EE981DFCB767DFDE2957`.
It binds, without altering, the authoritative P5 gate SHA-256
`AD1B793125EAD205CB9681828452736154DADBBEA26166C7ECFF245EB87991D5`,
the validated input manifest SHA-256
`5CA2CFA50312C094CF7E3436858887A429C52980264F7155E817FBA30CE12CF5`,
the fresh component-matrix receipt SHA-256
`C2851D45025156F1A7A4FE68E39EDCC32094FE95A2876C66D31A9EAE49630D43`,
and the pre-init pair receipt SHA-256
`05406B7FCA46B3BF4017E199F348EBD64CE15E7422376750604EC3F1E09C8B72`.

Every direct assignment in the adapter agrees with the sealed P5 gate. The
schema-level mappings that are not literal duplicate lines were independently
traced to the hash-bound component matrix or paired receipts: effective
pre-init arbitration, exact logger capacity 64/overflow at 65, production
timing, inherited power, inherited D2b, and the combined tri-phase scoreboard.
The adapter explicitly preserves the authoritative tri-phase classification
`PASS_COMBINED_FOCUSED_RTL_AND_FROZEN_REFERENCE_MODEL`; its schema-level
`PASS` does not relabel reference-model-only cases as synthesized RTL.

## Release conclusion

The exact R1g direct-child source, sole default-language RTL elaboration, and
generated prebuild manifest are mutually consistent and fully hash-bound.
No prebuild hard stop was found.

```text
R1G_PREBUILD_RELEASE=PASS
INDEPENDENT_MANIFEST_AUDIT=PASS
FULL_CLEAN_BUILD_RELEASE=PASS_ONE_AUTHORIZED_INVOCATION_ONLY
```
