# A/B constraint-export finding (historical files, no DCP mutation)

The executed first-attempt script, preserved as Tcl command echo in
`cont1r3r1_full_signoff.log`, took `PRE_GATE` before the bus-skew isolation
helper, from the original routed checkpoint's as-open view B. The current
same-named `.tcl` file was edited *after* that run and is not byte-identical
to the executed version; its SHA-256
`1834E2EB3479EFE7FD0C4365C12BB710C9F45AC3548FF96C69FD96BB9AFEBFD2`
identifies the later revision only, not the executed first-attempt file. The original executed script
SHA-256 is unavailable, as labelled in `HASH_FLOW.csv`. The helper
subsequently ran `reset_timing -invalid`, `read_xdc` and
multiple `write_xdc`/`read_xdc` fixed-point passes, then restored the full
timing view and exported A. The comparator at line 104 compared B against A
as if both captures had the same state provenance. This is the first mixed
view defect.

The third finalization attempt loaded the historical semantic XDC into the
original routed DCP, then performed two fixed-point passes. Its restored
analysis view exported A and became the expected value. After
`write_checkpoint`, a fresh `open_checkpoint` of the final provisional DCP
exported B. The finalizer compared restored A with as-stored B at line 161–162
and failed. The header label `FIRST_SIGNOFF_RESTORED_SEMANTIC_VIEW` therefore
describes in-memory timing-constraint restoration, not text-only processing.

Historical A canonical: SHA-256
`4EDC4305DFD5B6A0F2EEA9E45CEABDDF4DC74B30A2CD9B394ED22E7500FC1B44`,
59,710 bytes, 108 lines, 11 `_xlnx_shared_iN` selector assignments.
Historical B canonical: SHA-256
`820331804ABA905FDBC1AA70578CCF8CFFE2D723DAEA08D861A85CDD3B7BE224`,
59,486 bytes, 102 lines, 5 such assignments. Each has 11 `set_bus_skew`,
26 `set_max_delay`, 30 `set_false_path`, and one `set_clock_groups` command.
Those counts were not used as an equivalence proof.

An order-preserving expansion of only the generated, read-only selector
aliases produces exactly the same 97 executable command lines in A and B,
with the same command-stream SHA-256
`12A2080ADB2957FB48F56433830CC64FB92B328BA0156B357ECA0DAB8F36DE50`.
This identifies the concrete A/B textual delta as selector alias factoring:
six assignments in A are inlined in B. The comparison preserves order,
targets, values and commands. No XDC line was sorted or discarded. This is a
structural statement about the stored exports, not by itself a claim that
Vivado's in-memory effective constraint sets or the DCPs are equivalent.

Raw files differ also in generated comment headers naming their export path
and source XDC. The project normalizer strips all comments and collapses
whitespace; that historical normalizer is too broad to serve as an
unqualified semantic-equivalence rule. The new comparator relies on exact
ordered commands for this audited delta and allows no metadata exclusions
until separately documented.

The original routed checkpoint's historical as-open `PRE_GATE` export is B.
The final provisional checkpoint's historical as-open `SIGNED_REOPEN` export
is also B. Their historical clock, cell/net/placement and route-signature
hashes are identical. Fresh independent as-open reporting is required before
using these historical observations for sign-off. The earlier routed DCP is
not a replacement candidate.
