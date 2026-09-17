# W3a lean offline resume evidence

Task `CONT1R3R4R6-W3-R1-LEAN-RESUME`. Candidate budget at resume: 2/3 used, no candidate 3 existed. Candidate 3 is now 3/3 used. The sole new build stopped after opt at **20,456 Slice LUT versus the governed 20,384 limit** (excess 72). No routed DCP or bitstream exists. `XSIM_NEW_RUNS=0`. DUT contact and W4: none.

- [Final resume report](RESUME_REPORT.md)
- [First failed gate](reports/FIRST_FAILED_GATE.md)
- [Same-stage LUT attribution](reports/LUT_ATTRIBUTION.md)
- [Source scope](reports/SOURCE_SCOPE.md) and [bounded static review](reports/W3A_STATIC_REVIEW.md)
- [Candidate ledger](reports/CANDIDATE_LEDGER.csv)
- [Reduced W3a ABI](contract/W3A_CONTRACT.json)
- [Old W3 publication receipt binding](receipts/OLD_W3_READBACK_BINDING.json)
- [Private-source branch remote byte read-back](receipts/SOURCE_REMOTE_READBACK.json)
- [Frozen build inputs](receipts/W3A_CANDIDATE3_SOURCE_BUILD_MANIFEST.json)
- [New post-opt utilization](receipts/POST_OPT_UTILIZATION.rpt) and [hierarchy](receipts/POST_OPT_HIERARCHY.rpt)
- [Machine-readable failure manifest](reports/BUILD_FAILURE_MANIFEST.json)

The raw Vivado log, generated project, source, DCP and firmware are not part of this public evidence directory. Its manifest deliberately excludes itself; the post-push independent read-back receipt is kept in the separate local task root.
