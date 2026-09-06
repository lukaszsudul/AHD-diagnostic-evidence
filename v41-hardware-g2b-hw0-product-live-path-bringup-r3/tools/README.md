# R3 task-specific source

This directory contains publishable source used by the R3 task. Inclusion does
not mean every tool produced controlling evidence; `SOURCE_PROVENANCE.csv`
distinguishes controlling, supporting, failed, superseded and unexecuted
sources.

Two R3 connection helpers and the earlier prior-R1 helper are intentionally not
published because their credential-handling logic is inside the protected
credential boundary. The provenance table records hashes and dispositions
without exposing that logic.

`historical/r2_jtag_final_state_session.tcl` is the exact outside-tree source
used by the first noncontrolling JTAG wrapper. Its result was superseded by the
complete R3-local selector/session rerun.

`unexecuted/` contains full MMIO and C2H qualification source written for later
gates but never executed because the task stopped before T1.

Every published source payload named by a normal public path in
`SOURCE_PROVENANCE.csv` is an exact byte copy of the original; each row's
original SHA-256 therefore also verifies its `public_path`. The top-level
manifest covers all published paths.

`T1_DRAFT_SAFETY_REVIEW.md` records hashes, nonexecution, and findings for the
unsafe T1 trio. Its source bodies are not published because they are not
accepted procedures and are not required MMIO/C2H parser sources.

`publication/` contains the package-manifest validator and commit-pinned remote
blob read-back utility used by the evidence-publication gate.
