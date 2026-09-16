# Readable harness behavior diff (no old script edit)

The original executed first-attempt Tcl file was overwritten after its run;
the Vivado command echo in `cont1r3r1_full_signoff.log` is the authority for
that invocation. The current same-named file, SHA-256
`1834E2EB3479EFE7FD0C4365C12BB710C9F45AC3548FF96C69FD96BB9AFEBFD2`,
is a later revision and is not claimed as the executed first-attempt script.
The attempt-2 finalizer file was also overwritten; attempt 3 is present at
SHA-256 `EF53E8221E8800E6B8788DC0241463ABE8D48D9E669C8C060D99148D1E614D02`.
All old files/logs remain in the private CONT1R3R1 root, untouched.

```diff
 First-attempt executed command sequence (from Vivado log):
-capture_signatures(original routed DCP, PRE_GATE)             # as-open B
-run_exact_routed_bus_skew_gate(...)                            # reset_timing/read_xdc
-capture_signatures(original routed DCP, POST_GATE)            # restored A
-require_same_signatures(PRE_GATE, POST_GATE)                   # mixes views

 Task-local acceptance path:
+open each byte-verified DCP copy independently, as stored
+capture timing XDC and physical signatures before any report-only command
+run identical read-only reports, capture signatures again
+compare candidate as-open B against reference as-open B
+compare A/B historical exports only diagnostically, under frozen alias-expansion contract
```

```diff
 Third finalizer executed command sequence:
-capture_signatures(original routed DCP, RESTORED_SEMANTIC_PRE) # restored A
-write_checkpoint(final provisional DCP)
-open_checkpoint(final provisional DCP)
-capture_signatures(final provisional DCP, SIGNED_REOPEN)        # as-open B
-require_same_signatures(RESTORED_SEMANTIC_PRE, SIGNED_REOPEN)  # mixes views

 Task-local closure:
+do not write any checkpoint or replay any constraint into the candidate
+open the exact existing final DCP in fresh independent sessions
+compare its as-open B view to the original routed DCP's as-open B view
+preserve A as provenance evidence, not the expected as-stored signature
```

The new comparator is not a drop-in modification of the old source script;
it is a separate, task-local project-owned read-only utility. It expands
only generated selector aliases in order, rejects changed commands, values,
targets and order, and records raw hashes. The report comparator excludes
only generated Date/Command header fields, and checks warnings/body content.
Focused tests and exact authority validation are in
`HARNESS_PATCH_AND_TESTS.md`. No `write_bitstream`, `write_checkpoint`,
`reset_timing`, `read_xdc`, source edit or DUT action appears in the new
acceptance path.
