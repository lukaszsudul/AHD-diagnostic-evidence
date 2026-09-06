# JTAG-to-PCIe correlation

Result: PASS. Every JTAG phase found exactly one pinned target and one xc7a35t chain device with IDCODE 0362D093. DONE samples were 1 before programming, after programming, after warm reboot, and at final state. The post-reboot runtime identity and exact 10ee:7011/10ee:0007 endpoint appeared under root port 0000:00:01.1; the distinct 10ee:7021/10ee:f0a1 endpoint was excluded. Endpoint and root port remained at 5.0 GT/s x1.

Candidate retention: CANDIDATE_LEFT_IN_VOLATILE_SRAM = YES based on one programming attempt, no Flash operation, no power cycle, no second programming, one expected reboot, runtime identity after reboot, final endpoint presence, and final DONE=1.
