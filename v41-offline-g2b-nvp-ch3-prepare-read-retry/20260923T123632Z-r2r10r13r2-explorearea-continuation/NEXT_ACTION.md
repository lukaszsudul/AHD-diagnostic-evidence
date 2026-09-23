# Next action

With separate Owner authorization, program only the exact R13R2 bitstream identified by SHA-256 `22DACBCF9245BB04901B106A27BB37248B14CC877B92DB1774FFAF63FA4B716A`, establish a fresh reset state with an empty hard-failure record, and perform one bounded PREPARE observation. Preserve the hard-failure record first and then the complete retry telemetry v1 snapshot. Continue to the unchanged APPLY/EQ, one SCAN1, and one bounded C2H/PNG only after `PASS_CLEAN` or `PASS_WITH_READ_RETRY` under the existing contract.
