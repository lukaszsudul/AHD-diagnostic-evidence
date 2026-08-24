# R1f independent pre-build release audit

## Verdict

This is the final independent, read-only release audit of the committed R1f
source candidate against exact R1e base commit
f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd and tree
db8b5581a237e19905fd01c6d453793047bc3ba7. No RTL, source, synthesis,
implementation, route, bitstream, JTAG, SSH, or hardware operation was
performed by this audit.

~~~text
PREBUILD_RELEASE=PASS
SOURCE_COMMIT_GATE=RELEASED
DESIGN_OR_VERIFICATION_BLOCKER=NONE
FULL_BUILDS_CONSUMED_BY_THIS_AUDIT=0

BUILD_INVOCATION_READY_NOW=NO
BUILD_ENTRY_PENDING=
    FINAL_HASH_BOUND_PREBUILD_MANIFEST
~~~

The pending items are sequencing/accounting requirements, not a source or
simulation failure. The one authorized clean build must not be invoked from
the present precommit/dirty worktree.

## Audited candidate identities

~~~text
BRANCH=diag/v41-nvp-r1f-phase-complete-observability
R1F_SOURCE_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1F_SOURCE_TREE=cfde8769af95cf20586391c411fab3ddfa2c87b6
COMMITS_ABOVE_EXACT_R1E_BASE=1
SOURCE_TREE_CLEAN=YES

AUTOINIT_WRAPPER_SHA256=
    FE2C7DF869E23B9440D2F6D1B19808C407F438C861899B319AE4677287C21658
BRINGUP_PRODUCER_SHA256=
    A2865C428B89E9492BB1D62144963558805B036F1A1212C09F968D6059AE9533
TRANSACTION_SERIAL_SHA256=
    FA92E1B52A5BB870EDBEDA5457A7021DB882AE9FF31DF880CBD97A6C7549019E
TRI_PHASE_PROBE_SHA256=
    4AA823B5896D9C11DB9837D1F30E4E077557FE367942B032B404ACBA92E03552
FAILED_TXN_LOGGER_SHA256=
    EFAF862E4267A8AE9A042FFB6B5F074B217CD8D0AD2DD3E4E783BA6F6B7B6C71
R1F_MEASUREMENT_REGS_SHA256=
    BB77188A3A28F34DB3BBC195129A58620D11ECFE4F617528D68002DC1F1FDBFF
CONTROL_STATUS_REGS_SHA256=
    BE70C2707EDAFE075008F9592E474AF1E1658D75A75D5053A1F2FFBD072E44B5
TOP_SHA256=
    CD8E2BB50D89273857168722EDA06F83AE08FA059FCA266522E6D2E3CD2CB77F
R1F_BUILD_TCL_SHA256=
    53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B
~~~

Any change to one of these files invalidates this release and requires a new
read-only audit before the sole build is consumed.

## Functional-change boundary

The exact base-relative production RTL changes are limited to the autoinit
wrapper, bringup producer, top integration, and control/status read decoder,
plus the four new R1f diagnostic components. The autoinit and bringup diffs
retain the inherited functional body; removed inherited lines are port-list or
port-map terminators reintroduced with the new diagnostic outputs. The new
phase counters, failed-record producer, transaction serial, bank invariant
state, logger, and read map observe inherited state and have no fanout into
inherited FSM transitions, byte selection, bank-cache decisions, timeout
thresholds, reset/power, or original SCL/SDA release requests.

The only new electrical master is the expressly authorized active
post-autoinit tri-phase probe. Its physical contribution is open-drain AND
arbitration at top level and is dynamically proven released throughout the
original pre-init interval.

~~~text
NVP_FUNCTIONAL_SOURCE_CHANGE=NO
NVP_DIAGNOSTIC_SOURCE_CHANGE=YES_R1F_ONLY
R1F_PASSIVE_AUTOINIT_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0
R1F_LOGGER_AND_MAP_TO_FUNCTIONAL_FANOUT=0
TRI_PHASE_PROBE_CLASS=ACTIVE_POST_AUTOINIT_DIAGNOSTIC
PRE_INIT_EFFECTIVE_OPEN_DRAIN_ARBITRATION=PASS
~~~

The 16-bit serial is consumed at the inherited START-command attempt edge. In
the intentional stuck-SDA negative case a physical START transition is
impossible, but the attempted transaction remains uniquely diagnosed. That
case must and does trigger invariant predicate 3; it is not a valid-sample
zero-error case. All modeled valid/all-ACK paths require zero invariant errors.

## Protected assets and inherited behavior

Git comparison against the exact base proves these classes remain
byte-identical: the exact NVP operation-table/diagnostics package; R1e
measurement/lifecycle registers; capture, record, physical-frontend and video
sources; PIO slot adapter and BAR target; the exact XDMA XCI; and all seven
production XDC files.

~~~text
NVP_DIAGNOSTICS_TABLE_PACKAGE_SHA256=
    36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156
R1E_MEASUREMENT_REGS_SHA256=
    034F8C63258CA6436817CFFE1605CDF23EF04030047CCE36146E115F3C374939
XDMA_XCI_SHA256=
    EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C
NVP_CONTROL_XDC_SHA256=
    B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318
PINS_XDC_SHA256=
    A8849CD13E75CAB2F509449617440ABE359BAA2B42ACAAE869BA25B581E6F8B9

NVP_TABLE_UNCHANGED=YES
POR_START_WATCHDOG_UNCHANGED=YES
SDA_SCL_FILTERS_UNCHANGED=YES
NVP_XDC_UNCHANGED=YES
XDMA_XCI_UNCHANGED=YES
~~~

The inherited POR, start, watchdog/timeout, and three-sample SCL/SDA filter
lines are retained. Fresh inherited power and D2b simulations pass on the
current source set.

## Register map and write forwarding

The R1f decoder overlays only aligned reads in 0x20A0..0x35FF. The existing
R1e read decoder remains at 0x2000..0x209F, with defined offsets through
0x2094 and reserved zero at 0x2098/0x209C. All writes remain outside both local
read selects and are forwarded unchanged to the inherited PIO invalid-write
accounting path. The R1f map has no write input or functional output.

The preserved R1e page in the R1f image is explicitly a backward-readable
compatibility projection: WADDR counters are projected while start/terminal,
timestamps and low-level timeout status describe the complete tri-phase
setup/probe/restoration lifecycle. R1f scientific conclusions use only the
versioned R1f page. Dynamic byte identity with the old address-only experiment
is neither claimed nor required.

~~~text
R1F_READ_MAP_COLLISION=PASS_NONE
R1E_DEFINED_OFFSETS_AND_DECODER_PRESERVED=YES
R1F_LOCAL_WRITE_SELECT=NO
R1F_FIELD_MUTATION_FROM_WRITE=NONE
PRIOR_INVALID_WRITE_ACCOUNTING=PRESERVED_BY_FORWARDING
FORMAL_PHASE2_R1F_RANGE_ZERO=PASS_EXACT_SOURCE_PROOF
MAP_AND_TOP_PACKING_STATIC_AUDIT=PASS
~~~

The final current top packed-status wiring was inspected field by field and
matches the normative map. A dedicated dynamic top-packing fixture is not
present; this is not a prompt-required gate because exact mapping is covered
by static wiring audit, focused producer/probe tests, exhaustive map decode,
and fresh complete-top elaboration.

## Fresh evidence binding

| Gate | SHA-256 | Result |
|---|---|---|
| Production 62.5 MHz / 25 kHz pre-init equivalence | F3D061279980639F3A547413A9526FED08B3184DAA363CE5AF8D9D0E3118F729 | PASS |
| Effective pre-init open-drain arbitration | DE0E9F7951DEE936FBF48D39D1144510D7D9E21D269FFF16AA65A0B750A1D864 | PASS |
| Integrated phase/bank/record matrix | EC8FA7BF2B49097B584658CE89869F37EDEED462A5DE5B81ECD2BF6F00847961 | PASS |
| Exact serial counter through index 300 | 4BEAD247C1250852226B72091E6392E17BD6B4231DD4FDB29A3FBA3313592DCB | PASS |
| Failed logger 64/65 boundary | B209D3AC8DA34F67F3612DD4AD2A1F4A2D4E23EAF4FBEA9FAA8E1C6B74F3EA6B | PASS |
| Exhaustive R1f map fixture | 02D4A9605063D83883930E1E73793740111EF8FDE5E8F203379120845B7A03F9 | PASS |
| Final complete-top elaboration | 9E88A0277C3F550AFA317BEF23D805508766C2EFF370C84BD8CE47D08933C893 | PASS |
| Inherited power/POR timing | 369360840D6F0162F8C56889E2C1ECB1D138231AA84176B4DC078C4CFB4B6D69 | PASS |
| Inherited D2b sequence | 49F5243F4F6ECC81FC539764322BFB844291703461CF6B88EEC61FF57553D9DA | PASS |
| Production probe timing model | 06D6D00BDF6F23D6AA6479B9D688437D9DD4F2B76D01AB9984229DBF8D32923B | PASS |
| Host-tool fixture report | 186889F2353BCAC7BFFD71C163408403274EC1F7F4C305067B938F02A90C4368 | PASS_ALL_16 |

The final-current tri-phase suite is 7/7 PASS. Its seven raw log hashes are
recorded in 06_SIMULATION/R1F_TRI_PHASE_PROBE_FINAL_CURRENT_GATE.md.

The integrated matrix covers all-ACK autoinit; isolated WADDR, REGADDR, DATA
and RADDR NACKs; multi-phase failure; all transaction kinds; bank selection
success/failure; verify success, mismatch and transport NACK; operation-86-like
context; exact 13/15/36 historical patterns; and legacy first-eight
reconciliation. The logger separately proves 64/65 behavior and the exact
serial component separately proves unique index 300.

Large statistical probe patterns (exact 29/10000, independent Bernoulli and
clustered patterns) execute in the frozen reference model; focused current RTL
tests prove physical phase reachability, prerequisite suppression, target
counting, restoration, timeout and index-overflow mechanics. This combined
RTL/model coverage satisfies the predeclared matrix; it is not mislabeled as
all-pattern RTL coverage.

~~~text
PRE_INIT_DONE_CYCLE_EQUIVALENCE=PASS
AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
AUTOINIT_FUNCTIONAL_STATE_SEQUENCE_IDENTICAL=YES
PHASE_OPPORTUNITY_COUNTERS_MATCH_SCOREBOARD=PASS
FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD=PASS
BANK_BEFORE_AFTER_SEMANTICS=PASS
TRANSACTION_INDEX_16_UNIQUE=PASS
LEGACY_FIRST8_RECONCILIATION=PASS
TRI_PHASE_PROBE_SCOREBOARD=PASS_COMBINED_CURRENT_RTL_AND_FROZEN_MODEL
SAFE_TARGET_RESTORATION=PASS
~~~

The production timing model freezes probe completion at 29.415318 seconds
after original init_done, 31.536673744 seconds from configuration, and the
Arm-A minimum wait at 33.536673744 seconds.

## Dedicated one-build flow

The frozen build script at SHA-256
53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B is
syntactically complete and independently audited. It includes every exact
production source, the four R1f modules in dependency-safe order, exact XCI
and seven XDCs, exact part/top/generics, source-commit provenance, all prebuild
log/meta gates, and a pre-create-project atomic consumption sentinel. It has
exactly one create/synthesis/opt/place/phys-opt/route/bitstream command, no
retry/run-reset/checkpoint-input/programming path, and emits the bit only after
all implementation gates pass.

The repository-owned XDMA helper is not sourced until Git identity,
one-commit lineage, clean-tree, manifest, source hashes and accepted-log hashes
pass. Full details are in R1F_BUILD_SCRIPT_STATIC_AUDIT.md.

## Procedural conditions before invoking Vivado

The single authorized R1f source commit now exists at
225544084dbfcaadb8592fcecc947aa1cec4970e with tree
cfde8769af95cf20586391c411fab3ddfa2c87b6. It is exactly one commit above the
R1e base. Git status with all untracked files enabled is empty.

The earlier committable/untracked simulator artifacts were removed. A physical
source-root xsim.dir still contains twelve log-only remnants ignored by the
pre-existing *.log rule; none is tracked, appears in Git status, enters the
source commit, or can enter the required source manifest. This is not a dirty-
tree or source-identity exception.

Before the one build, create and hash the final prebuild manifest binding the
exact commit/tree above, every required source, all required META gates and
accepted logs. Then recheck that Git status remains completely clean and pass
the commit, tree, manifest path and manifest SHA-256 to the one-build script.

No source correction is authorized after the build. A failure after sentinel
creation consumes the sole build and is terminal.

~~~text
PREBUILD_RELEASE=PASS
SOURCE_COMMIT_GATE=PASS
SOURCE_TREE_CLEAN_GATE=PASS
NEXT_AUTHORIZED_ACTION=CREATE_AND_VERIFY_FINAL_HASH_BOUND_PREBUILD_MANIFEST
ONE_CLEAN_BUILD_MAY_RUN_AFTER_COMMIT_CLEAN_MANIFEST_GATES=YES
~~~
