# Final superseding independent static audit of the R1h-R2 semantic preflight

Audit time: `2026-08-25T10:06:55.2507163+02:00`

This report supersedes the preceding audit of runner SHA-256
`584F7C07A184E7F6653450D310A2404C3FEC52503B00FA0770C84048E1A4924F`
(report SHA-256
`F0A7902CBE8C25C94AC42C7BE1A5803C932805865BDA932C27E87948291F4470`).
It audits the narrow dry-run normalization patch without invoking the semantic
frontend.

## Frozen identity and non-execution state

| Field | Exact value |
|---|---|
| Task | `V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION` |
| Scientific source commit | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` |
| Scientific source tree | `161e561f007912d73dba93c5ecd78e3cc3a6955b` |
| Source worktree | clean, including untracked-file audit |
| Canonical semantic runner SHA-256 | `265EEA66ED9FA585BD0E8D5DD913492A65AF46983CA4FECD9E5A2653E6E79546` |
| Raw immutable dry-run receipt SHA-256 | `F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6` |
| Canonical normalization-audit SHA-256 | `3EBF9874DBD5E78C8105173C6616F541F7F741A6729FF416D6BF52D55B743A4F` |
| Top / part context | `ahd_capture_top_xdma` / `xc7a35tcsg325-2` |
| Vivado context | `2025.2`, build `6299465` |

FACT: `run_01` is absent. Recursive inspection under
`05_SEMANTIC_ELABORATION` found zero `xvhdl`, `xvlog`, or `xelab` logs and zero
frontend `.jou`/`.pb` artifacts.

FACT: this audit ran no `xvhdl`, `xvlog`, `xelab`, `xsim`, Vivado, synthesis,
optimization, implementation, checkpoint, or bitstream command. It modified
only this task-local audit report.

## Independent raw-receipt audit

NETLIST-INDEPENDENT FACT: the receipt at the fixed project-setup path rehashes
to the exact frozen SHA-256 above.

SOURCE-DERIVED FACT: independent line parsing produced:

```text
RAW_ROWS=90
PARSED_ROWS=90
MALFORMED_ROWS=0
UNIQUE_KEYS=86
DUPLICATE_KEYS=4
```

The complete duplicate inventory is:

| Key | Multiplicity | Distinct values | Exact value |
|---|---:|---:|---|
| `FAILED_RECORD_WRAPPER_MODULE_NAME` | 2 | 1 | `v41_r1f_failed_txn_logger` |
| `FAILED_RECORD_WRAPPER_SOURCE_PATH` | 2 | 1 | `rtl/v41/r1f_failed_txn_logger.sv` |
| `PROBE_INDEX_WRAPPER_MODULE_NAME` | 2 | 1 | `r1h_probe_index_bram_store` |
| `PROBE_INDEX_WRAPPER_SOURCE_PATH` | 2 | 1 | `rtl/v41/r1h_probe_index_bram_store.sv` |

FACT: no contradictory or unexpected duplicate exists. Every permitted key has
exact multiplicity two and byte-identical values. All 23 exact required
semantic-gate key/value pairs are present with zero mismatch.

## Normalization logic audit

SOURCE-DERIVED FACT: before parsing, the runner binds the raw receipt to exact
SHA-256
`F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6`.
Any raw-byte change fails before `run_01` is created.

SOURCE-DERIVED FACT: `Read-ExactNormalizedKeyValueReceipt`:

- rejects blank and malformed rows;
- rejects every duplicate outside the four frozen keys;
- requires the duplicate value to equal both its first occurrence and the
  frozen allowed value;
- rejects a third occurrence immediately;
- later requires each allowed key to be present with exact multiplicity two;
- verifies the complete duplicate-key count equals four.

SOURCE-DERIVED FACT: after normalization the runner separately requires exact
shape `90 rows / 86 unique keys / 4 duplicated keys`, then case-sensitively
checks the unchanged 23 required gate values.

FACT: independent reconstruction of the 12-line canonical LF-delimited
normalization audit produced 855 UTF-8 bytes and SHA-256
`3EBF9874DBD5E78C8105173C6616F541F7F741A6729FF416D6BF52D55B743A4F`,
exactly matching the frozen runner value.

SOURCE-DERIVED FACT: the runner verifies that canonical hash before one-shot
consumption, writes the identical canonical artifact with UTF-8/no BOM, and
emits `DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT_SHA256` in the final semantic
receipt.

Classification:
`DRY_RUN_NORMALIZATION=PASS_NARROW_EXACT_FOUR_IDENTICAL_DUPLICATES_ONLY`.

## Complete static-gate re-audit

| Requirement | Result | Independent evidence |
|---|---|---|
| Canonical runner count | PASS | Exactly one canonical semantic runner. |
| Parser gate | PASS | Runner parse errors `0`; static-checker parse errors `0`. |
| Prepared artifact integrity | PASS `6/6` | Every patched entry in `PREPARED_ARTIFACT_SHA256.txt` independently matches. |
| Production source list | PASS | Exact 4 VHDL plus 17 SystemVerilog inputs; zero difference from the frozen CSV; stale address-probe source absent; exactly two accepted support inputs. |
| Exact scientific identity | PASS | Runner and current clean worktree agree on exact commit/tree. |
| Immutable dry-run prerequisite | PASS | Exact raw hash, exact normalized duplicate contract, exact shape, and 23 exact value gates all pass statically against the current receipt. |
| One-shot mechanism | PASS | Existing `run_01` rejects invocation; start marker is created before any frontend tool. `run_01` is currently absent. |
| Total frontend call sites | PASS: `3` | Exactly one `$Xvhdl`, one `$Xvlog`, and one `$Xelab` call. |
| Forbidden calls | PASS: all `0` | AST audit found zero `vivado`, `xsim`, synthesis, optimization, placement, routing, checkpoint, or bitstream calls. |
| Source/design binding prechecks | PASS | Exact declaration, instantiation, 6+3 generate, duplicate-definition, accepted-stub, and stale-source gates remain intact. |
| Frontend fail-closed checks | PASS | Nonzero exit, hard error/fatal, unresolved unit, black box, failed binding, absent exact snapshot, or missing one of six binding fragments fails. |
| Input immutability | PASS | All production inputs plus accepted stub and `glbl.v` are prehashed and post-elaboration rehashed. |
| Explicit R1h test-elaboration result | PASS | `R1H_TEST_ELABORATION=PASS` appears exactly twice: sealed receipt and stdout, both after normalization, snapshot, binding, error, and input-rehash gates. |

## Final disposition

```text
INDEPENDENT_STATIC_REAUDIT=
    PASS

CANONICAL_RUNNER_SHA256=
    265EEA66ED9FA585BD0E8D5DD913492A65AF46983CA4FECD9E5A2653E6E79546

DRY_RUN_RAW_RESULT_SHA256=
    F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6

DRY_RUN_RAW_RESULT_ROWS=
    90

DRY_RUN_RAW_RESULT_UNIQUE_KEYS=
    86

DRY_RUN_ALLOWED_IDENTICAL_DUPLICATE_KEY_COUNT=
    4

DRY_RUN_ALLOWED_DUPLICATE_MULTIPLICITY=
    2

DRY_RUN_CONTRADICTORY_OR_UNEXPECTED_DUPLICATES=
    0

DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT_SHA256=
    3EBF9874DBD5E78C8105173C6616F541F7F741A6729FF416D6BF52D55B743A4F

R1H_TEST_ELABORATION_PASS_EMISSIONS=
    2

XVHDL_SCRIPTED_INVOCATIONS=
    1

XVLOG_SCRIPTED_INVOCATIONS=
    1

XELAB_SCRIPTED_INVOCATIONS=
    1

FORBIDDEN_TOOL_INVOCATIONS=
    0

RUN_01_EXISTS=
    NO

XILINX_FRONTEND_INVOCATIONS=
    0

STATIC_BLOCKERS_REMAINING=
    0

SEMANTIC_PREFLIGHT_EXECUTION_RELEASE=
    PASS_EXACTLY_ONCE
```

UNAVAILABLE: semantic elaboration PASS is not claimed by this static audit. It
may be claimed only after the authorized one-shot runner completes.
