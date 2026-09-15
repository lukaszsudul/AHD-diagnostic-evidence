# CONT1R2 I2C Integrity Decision

Decision: `FAIL_RETRIED_NACK` for the 10,000-scan zero-error gate.

Scientific/engineering Path B result: `PASS_RETRIED_NACK_REPRODUCED_CHARACTERIZED_NO_FUNCTIONAL_WRITES` after bounded characterization, normal cleanup, and evidence publication.

The first recovered NACK appeared at qualification scan 7. Ten recovered events were recorded across Bank8/0xF2, Bank6/0xF5, Bank0/0xB0, Bank7/0xF4, Bank5/0xF2, Bank7/0xF0, and Bank7/0xF5. All retries produced valid values and all scans projected successfully. The dispersed targets do not support attributing the cause to Bank7/0xF4 or any single register. The exact failing I2C protocol phase is not encoded after a successful retry.

The gate failed closed: functional writes were prohibited and the camera campaign was not reached.
