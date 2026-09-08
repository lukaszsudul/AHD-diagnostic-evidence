
# Minimal diagnostic plan

Type: `RAW_MARKER_FRAME_BOUNDARY_TRACE`

The current PRODUCT bitstream is **not sufficient**: it reports cumulative
malformed/drop snapshots in committed records but has no raw marker/state trace
for the missing interval.

## Exact bounded observability

Add one source-clock-domain, marker-event trace FIFO for one frame boundary.
Each entry records only protocol/control metadata, never active-line payload:

- four raw marker bytes (`marker_p0`, `marker_p1`, `marker_p2`, current XY);
- qualified-marker valid and decoded F/V/H;
- source state before/after (`SRC_IDLE`, `SRC_CAPTURE`, `SRC_WAIT_EAV`, header,
  commit);
- `previous_sav_v`;
- `source_locked_source` before/after;
- `source_frame_sequence`, `source_line_sequence`, `next_source_line`;
- `pending_frame`, `pending_line`;
- `monitor_has_attempt`, allocation-valid/choice, `monitor_writes_slot`;
- malformed increment pulse and cumulative malformed value;
- source-drop increment pulse and cumulative dropped value;
- commit pulse and composed flags;
- source-clock delta from the previous trace entry.

## Trigger and window

- arm while the parser completes a valid EAV for source line 1079;
- pretrigger: the line-1079 SAV/EAV entries;
- capture the next 256 qualified-marker/malformed/commit events;
- stop after the first committed next-frame line 1, or after a bounded 300,000
  source clocks (about 2.02 ms at 148.5 MHz), whichever comes first;
- run exactly one boundary, not another 2500-record or continuous campaign.

## Decision mapping

- H1 contribution: raw line-0 SAV has V=0 with lock=0 and
  `monitor_has_attempt=0`, then valid EAV relocks before line 1.
- H2: each of the 21 malformed pulses maps to an early marker, invalid EAV, or
  missing-EAV timeout during the boundary interval.
- H3: correct raw V transition but internal observed/next line skips or
  mislabels line 0.
- H4: stable raw F/V/H/XY sequence conflicts with the parser's programmed-mode
  assumption.
- H5/timing reopen: raw marker bytes or parity vary inconsistently across
  otherwise identical boundaries after H1-H4 are resolved.

This is shorter and more discriminating than a new finite capture. It must be
authorized as a separate diagnostic bitstream task; none was generated here.
