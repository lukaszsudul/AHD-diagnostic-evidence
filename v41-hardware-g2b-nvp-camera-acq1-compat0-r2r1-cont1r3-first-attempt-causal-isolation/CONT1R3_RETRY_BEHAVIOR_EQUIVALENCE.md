# Parent/candidate non-telemetry equivalence

The comparison compiled the exact parent scanner from commit `dae2aff60141ecdbc0afac08fc0df9a3166f66c6`, mechanically changing only its module declaration for co-simulation. The generated simulation-only source SHA-256 is `8ADD7393BFF7E4E7B32814CFC3524B0E9885D54B2B4A565C2C9C98880BB1DEAA`. This generated source is outside the diagnostic commit and is not a replacement build input.

Both scanners received the identical I2C ready/accepted/completion/data/error and MMIO stimulus. Every cycle compared command valid/write/register/value, I2C ownership, scanner busy/done/lockout, MMIO ready/response-valid, and legacy read responses. Across clean, WADDR/REGADDR/RADDR recovered, all-82 recovered, unrecovered NACK, timeout, bank-select/verify/restore hard-error scenarios, 2,862 cycles and 547 physical command acceptances matched. See `simulation/parent-candidate-equivalence/xsim.log`; no retry, order, acceptance-cycle or abort divergence occurred under those directed stimuli.

The unchanged `rtl/v41/nvp_i2c_fixed_master.sv` source hashes to `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF`; the inherited master simulation gate passed as part of 24/24. Therefore identical simulated command inputs exercise the same unchanged logical SCL/SDA generator and qualification settings. This does not establish identical post-route physical delay or electrical signal quality; those require the fresh implementation/sign-off gate.

Result: `CONT1R3_RETRY_BEHAVIOR_EQUIVALENCE=PASS` for the simulated, source-bounded non-telemetry behavior.
