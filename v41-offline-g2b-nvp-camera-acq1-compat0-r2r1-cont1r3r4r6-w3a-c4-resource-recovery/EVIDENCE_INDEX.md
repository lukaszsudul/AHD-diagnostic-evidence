# W3a C4 offline resource recovery evidence

Task `CONT1R3R4R6-W3A-C4-RESOURCE-RECOVERY`; exactly one fourth candidate, budget 3/4 before and 4/4 after. Post-opt measured 20,540 Slice LUT against 20,384; first failed gate `POST_OPT_LUT_GATE_FAILED:20540`. No routed DCP or bitstream exists. No new RTL simulation, DUT contact or W4 activity.

- [C4 report](C4_REPORT.md), [candidate ledger](CANDIDATE_LEDGER.csv) and [resource delta](RESOURCE_DELTA.csv)
- [Frozen source/contract manifest](SOURCE_AND_CONTRACT_MANIFEST.json), [contract](contract/W3A_CONTRACT.json) and [host bundle manifest](HOST_BUNDLE_MANIFEST.json)
- [Targeted static review](reports/C4_STATIC_REVIEW.md), [source scope](reports/SOURCE_SCOPE.md), and [resume journal](RESUME_JOURNAL.md)
- [Private source remote readback](receipts/SOURCE_REMOTE_READBACK.json)
- [Raw post-synthesis utilization](receipts/POST_SYNTH_UTILIZATION.rpt), [post-opt utilization](receipts/POST_OPT_UTILIZATION.rpt), [post-opt hierarchy](receipts/POST_OPT_HIERARCHY.rpt), and [post-opt result](receipts/POST_OPT_CANDIDATE_RESULT.txt)
- [Failure manifest](reports/BUILD_FAILURE_MANIFEST.json) and [W4 handoff](W4_HANDOFF.md)

The complete Vivado log, generated project, private source, host code, DCP, bitstream, driver, credentials and image data are absent from this public package. The manifest excludes itself. The post-push commit-pinned byte-readback receipt is kept separately in the local task root.
