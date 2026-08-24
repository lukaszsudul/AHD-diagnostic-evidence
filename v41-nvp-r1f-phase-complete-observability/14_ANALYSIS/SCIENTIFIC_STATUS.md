# R1f scientific status

```text
TASK=V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY_AND_REPLICATED_PAIRED_AB
TERMINAL_CLASSIFICATION=BLOCKED_ONE_CLEAN_BUILD_SYNTHESIS_VHDL_2008_CONSTRUCT
R1F_HARDWARE_SAMPLES=0
PAIR_COUNT_VALID=0
SCIENTIFIC_RESULT=NOT_EVALUATED_NO_R1F_BITSTREAM
```

All source-identity, semantics, safe-target, register-map, simulation,
cycle-equivalence, host-tool, and frozen-statistical-plan gates passed before
the one authorized build. The build then stopped during RTL
elaboration/synthesis on Vivado error `[Synth 8-2757]` at committed
`rtl/nvp/nvp6134c_i2c_bringup.vhd:994`: the conditional signal assignment at
that line was rejected as a VHDL-2008-only construct in the build's analysis
mode. The sole build authorization was consumed. No correction, retry,
implementation, bitstream generation, hardware precheck, bootstrap, or A/B
arm followed.

Consequently, R1f produced no phase opportunities, failed-transaction log,
tri-phase probe, bank-invariant, functional NVP, replicate, or paired A/B
measurement. Every planned R1f statistical classification is
`NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE`; this is not evidence for or against
any electrical or analog cause.

The exact R7 observations remain historical input only. In particular:

- the R7 post-init write-address sequence is compatible with a stationary,
  memoryless Bernoulli process within that narrow scope, but memorylessness
  is not proven;
- an exact R7 autoinit-to-probe rate ratio is not identifiable without the
  phase-opportunity denominators that R1f was designed to measure;
- the first 16 retained R7 records' raw phase counts are not a phase-rate
  test; and
- the exact-source replay classifies R7 operation 86 as legal transitional
  bank-verify context, not a proven bank-tracker defect.

R7 recorded exact formal Phase 2, pinned driver, diagnostic magic zero, and
`DONE=1`. R1f performed zero hardware mutation, but did not freshly
reconfirm that state because the mandatory build gate failed first.

