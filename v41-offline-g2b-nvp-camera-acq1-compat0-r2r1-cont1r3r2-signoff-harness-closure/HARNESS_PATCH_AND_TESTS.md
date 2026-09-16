# Task-local sign-off comparator correction and tests

The executed first-attempt `cont1r3r1_full_signoff.tcl`, whose Tcl command
echo survives in `cont1r3r1_full_signoff.log`, compared a pre-isolation
as-open B XDC signature with a post-isolation, `reset_timing`/`read_xdc`
restored A signature at its `require_same_signatures` call. The current
same-named `.tcl` was edited after that run and must not be assigned to it
by hash; the executed version's file SHA-256 is unavailable. The third
finalizer compared restored analysis-view A with final-checkpoint as-open B.
Both calls assumed a common view provenance without recording one. The
historic version-2 finalizer file was overwritten by version 3; its call
sequence survives in the Vivado log, but its original file SHA-256 is
unavailable and is not fabricated.

The correction is task-local and leaves all old source/worktrees/checkpoints
untouched. `compare_xdc_views.py` expands only Vivado-generated read-only
`_xlnx_shared_iN` selectors and compares the exact ordered executable
constraint stream. It retains the A/B raw hashes and exposes the first
meaningful difference. `compare_report_bodies.py` records raw hashes, checks
identical report commands/options and excludes only the exact generated
`Date` and output-path `Command` header fields from body comparison. It
does not remove warnings, data lines or the methodology-cache section.
`collect_as_open.tcl` and `collect_methodology_timing.tcl` open exact copies
without loading or resetting constraints, then check pre/post report
signatures. `collect_physical_identity.tcl` queries full XDC and route
properties without DCP writes. `validate_authority.py` checks original and
copy hashes/sizes, sealed source Git identity and exact Vivado build.

Frozen A/B raw hashes differ but the 97 expanded executable command lines
are identical, SHA-256
`12A2080ADB2957FB48F56433830CC64FB92B328BA0156B357ECA0DAB8F36DE50`.
The original routed and final provisional as-open XDC both yield B. Six
report families are accounted for individually in `REPORT_COMPARISON.csv`;
the historically expensive global bus-skew query is linked through exact
design and per-net route identity to the 11/11 source-DCP group receipt,
not silently treated as freshly rerun.

Focused tests:

- C1–C10 XDC comparison contract: **10/10 PASS**. An initial test fixture
  accidentally moved an alias use before its definition and produced a
  fail-closed exception; the fixture was corrected to treat that exception
  as rejection. No candidate or XDC was changed.
- Exact report-header/warning mutation tests: **4/4 PASS**.
- Wrong/empty/stale artifact and wrong Vivado build tests: **3/3 PASS**.
- Real exact authority check: PASS for source commit/tree/branch/clean tracked
  worktree, both original and copied DCP bytes, and Vivado 2025.2 build
  6299465.

No build, bitstream, hardware, SSOT write, source edit, implicit candidate
constraint load or old wrapper execution is present in the corrected path.
The original full historical harness remains private and unchanged; the new
project-owned comparator/collector files are published as supporting source.
