# Scope and first-failed-gate policy

This is a diagnostic characterization of recovered first-attempt NACKs, not a production repair or zero-error qualification. Preserve the 82-entry manifest, ten actual execution groups, 105 clean transactions, bounded retry and bank selection/verification/restoration, immutable projection, low-level I2C master and all non-diagnostic product behavior.

The new read-only telemetry makes all 82 entry opportunities observable in a single frozen generation. A recovered first-attempt NACK can be recorded without a recovered-event-count stop only when the existing successful bounded retry yields a complete, coherent scanner publication. An unrecovered NACK, timeout, bank-verify/restore problem, incoherent telemetry, unexpected MMIO capability or source/build sign-off failure is a hard stop. A partial run never becomes a 1,000-scan PASS.

Fresh task roots and locks are separate from prior runs. Only `192.168.1.57:22` may be used as the DUT SSH endpoint. Evidence publication is a separate gate from engineering acceptance.
