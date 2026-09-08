
# RTL state-machine audit

Audited read-only source:
`C:/FPGA/V41_G2B/rtl/g2b/v41_g2b_onech_c2h.sv`.
The active PRODUCT worktree was not modified.

## Marker and admission path

The four-byte detector pipelines `FF 00 00 XY`; the state machine consumes the
registered valid/H/V tuple on the following source-clock edge. It qualifies
bit 7 and a zero low nibble, decodes H from bit 4 and V from bit 5, and does not
use F (bit 6) in frame/line sequencing.

In `SRC_IDLE`, only H=0 markers are SAV candidates. A V=1 SAV updates
`previous_sav_v` but starts no capture. For a V=0 SAV, previous V=1 assigns the
next frame and line 0, resets `next_source_line` to 1, and stores pending line 0;
otherwise the current `next_source_line` is used and then incremented. Thus the
source-line arithmetic itself produces `1079 -> 0 -> 1` under the project
marker fixture.

Admission at that same edge requires the *previous registered value* of
`source_locked_source`. If it is zero, `monitor_has_attempt` stays zero and no
slot is allocated, although the parser still enters `SRC_CAPTURE`. A valid EAV
then sets lock to one; with no attempt, that line is not committed and the next
line can be admitted. If line 0 is admitted and reaches valid EAV, its flags
include SOF because `pending_line == 0`.

## Exact malformed increment paths

`source_lifetime_malformed` increments exactly once for each of these episodes:

1. any qualified marker appears in `SRC_CAPTURE` before all 3840 payload bytes;
2. a marker appears in `SRC_WAIT_EAV` but is not H=1 at exactly the accepted
   post-payload position, or the pending line is greater than 1079;
3. no qualified EAV appears before the bounded `SRC_WAIT_EAV` timeout.

Each branch clears lock, sets pending discontinuity and malformed context, and
returns to `SRC_IDLE`; it is not a free-running per-cycle increment. V=1 SAV/EAV
markers encountered while already in `SRC_IDLE` do not increment malformed.
Therefore `+21` means 21 separate malformed parser episodes, not 21 cycles of
one stuck state. The current record header snapshots the cumulative malformed
counter; `MALFORMED_PRECEDING` remains pending until a successful commit, so it
can aggregate multiple earlier episodes rather than identify exactly one.

## Answers to the twelve required questions

1. The three exact increment paths are the early marker, invalid/late EAV, and
   missing-EAV timeout described above.
2. Idle VBI markers alone cannot increment. VBI-associated bytes can increment
   only if the parser is in capture/wait or interprets an H=0,V=0 marker as an
   active SAV and then fails its line termination.
3. RTL structure alone does not derive 21. The hardware snapshots prove 21
   separate episodes per boundary, but no raw marker trace maps them.
4. No local authoritative document proves that 21 is a blanking-line count;
   the RTL does not contain a 21-cycle retry loop or 21-entry boundary constant.
5. Yes: previous SAV V=1 followed by active SAV assigns line 0; an admitted,
   valid line 0 receives SOF.
6. Yes conditionally: when lock is zero at that SAV, line 0 is observed and
   parsed but not admitted.
7. Yes, this conditional behavior follows nonblocking assignment ordering: a
   lock established by that line's EAV cannot retroactively admit its SAV.
8. No off-by-one was reproduced. The project fixture produces 1079, 0, 1.
9. A mode mismatch is not established. The parser assumes the project's
   zero-low-nibble embedded markers; local NVP material does not provide the
   exact boundary byte stream needed to compare the assumption.
10. Autoinit forces the 1080p25 profile, but local evidence does not prove its
    complete progressive F/V/H byte sequence at frame boundaries.
11. The flag reports accumulated prior context. Two hardware boundary records
    each carry one flag while their snapshot increases by 21.
12. No. The project marker fixture passes. The exact hardware signature cannot
    be reproduced from an authoritative local NVP sequence because that
    sequence is absent.

## H1 disposition

The conditional previous-lock gating mechanism is simulation-proven. It is not
the complete hardware root cause: a pure lock-only omitted line consumes no
attempt and causes no drop, while each hardware boundary has an attempt gap and
drop delta of one. H1 is therefore `DISPROVEN` as the sole boundary root cause,
although the mechanism may operate after an earlier malformed episode clears
lock.
