# G2B-HW0-PRODUCT-R3 driver load/probe report

Result: **NOT_REACHED**

The exact commit-pinned driver-load plan was read and verified in a
post-stop, read-only supplemental check; see the authority-verification report.

- module-load/unload attempts: `0 / 0`
- module registration and automatic PCI probe: NOT_RUN
- endpoint automatically bound: NOT_RUN
- unintended endpoints bound: `0`
- udev settlement and node discovery: NOT_RUN
- kernel taint after load: N/A

The task stopped for
`FAIL — PRIOR_IMMUTABLE_ARTIFACT_BOUNDARY_VIOLATION` before `insmod`.
No module-load attempt marker exists on the DUT.

## Excluded unsafe-draft review

The unexecuted trio's hashes and safety receipt are published in
`tools/T1_DRAFT_SAFETY_REVIEW.md`; its unsafe source bodies are excluded. It
was never copied to or executed on the DUT and is not an accepted procedure.
Review found:

1. no guaranteed post-load `EXIT`/`INT`/`TERM` rollback trap;
2. `fuser ... | wc -w || true` can collapse an inspection failure to zero
   holders;
3. rollback never proves stream disabled, no active record, ring empty and no
   reset busy before `rmmod`;
4. the script can declare T1 PASS without the required two-path node-to-BDF
   proof;
5. the nominal 20-second loop can overrun its bound, while the controller's
   90-second timeout can terminate the connection without proving remote
   rollback; combined with absent traps, interruption can strand the module.

Future use requires a new governed task and a reviewed replacement. The draft
must not be executed.
