# R1f independent P8 simulation-matrix coverage audit

## Refreshed scope and source/evidence identities

This read-only audit was refreshed after the final integrated producer matrix
and the standalone exact transaction-serial test completed. It does not modify
RTL or tests, run a simulator, perform a build, or make a hardware claim.

```text
AUDIT_REFRESH_DATE=2026-08-24

CURRENT_BRINGUP_SHA256=
    A2865C428B89E9492BB1D62144963558805B036F1A1212C09F968D6059AE9533

CURRENT_AUTOINIT_TB_SHA256=
    FD978BCF86A25B1E12CB5985FD29BA492E8A4F17306F2714896E4A6A295EF495

FINAL_INTEGRATED_MATRIX_LOG=
    06_SIMULATION/r1f_autoinit_observability_scoreboard/final_matrix_v4/xsim.log

FINAL_INTEGRATED_MATRIX_LOG_SHA256=
    EC8FA7BF2B49097B584658CE89869F37EDEED462A5DE5B81ECD2BF6F00847961

FINAL_INTEGRATED_MATRIX_RESULT=
    PASS_STAGE6_G0P8C5D_AUTOINIT_SIMULATION

EXACT_SERIAL_COUNTER_SHA256=
    FA92E1B52A5BB870EDBEDA5457A7021DB882AE9FF31DF880CBD97A6C7549019E

EXACT_SERIAL_COUNTER_TB_SHA256=
    3C692D146AD05ABBCF0CD5A2630675F87C2D22C01B43F85BAFEF028F2327B4D1

SERIAL_INDEX_300_LOG=
    06_SIMULATION/transaction_serial_16/xsim.log

SERIAL_INDEX_300_LOG_SHA256=
    4BEAD247C1250852226B72091E6392E17BD6B4231DD4FDB29A3FBA3313592DCB

FULL_BUILD_RUN_BY_THIS_AUDIT=NO
SIMULATOR_RUN_BY_THIS_AUDIT=NO
RTL_OR_TEST_EDIT_BY_THIS_AUDIT=NO
```

The final integrated compile log proves that the test instantiated the current
`nvp6134c_i2c_bringup.vhd` together with
`r1f_transaction_serial_counter.vhd`. The standalone serial fixture therefore
tests the exact counter RTL instantiated by the producer, not a Python or
test-only reimplementation.

Coverage labels:

- `RTL_DYNAMIC_CURRENT_PASS`: matching current synthesizable RTL and test
  executed in XSim with a terminal PASS.
- `RTL_DYNAMIC_CURRENT_PASS_STANDALONE`: exact synthesizable component RTL
  executed separately from full producer integration.
- `MODEL_DYNAMIC_PASS`: executable Python/reference-model coverage; this is
  deliberately not described as RTL coverage.
- `STATIC_AUDIT_PASS`: source/contract inspection only.

## Required P8 case coverage

| Required case | Current evidence | Coverage | Independent finding |
|---|---|---|---|
| all-ACK autoinit | final integrated matrix | `RTL_DYNAMIC_CURRENT_PASS` | Full table traffic, opportunity and transaction scoreboards, all bank-invariant checks, final bank restoration, and clean aggregate counters pass. |
| one NACK in each autoinit ACK phase | integrated modes 9/10/11/12 | `RTL_DYNAMIC_CURRENT_PASS` | Separate terminal markers prove isolated WADDR, REGADDR, DATA, and RADDR NACK cases. |
| multiple phase NACKs in one transaction | integrated mode 1 | `RTL_DYNAMIC_CURRENT_PASS` | The original-bank-read scenario checks one failed transaction with WADDR, REGADDR, and RADDR opportunity/NACK bitmaps and three legacy phase events. |
| exact 13-NACK historical pattern | integrated mode 13 | `RTL_DYNAMIC_CURRENT_PASS` | Exact injected/aggregate/record count 13 passes; legacy-first-eight reconciliation also passes. |
| exact 15-NACK historical pattern | integrated mode 14 | `RTL_DYNAMIC_CURRENT_PASS` | Exact injected/aggregate/record count 15 passes; legacy-first-eight reconciliation also passes. |
| exact 36-event historical pattern | integrated mode 15 | `RTL_DYNAMIC_CURRENT_PASS` | Exact injected/aggregate/record count 36 passes; legacy-first-eight reconciliation also passes. |
| exactly 64 failed transactions | standalone failed-transaction logger | `RTL_DYNAMIC_CURRENT_PASS_STANDALONE` | Count/stored=64, overflow=0, chronological append, immutability, and unused-zero checks pass. |
| 65th failed transaction overflow | same logger test | `RTL_DYNAMIC_CURRENT_PASS_STANDALONE` | The 65th event sets overflow, total continues, stored remains 64, and no entry is overwritten. |
| transaction index beyond 255, including index 300 | exact extracted serial-counter RTL, `transaction_serial_16/xsim.log` | `RTL_DYNAMIC_CURRENT_PASS_STANDALONE` | Marker `PASS TRANSACTION_INDEX_16_UNIQUE_AT_300` proves pre-increment indices 0..300 are unique; clear behavior also passes. Integrated producer assertions prove the same counter output equals actual transaction starts in normal autoinit runs. |
| bank-select write success | integrated all-ACK mode | `RTL_DYNAMIC_CURRENT_PASS` | Exact helper-count, cache state, and zero-invariant-error assertions pass. |
| bank-select write failure | integrated mode 6 | `RTL_DYNAMIC_CURRENT_PASS` | Failure interlock, invalid after-bank state, and update reason are checked before terminal PASS. |
| bank-verify read success | integrated all-ACK mode | `RTL_DYNAMIC_CURRENT_PASS` | Verified selections and final cache/restoration pass with zero invariant errors. |
| bank-verify transport NACK | integrated mode 12 | `RTL_DYNAMIC_CURRENT_PASS` | Isolated RADDR NACK on the operation-86-like verify transaction produces verify-transport-failure semantics and invalid after-bank state. |
| bank-verify value mismatch | integrated mode 7 | `RTL_DYNAMIC_CURRENT_PASS` | Mismatch result, terminal error, invalidation, and guarded target-write behavior pass. |
| operation-86-like transitional bank context | integrated mode 12 | `RTL_DYNAMIC_CURRENT_PASS` | Exact legacy operation `0x56`, slot `0x0055`, verify kind, RADDR NACK, result, after-valid, and update-reason assertions pass. |
| every transaction kind | integrated all-ACK mode | `RTL_DYNAMIC_CURRENT_PASS` | Terminal marker `PASS EVERY_R1F_TRANSACTION_KIND_EXERCISED` proves all defined producer kinds were observed. |
| safe probe setup/readback/restore | tri-probe main plus abort, timeout, attempt-limit, and secondary-restore RTL tests | `RTL_DYNAMIC_CURRENT_PASS_STANDALONE` | Matching probe RTL proves safe-bank selection/readback, target pre/post equality on success, original-bank restoration, abort/timeout restoration, terminal line release, and explicit secondary restoration failure evidence. |
| tri-phase probe: all ACK | Python reference model | `MODEL_DYNAMIC_PASS` | Model uses 100 reduced opportunities; there is no dedicated all-ACK RTL run. |
| tri-phase probe: exact 29/10000 WADDR NACK pattern | Python reference model | `MODEL_DYNAMIC_PASS` | Exact 29-of-10000 sequence is model-only. |
| tri-phase probe: independent Bernoulli patterns | Python reference model | `MODEL_DYNAMIC_PASS` | Independently seeded per-phase patterns are model-only. |
| tri-phase probe: clustered patterns | Python reference model | `MODEL_DYNAMIC_PASS` | Cluster, run, adjacency, streak, and block behavior are model-only. |
| tri-phase probe: prerequisite-phase NACKs | focused main probe RTL test | `RTL_DYNAMIC_CURRENT_PASS_STANDALONE` | Reduced-count RTL proves prerequisite losses consume attempts without fabricating downstream target opportunities. |
| tri-phase probe: target-phase NACKs | focused main probe RTL test | `RTL_DYNAMIC_CURRENT_PASS_STANDALONE` | All three target phases receive deterministic NACKs and pass exact hand scoreboards. |
| tri-phase probe: timeout abort | focused timeout RTL test | `RTL_DYNAMIC_CURRENT_PASS_STANDALONE` | SCL timeout, abort, line release, and original-bank restoration pass. |
| tri-phase probe: NACK-index-log overflow | RTL reduced capacity 4 plus Python capacity-512 model | `RTL_DYNAMIC_CURRENT_PASS_STANDALONE` and `MODEL_DYNAMIC_PASS` | RTL proves aggregate statistics survive overflow; the production 512-entry boundary is exercised only by the model and statically frozen parameter. |
| formal zero-page behavior | exhaustive measurement-map fixture plus reserved-range audit | `RTL_DYNAMIC_CURRENT_PASS_STANDALONE_FIXTURE` and `STATIC_AUDIT_PASS` | Fixture enumerates all 1368 R1f DWORDs as zero. The connection to exact formal Phase 2 is a static reserved-slot decode proof; exact formal RTL/bit is not instantiated in this fixture. |
| host parser version mismatch | current Python host-tool fixture suite | `MODEL_DYNAMIC_PASS` | Exact header/version mismatch and all-ones identity rejection are included in the current 16/16 passing fixture summary. |

## Required named P8 results

| Required result | Evidence-backed disposition | Literal marker status |
|---|---|---|
| `PHASE_OPPORTUNITY_COUNTERS_MATCH_SCOREBOARD=PASS` | `PASS_DYNAMIC_ASSERTION_BACKED` | `assert_r1f_common` checks every phase `NACK<=opportunity`, phase-NACK sum equals legacy aggregate, and transaction/record counts in every legal integrated mode; final matrix terminates PASS. The exact aggregate assignment string is not emitted. |
| `FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD=PASS` | `PASS_STANDALONE_LOGGER` | Exact matching logger marker is preserved in `architecture_components/logger_clean/xsim.log`. |
| `BANK_BEFORE_AFTER_SEMANTICS=PASS` | `PASS_DYNAMIC_ASSERTION_BACKED` | Current integrated success, selector-failure, verify-mismatch, verify-transport-NACK, all-kind, and 12-check-per-transaction assertions pass. The exact aggregate assignment string is not emitted. |
| `TRANSACTION_INDEX_16_UNIQUE=PASS` | `PASS_EXACT_RTL_INDEX_300` | Log emits `PASS TRANSACTION_INDEX_16_UNIQUE_AT_300`; exact requested assignment spelling is not emitted. |
| `LEGACY_FIRST8_RECONCILIATION=PASS` | `PASS_CURRENT_RTL_THREE_PATTERNS` | Exact marker is emitted independently for the 13-, 15-, and 36-event cases. |
| `TRI_PHASE_PROBE_SCOREBOARD=PASS` | `PASS_COMBINED_FOCUSED_RTL_AND_REFERENCE_MODEL` | Existing report says `PASS_FOCUSED_STANDALONE_SCOPE`; four large/statistical patterns remain explicitly model-only. |
| `SAFE_TARGET_RESTORATION=PASS` | `PASS_DYNAMIC_ASSERTION_BACKED` | Matching focused RTL success, setup-abort, timeout, attempt-limit, and secondary-failure tests all assert restoration semantics; the exact aggregate assignment string is not emitted. |

Literal aggregate marker omissions are evidence-publication cleanup items, not
missing dynamic behavior, because their underlying assertions execute in
terminally passing logs. They should be emitted in a consolidated final
simulation-gate summary before evidence sealing.

## Supporting current gates

The refreshed exact reference/candidate pre-init evidence is separately
preserved under `pre_init_equivalence/final_fresh/`. It is not substituted for
P8, but supports the required diagnostic-only boundary. The focused logger,
map, tri-probe, host-parser, and serial-counter sources also retain matching
hashes for their preserved PASS evidence.

One source-audit scope caveat remains: the superseding bank-semantics static
audit explicitly binds to earlier bringup SHA `A83E795B...`, while the current
bringup SHA is `A2865C42...` after extraction/instantiation of the separately
tested serial counter. The current integrated bank-invariant simulations pass,
but a final static delta audit must bind the bank-semantic conclusion to the
current SHA before the broader pre-build source audit is sealed. This is not a
P8 dynamic-matrix failure.

## Remaining scope distinctions

No unconditional missing P8 scenario was found under the implemented two-layer
verification plan: focused RTL proves the probe engine's protocol/counting
mechanics, and the Python reference model supplies the statistically large
all-ACK, 29/10000, Bernoulli, clustered, and production-capacity distribution
cases.

If the owner/auditor interprets every listed P8 probe pattern as requiring an
exact synthesized-RTL execution, the following remain conditional gaps:

1. all-ACK production-count probe in RTL;
2. exact 29/10000 WADDR pattern in RTL;
3. independent Bernoulli patterns in RTL;
4. clustered patterns in RTL;
5. the 512-to-513 index-log boundary in RTL rather than reduced-capacity RTL
   plus production-capacity model.

The prompt does not explicitly require every statistical pattern to run in
RTL, so these are recorded as scope distinctions rather than unconditional
hard stops.

```text
P8_SIMULATION_MATRIX_CURRENT_CLASSIFICATION=
    PASS_COMBINED_CURRENT_RTL_AND_FROZEN_REFERENCE_MODEL

P8_UNCONDITIONAL_MISSING_CASES=
    NONE

P8_LITERAL_AGGREGATE_MARKERS_TO_SEAL=
    PHASE_OPPORTUNITY_BANK_BEFORE_AFTER_TRANSACTION_INDEX_SAFE_RESTORATION

STRICT_ALL_PATTERNS_IN_RTL_CLASSIFICATION=
    CONDITIONAL_GAP_FOUR_PATTERN_CLASSES_AND_PRODUCTION_512_BOUNDARY

BROADER_PREBUILD_STATIC_SHA_REFRESH_REQUIRED=
    YES_BANK_SEMANTICS_AUDIT_A83_TO_CURRENT_A286

SOURCE_COMMIT_GATE_READY_FROM_P8=
    YES_SUBJECT_TO_SELECTED_RTL_VERSUS_MODEL_SCOPE_AND_AGGREGATE_SUMMARY
```
