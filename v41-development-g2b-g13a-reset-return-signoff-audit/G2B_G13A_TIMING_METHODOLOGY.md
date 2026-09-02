# AHD v41 G2B-G13-A — Timing Methodology

## Prohibited query and accepted timeout

The predecessor's full Group-13 command was:

```tcl
report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 -warn_on_violation
```

Its external watchdog measured `301.094 s` from `QUERY_STARTED.marker` and
terminated the process. `QUERY_COMPLETED.marker` and a bus-skew report are
absent. This audit did not retry that query and did not run any other
`report_bus_skew` experiment.

## Focused methodology warnings

The authoritative already-run focused report is
`../v41-development-g2b-lut1-signoff-recovery/raw/group9_fresh/G2B_BS3_FULL_CONTEXT_TIMING_METHODOLOGY.rpt`
at evidence commit `765f5a5d4760f7a685447651dc68179b2fd96846`
(SHA-256
`5C7C43BDD284E7AD54E714270DEEAC548C8C96610C3D5F31FEC43BCDE3533C62`).
Its command explicitly ran all five requested checks.

| Check | State | Group-13 relevance |
|---|---|---|
| `TIMING-32` | `ABSENT` | No finding for the scoped constraints |
| `TIMING-34` | `PRESENT` | Finding #15 identifies Group 13: the 3 ns value is aggressive relative to the shorter clock period; first endpoint `axi_hard_episode_reg/D` |
| `TIMING-37` | `ABSENT` | No finding for the scoped constraints |
| `TIMING-38` | `ABSENT` | No finding for the scoped constraints |
| `TIMING-39` | `PRESENT` | Finding #6 identifies Group 13: the relation spans more than one logic level and the same reconvergent endpoint cone |

The warnings agree with the semantic diagnosis: the relation compares logic
cones rather than a compact first-stage coherent bus.

## Alternative query A — exact-scope `report_timing`

```tcl
report_timing -delay_type max -max_paths 1 -nworst 1 \
  -from $g2b_g13a_all_sources -to $g2b_g13a_original_destinations
```

External timeout is `300 s` from an explicit stage marker. The command is a
max/setup-style datapath query. It does not create a hold requirement; hold is
not the stable-mailbox safety property and remains covered by later general
routed hold sign-off. It ran in the predecessor bus-skew-free query context,
not the later full preserved candidate context.

`REPORT_TIMING_RESULT = PASS`

`REPORT_TIMING_ELAPSED_SECONDS = 56.827`

`REPORT_TIMING_PATH_COUNT = 1`

`REPORT_TIMING_WORST_DATAPATH_NS = 3.756`

The returned path is in `nvp_vclk1` to `userclk1` context, has `1.723 ns`
slack against the existing `6.000 ns` datapath-only max-delay relation, and
ends at `reset_events_axi_reg[21]/R` after five logic levels. This is max/setup
analysis under a max-delay exception; hold was not requested by this scoped
query and remains a later general routed hard gate.

`REPORT_TIMING_WARNINGS = NONE_IN_REPORT`

The Vivado transcript has a benign duplicate installed-strategy warning and a
later file-already-in-project message during context loading; neither is in the
timing report or changes its path result.

## Alternative query B — bounded `get_timing_paths`

```tcl
get_timing_paths -delay_type max -max_paths 64 -nworst 7 \
  -from $g2b_g13a_all_sources -to $g2b_g13a_original_destinations
```

The output is hard-capped at 64 objects. Path properties are serialized
dynamically, including startpoint, endpoint, clocks, datapath/arrival delay,
slack, requirement, path group, and logic levels where available. Like query
A, it ran in the predecessor bus-skew-free query context.

`GET_TIMING_PATHS_RESULT = PASS`

`GET_TIMING_PATHS_ELAPSED_SECONDS = 0.185`

`GET_TIMING_PATHS_COUNT = 64`

`GET_TIMING_PATHS_SOURCE_DIVERSITY = 1`

`GET_TIMING_PATHS_DESTINATION_DIVERSITY = 16`

All 64 returned paths are `nvp_vclk1` to `userclk1`. The worst-slack path is
the same `3.756 ns` path reported above; the maximum datapath delay anywhere in
the bounded 64-path set is `3.934 ns`. Dynamic properties are retained in the
raw path-properties CSV.

## Candidate validation

The combined applied context replaces exactly the Group-13 `set_bus_skew`
relation relative to the preserved recovery context. Its derived base omits
Groups 9 and 13, then reapplies the unchanged promoted Group-9 candidate and
the temporary Group-13 candidate. The latter adds two explicit cell-scoped
`6.000 ns` family settling checks, covering all timing endpoint pins on the
selected cells. The
unchanged aggregate source-mailbox `6.000 ns` max-delay constraint remains in
force and covers the broader fanout. Validation asserts all 7 original source
cells and all 207 original destination cells are members of that aggregate,
then separately checks aggregate-only transport-follow-up, commit-FIFO, and
shadow-state completion fanout. Groups 10–12 and 14–17 retain their existing
bus-skew command lines. No bus-skew report is invoked during validation.

This is a different, explicitly preserved context from A/B: the derived full
base retains Groups 10–12 and 14–17 while omitting Groups 9 and 13, then the
promoted Group-9 candidate and temporary Group-13 candidate are applied. The
expected applied inventory is 15 `set_bus_skew`, 14 `set_max_delay`, and zero
Group-13 bus-skew relations.

Attempt 1 completed both required alternative queries, then stopped before any
candidate query because a harness membership assertion applied `get_property`
to literal cell-name lists emitted by `write_xdc`. The candidate-only
continuation resolves those exact aggregate source and destination names with
`get_cells`, re-verifies counts/hashes/context, and does not repeat either
alternative query. Both attempts and the object-resolution-only fix are
retained as evidence.

`CANDIDATE_VALIDATION_RESULT = PASS`

`SIGNOFF_RUNTIME = PRACTICAL`

The two semantic-family checks and supplemental aggregate check total
`81.827 s`; including focused methodology, replacement-specific active-query
runtime is `105.521 s`. The candidate-only cold routed session was `998.405 s`
because it reopened the DCP and reconstructed the full context. That common
setup would be `MARGINAL` in a standalone fresh process but is not assigned to
the replacement primitive in the governed continuation session. No active
query exceeded `76.881 s` or approached its `300 s` bound.

Focused candidate-context methodology completed in `23.694 s`, reported 20
design-level findings and zero Group-13 object mentions. The authoritative
original-context mapping above remains the basis for the requested Group-13
`TIMING-34` and `TIMING-39` dispositions.
