# RM1 one-shot offline build/finalizer harness

Status: prepared and statically checked only. It has not been launched by
ADVANCE1 Workstream A. It never contacts the DUT.

The harness is split deliberately:

1. `g2b_nvp_diag2_rm1_build.tcl` performs one fresh nonincremental
   synth/opt/place/phys-opt/route and writes reports plus a routed handoff DCP.
   It has no executable `write_bitstream` command.
2. `g2b_nvp_diag2_rm1_finalize.tcl` reopens that exact DCP, independently
   verifies source, route, timing, resource, and profile identity, then writes
   exactly one signed-off DCP and one bitstream into a fresh artifact root.
3. `invoke_rm1_one_shot_build.ps1` invokes those two stages serially with one
   Vivado process at a time and a task-local temporary directory.

The build requires a future clean committed RM1 source identity. It rejects a
dirty worktree, the wrong branch, anything other than one direct child of
`fc37d815...`, stale focused/affected-regression receipts, or drift in the
accepted XDMA inputs. The parent-to-candidate name/status diff must be exactly
the governed eleven paths: two modified RTL files and nine added RM1 RTL,
test/checker, runner, and XDC files. Rename/copy records, a missing path, an
extra path, a noncanonical path, or a status mismatch fail before Vivado.
Copy detection uses the harder unchanged-source scan as well as rename/copy
detection, so an added governed file copied from a parent blob is also rejected.
Before the first Vivado process it also requires the exact RM1 origin branch to
resolve to the requested commit, validates a commit-pinned publication/blob
readback receipt, and binds every focused `HashAfter` plus affected-regression
`InputHashes` entry to current committed bytes. The full harness set, including
the finalizer and launcher, is hashed into the build-input seal; the finalizer
self-verifies all nine harness component hashes at entry, before output
generation, and again after the single DCP/bitstream write sequence.

The binder captures each focused, affected-R3, and publication receipt
exactly once as a byte array. Its retained SHA-256, strict UTF-8 decoding, JSON parsing,
and all semantic validation therefore refer to the same byte snapshot. After
serializing the prospective binding in memory, the binder rehashes all three
live paths and requires equality with those retained validated hashes
immediately before a `CreateNew` output write. The static gate deterministically
swaps each receipt in that boundary and requires all three cases to fail closed.
All receipt/authority path sets use Windows case-insensitive uniqueness. The
binder and launcher use ordinal case-insensitive sets; build and finalizer also
normalize and case-fold their exact 14/6 authority sets (and the finalizer's
nine harness paths). Case-varied aliases to one omnibus file fail closed in
both binder and pre-Vivado-seal semantic tests.

Immediately after binding, the launcher persists a 14-entry pre-Vivado seal:
the exact normalized path and SHA-256 of focused, affected-R3, binding, and
publication receipts, the immutable executable R3 donor Tcl, plus all nine
harness files. It rechecks this seal before each Vivado process and passes the
seal SHA plus all four receipt SHAs into the build Tcl as immutable command-line
authority. The build validates the exact 14-entry set and the donor's fixed
SHA-256 both before and after importing its procedures, before accepting receipt
contents or creating build outputs, then
strictly parses the binding receipt and compares all three bound source receipt
paths and hashes to the current focused, affected-R3, and publication files.
The routed handoff carries these identities into the build manifest. The
launcher pins the routed handoff SHA for the finalizer, which independently
rechecks the same six authority files (pre-Vivado seal, four receipts, and the
R3 donor) against the immutable manifest before and during final output
generation.

Exact profile:

```text
ENABLE_NVP_VIDEO_DIAG2_RM1=1
ENABLE_NVP_VIDEO_DIAGNOSTIC=0
ENABLE_RTRACK_DIAGNOSTICS=0
BUILD_FLAGS=0x00000802
```

The source list adds the fixed I2C master, RM1 route controller, RM1 raw-marker
monitor and RM1 wrapper before the top. The RM1 XDC is included exactly once.
SCAN1, ACQ1 and MODE1 source files are absent. Post-synth, post-opt, routed and
finalizer gates require RM1 controller/monitor/BRAM/fixed-master presence and
R3/R-track/history/scanner/ACQ/MODE1 absence.

Hard gates include fully routed timing, WNS/WHS nonnegative, and TNS/THS
derived as zero only after the respective negative-path query is empty. Both
the build and finalizer generate and parse a timing summary with
`-report_unconstrained` plus a standalone verbose `check_timing` report. Every
one of the twelve check categories must be present twice and consistent;
`no_clock`, `constant_clock`, `unconstrained_internal_endpoints`,
`no_input_delay`, `no_output_delay`, `multiple_clock`, `generated_clocks`,
`loops`, `partial_input_delay`, `partial_output_delay`, and `latch_loops` must be raw zero;
the known pulse-width category is exactly two. The raw
Unconstrained Path Table must be empty. There is no post-hoc I/O disposition
and this harness adds no input/output delay, clock, or control-port false-path
constraint; a future 3/3/3 raw signature honestly fails the build.

The RM1 XDC itself fails unless it resolves exactly 12 one-bit synchronizer
cells/D pins and 21 mailbox cells/D pins (16 session, 3 route, 2 window).
Build and finalizer independently require the exact 12 `CDC-3`/`Info` and 21
`CDC-15`/`Warning` source-to-destination tuples, each with Vivado exception
`False Path`, exact multiplicity one, and no unmatched critical or warning.
The finalizer regenerates CDC, unconstrained, DRC, and methodology reports from
the reopened DCP; it does not trust only the build handoff. Other hard gates
include inherited bus-skew `11/11`, promoted replacements `17/17`, DRC and
methodology PASS (unknown or unrecognized severities fail), and LUT at most `20384/20800`
(`98%`), and the preferred advisory target at most `19760/20800` (`95%`).
The R3 LUT-reduction-vs-DIAG1 condition is intentionally not inherited.

Future invocation shape (do not run until the RM1 branch is committed and the
Owner authorizes the full build):

```powershell
& '<this-directory>\invoke_rm1_one_shot_build.ps1' `
  -RepoRoot 'C:\FPGA\V41_G2B_NVP_DIAG2_RM1' `
  -RunRoot 'C:\FPGA\G2B_NVP_DIAG2_RM1_BUILD_<fresh-UTC>' `
  -SourceCommit '<40-hex committed RM1 SHA>' `
  -SourceTree '<40-hex committed RM1 tree>' `
  -FocusedReceipt '<fresh focused gate JSON>' `
  -AffectedR3Receipt '<fresh affected-R3 25-of-25 JSON>' `
  -PublicationReadbackReceipt '<commit-pinned remote publication receipt JSON>'
```

For this R1 continuation, a successful finalizer writes
`G2B_NVP_VIDEO_DIAG2_RM1_R1_SIGNED_OFF_ROUTED.dcp` and
`G2B_NVP_VIDEO_DIAG2_RM1_R1_RAW_MARKER.bit`, classified as
`RM1_R1_OFFLINE_QUALIFIED_NO_DMA_RAW_MARKER_CANDIDATE`.

The invocation must stop at the first failed gate. A failed or partial run is
not reusable. No checkpoint reuse, incremental implementation, second route,
or hardware action is provided by this harness.
