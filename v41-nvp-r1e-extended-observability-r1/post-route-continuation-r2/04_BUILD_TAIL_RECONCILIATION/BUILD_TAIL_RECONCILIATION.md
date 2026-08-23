# Original build-tail reconciliation

ORIGINAL_BUILD_TAIL_RECONCILED=PASS
ORIGINAL_REPORT_ONLY_TAIL_ASSIGNED_TO_DRY_RUN=YES
ORIGINAL_BITSTREAM_TAIL_ASSIGNED_TO_WRITE_SESSION=YES
BITSTREAM_PROPERTY_ASSIGNMENTS_IN_ORIGINAL_TAIL=0
CONTINUATION_FUNCTIONAL_SEMANTICS_CHANGE=NO

The shared helper owns namespace-correct identity, routed-state, structural,
object-ordering, and report procedures. The dry-run wrapper invokes the full
report tail and contains no bitstream command. The write wrapper invokes the
same identity helper, makes no property assignment, and contains one possible
`write_bitstream` command.
