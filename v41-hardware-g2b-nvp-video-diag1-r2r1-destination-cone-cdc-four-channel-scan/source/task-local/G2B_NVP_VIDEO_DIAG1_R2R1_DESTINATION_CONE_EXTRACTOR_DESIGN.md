# G2B-NVP-VIDEO-DIAG1-R2R1 deterministic two-DCP cone extractor

Status: design only; Vivado was not launched by this review.

## Authority and process isolation

Invoke one fixed worker in two separate Vivado 2025.2 operating-system
processes, serially:

1. `PRODUCT` opens only
   `C:/FPGA/G2B_BT656_FIX1_R1_20260909T090813Z/artifacts/offline-candidate/G2B_BT656_FIX1_R1_SIGNED_OFF_ROUTED.dcp`, SHA-256
   `5284A91C8D106A14E35A4DCB7A33EC4527A325D3D0F4F9333E6BB73C57255A82`.
2. `DIAGNOSTIC` opens only
   `C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp`, SHA-256
   `45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F`.

Require `PART=xc7a35tcsg325-2`, `TOP=ahd_capture_top_xdma`, the matching
CDC-1 physical-manifest SHA
(`A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D`
PRODUCT,
`BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99`
DIAGNOSTIC), a fresh empty profile output directory, and unchanged DCP
hash/size/mtime after `close_design`. The worker contains no constraint,
implementation, checkpoint-write, or bitstream-write command.

The external controller must use separate initialization and cone-command
watchdogs. Write and flush `CONE_QUERY_STARTED=<RowID>` immediately before an
`all_fanin` query and `CONE_QUERY_FINISHED=<RowID>` after all row outputs are
durable. A practical bound is 20 minutes for process/open/report initialization,
120 seconds without row progress, and 90 minutes total per profile. A timeout
is `BLOCKED -- NVP_DIAG1_R2R1_CONE_QUERY_TIMEOUT`, never CDC mismatch evidence.

## Frozen row authority

Pin and verify the exact R2 reconciliation inputs before transforming them:

- critical CSV SHA-256:
  `7E60B4855BD2A1D578A8D03E49806A6BDC0806DAEAAB0A490A95F3C8714B4148`;
- warning CSV SHA-256:
  `5A1B267ED3EDA48D0A8DB545DE47DF8E8C83634D4AE7674991F7EE69A078945E`.

After the authority-only transformation, pin the worker inputs too:

- `changed_destinations.tsv` SHA-256:
  `D8FAD3132ADECCDBAFD8189297617D9FC45F79382C07F16EB01208BF82A766B2`;
- `changed_destination_contract.json` SHA-256:
  `0F82AD1374F54D8416BF313AB0358EC5557B262E3AEB87E26F61815A70D7FC2F`.

The canonical changed-row input must assert:

- 302 critical plus 220 warning rows;
- 522 unique RowIDs and 522 unique destination pins;
- terminal-pin distribution `CE=265`, `D=226`, `R=31`;
- clock-pair distribution `nvp_vclk1->userclk1=502`,
  `userclk1->nvp_vclk1=20`;
- every PRODUCT and diagnostic report representative terminates in `/C`.

Do not hard-code a D-only destination query.

## Exact Tcl object resolution

Use an escaping helper and an anchored full-name query; never a substring or
unanchored destination match:

```tcl
proc re_quote {value} {
  regsub -all {[][(){}.^$*+?|\\]} $value {\\&} value
  return $value
}

proc exact_pin {name} {
  set objects [get_pins -quiet -hier -regexp "^[re_quote $name]$"]
  if {[llength $objects] != 1} {
    error "exact pin resolution failed: name=$name count=[llength $objects]"
  }
  return [lindex $objects 0]
}

set destination_pin [exact_pin $DestinationPin]
set destination_cells [get_cells -quiet -of_objects $destination_pin]
if {[llength $destination_cells] != 1} {
  error "destination owner multiplicity drift: $RowID"
}
set destination_cell [lindex $destination_cells 0]
if {[get_property IS_SEQUENTIAL $destination_cell] ni {1 TRUE true}} {
  error "destination owner is not sequential: $RowID"
}
set destination_clock_pins [get_pins -quiet -of_objects $destination_cell \
  -filter {IS_CLOCK == 1}]
set destination_clocks [lsort -dictionary -unique \
  [get_property NAME [get_clocks -quiet -of_objects $destination_clock_pins]]]
if {[llength $destination_clocks] != 1 ||
    [lindex $destination_clocks 0] ne $ExpectedDestinationClock} {
  error "destination clock drift: $RowID"
}
```

Resolve the selected `report_cdc` representative `/C` independently, map it
to its one sequential owner cell, verify its source clock, and later require
that owner cell in the destination startpoint-cell collection. A `/C` report
representative is not the same object as a fan-in Q/startpoint pin.

## Complete bounded cone query

For every exact CE, D, or R endpoint:

```tcl
set startpoint_cells [all_fanin -quiet -flat -startpoints_only -only_cells \
  -to $destination_pin]
set cone_cells [all_fanin -quiet -flat -only_cells -to $destination_pin]
```

Require a nonempty unique startpoint collection, all startpoint cells included
in the full cone collection, and both counts no greater than the exact design
cell count. This is a fail-closed cap, not a result truncation option. Sort
objects by `NAME` before emitting them. The successful diagnostic pilot for
`enable_applied_source_reg/D` returned 633 startpoint cells.

For each startpoint cell, resolve clock pins as above. Classify exactly:

- one clock equal to destination clock: `LOCAL_SAME_CLOCK`;
- one different clock: `CROSS_CLOCK`, requiring exactly one semantic rule;
- `REF_NAME` exactly `GND` or `VCC`: `STATIC_LOCAL`;
- zero or multiple clocks, any other nonsequential source, or a primary port:
  fail as unresolved asynchronous provenance.

Record local controls but do not put them in the cross-clock support set.

For each semantic atom, use one targeted timing query only to record the
effective exception; it is not the source-coverage proof:

```tcl
set paths [get_timing_paths -quiet -delay_type max -sort_by slack \
  -max_paths 1 -nworst 1 -from $atom_startpoint_cells -to $destination_pin]
if {[llength $paths] != 1} {
  error "exception path multiplicity drift: $RowID atom=$atom"
}
set path [lindex $paths 0]
if {[get_property ENDPOINT_PIN $path] ne [get_property NAME $destination_pin]} {
  error "exception query reached another endpoint: $RowID atom=$atom"
}
```

Capture `EXCEPTION`, `REQUIREMENT`, `DATAPATH_DELAY`, source/destination
clocks, and start/end pins. The expected exception class is
`Max Delay Datapath Only`; compare its numeric requirement between profiles.

## Exact family classifier

Classification is an offline Python `fullmatch`, or equivalent anchored Tcl
regular expression, over the complete cell name. Never strip a suffix and
never infer a family from a terminal bit index. Each cross-clock startpoint
must match exactly one rule.

The canonical support-atom identity is:

```text
(LeafFamily, ParentFamily, Slot, Field, SourceClock, UseRole)
```

Metadata compared exactly alongside that identity is:

```text
StartpointRole, GoverningToken, Protocol, EarliestUseBarrier,
ReplacementGroup, ExceptionClass, ExceptionRequirement
```

Use separate explicit rules for every physical base/alias. The canonical leaf
families are `RESET_COMMIT_STABLE_PAYLOAD`,
`RESET_ABANDONED_COUNT_STABLE_PAYLOAD`,
`DESCRIPTOR_EPOCH_STABLE_PAYLOAD`, `OWNERSHIP_STABLE_PAYLOAD`,
`RELEASE_GENERATION_FIELD`, and `RELEASE_EPOCH_FIELD`; release alone has the
parent `RELEASE_TOKEN_STABLE_PAYLOAD`. In particular:

- `reset_commit_phase_hold_source_reg`;
- `reset_abandoned_hold_source_reg`;
- `desc_attempt_source_reg`, `desc_generation_source_reg`,
  `desc_epoch_source_reg`;
- `own_ok_hold_source_reg`;
- `enable_value_hold_axi_reg`;
- `transport_epoch_hold_axi_reg`, `transport_hard_hold_axi_reg`,
  `transport_release_phase_hold_axi_reg`,
  `transport_own_phase_hold_axi_reg`;
- `snapshot_epoch_hold_axi_reg`;
- each ownership child with separately enumerated legal physical aliases:
  `own_slot_hold_axi_reg` or `axis_slot_reg`,
  `own_generation_hold_axi_reg` or `axis_generation_reg`,
  `own_epoch_hold_axi_reg` or `axis_epoch_reg`;
- `release_generation_axi_reg[slot][bit]` as leaf
  `RELEASE_GENERATION_FIELD`;
- `release_epoch_axi_reg[slot][bit]` as leaf `RELEASE_EPOCH_FIELD`.

The ownership aliases all remain one leaf family,
`OWNERSHIP_STABLE_PAYLOAD`, but preserve `Field=SLOT`,
`Field=GENERATION`, and `Field=EPOCH`; a slot hit cannot mask a missing
generation or epoch child. The release parent whitelist contains only
`release_generation_axi_reg` and `release_epoch_axi_reg` members.

The two release leaves have parent `RELEASE_TOKEN_STABLE_PAYLOAD`. They never
become the same leaf family. Ownership has no release-token parent.

Roles are `PAYLOAD`, `GOVERNING_TOKEN_CONTROL`, and `LOCAL_SAME_CLOCK`.
Physical members are retained in sorted arrays, but physical multiplicity is
not part of semantic equivalence. Every atom must have at least one physical
member in each DCP.

## Token/control evidence

Attach protocol metadata from explicit, separately resolved structures. At
minimum assert exact cell multiplicities, source/destination clocks, and
`ASYNC_REG=TRUE` on every sync1/sync2 stage for:

- ownership request/ack:
  `own_req_toggle_axi -> own_req_sync1_source -> own_req_sync2_source`,
  `own_ack_toggle_source -> own_ack_sync1_axi -> own_ack_sync2_axi`;
- release slots 0..3:
  `release_toggle_axi[slot] -> release_sync1_source[slot] ->
  release_sync2_source[slot]`, plus `release_seen_source[slot]`;
- transport request/ack:
  `transport_req_toggle_axi -> transport_req_sync1_source ->
  transport_req_sync2_source`, and the reverse acknowledgement chain.

For reset-overlap destinations, preserve `UseRole` distinctions:

- `transport_req_sync2_source` is the semantic-use trigger;
- captured transport release phase plus synchronized release phase is the
  retirement barrier;
- ordinary release uses the per-slot release-toggle sync2 request.

Thus release `NORMAL`/`MISMATCH` use records bind to `release_sync2`, while
`RESET_OVERLAP` binds to `transport_req_sync2` and separately records its
phase-retirement metadata. An otherwise classified payload with the wrong use
role is not semantically equal.

## Cross-profile and row-class gates

Compare sorted support atoms and all metadata exactly. Physical source names
and multiplicities may differ. Any new/missing atom, slot, child field, token,
protocol, clock, exception, barrier, or replacement group is a real FAIL.

For all seven critical cross-family rows require both ownership and release
support. Ownership must contain SLOT, GENERATION, and EPOCH children. Each
actual release slot must contain both GENERATION and EPOCH children. Preserve
the exact extracted slot set rather than forcing a guessed set.

For each of the three composite warning rows require in both DCPs:

- slots 0..3 x release GENERATION and EPOCH child fields;
- all four ordinary release toggle/sync2 controls;
- all four captured transport release-phase fields;
- transport-request sync2 semantic-use trigger;
- captured/synchronized release-phase retirement barrier;
- slot-state qualification for all four slots;
- Group 13 and Groups 14--17 authority metadata.

The three rows use only `COMPOSITE_RELEASE_TOKEN_EQUIVALENCE`. The seven use
only `DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE`.

## Diagnostic-tap noninterference

In the diagnostic DCP resolve the four exact hierarchical output pins:

```tcl
set tap_pins [get_pins -quiet -hier -regexp \
  {^G2B_ONECH_C2H/diag_(stored_enable|c2h_active|ring_empty|ring_full)$}]
if {[llength $tap_pins] != 4} {
  error "diagnostic tap pin multiplicity drift: [llength $tap_pins]"
}
foreach tap $tap_pins {
  set endpoints [all_fanout -quiet -flat -endpoints_only -only_cells -from $tap]
  if {[llength $endpoints] == 0} { error "tap has no physical consumer: $tap" }
  foreach endpoint $endpoints {
    if {[regexp {^G2B_ONECH_C2H/} [get_property NAME $endpoint]]} {
      error "diagnostic tap feeds back into G2B: $tap -> $endpoint"
    }
  }
}
```

Also require zero cells from the diagnostic core/I2C hierarchy in every one of
the 522 `cone_cells` collections. If the exact four hierarchical tap pins do
not survive in the routed DCP, stop; do not infer four proofs from a partial set
of optimized net aliases.

## Outputs

Each profile writes only its own fresh directory:

- `DESTINATION_STARTPOINT_INVENTORY.csv`: one row per destination/startpoint;
- `DESTINATION_EXTRACTION_SUMMARY.csv`: exactly 522 rows;
- `DIAGNOSTIC_TAP_FANOUT.csv`: four exact tap rows in both profiles (the
  PRODUCT rows prove absence);
- `EXTRACTION_RECEIPT.txt` with all identities, counts, hashes and read-only
  invariants.

The offline comparer writes the exact 23-column
`G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_SUPPORT.csv`. List-valued cells are
canonical JSON arrays. Because the mandated CSV omits clocks, token drift,
unclassified sources, and local controls, each `EvidencePath` points to a
companion per-row JSON record containing those fields. Generate the seven
critical reports separately and the three reset-abandoned proofs as their own
grouped report; never extrapolate one destination to another.

The comparer additionally writes
`G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_EVIDENCE_SHA256.txt`, containing 522
contract-ordered `RowID=EvidencePath|SHA256` bindings, and a final
`G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_COMPARER_RECEIPT.json` that hashes
the support CSV, the evidence-hash manifest, and the unclassified-startpoint
CSV. Existing comparer-owned paths are a hard stop; unrelated governed files
already present in `cdc/` are not overwritten.

The final V2 manifest is admitted only at exactly 1,337 rows with proof-class
counts `815/512/7/3` in contract order: unchanged, same-family changed,
destination-cone, composite-release-token.

Any missing/extra/duplicate row, unresolved object, unclassified cross-clock
source, unknown clock or port, diagnostic hierarchy in a G2B fan-in cone,
representative absent from its cone, support/token/protocol/exception/barrier/
group drift, or watchdog expiry stops before sign-off.
