# AHD v41 R0 R1i Causal-Isolation Design

Result: **PASS** (experiment design only)

This directory freezes the R0 design for separating two timing factors in the already qualified AHD v41 R1i PoC:

- physical, filtered SCL-HIGH qualification before transfer-clock progress; and
- the selected ACK sample point within the commanded/qualified HIGH phase.

No FPGA source was modified. No branch or FPGA worktree was created. No firmware or bitstream was built. Vivado was not executed, and no hardware was accessed.

The frozen functional qualification is not reopened: R1i remains `THESIS_CONFIRMED / STRONG_PASS / QUALIFIED_POC_BASELINE`, while its exact causal mechanism remains `INCONCLUSIVE`. R0 defines two—and only two—future RTL candidates, R1i-a and R1i-b, both derived directly from qualified R1i commit `20c3323d79d3896edc586d6db1df7deee60f9e41` and both retaining the qualified R1i recovery/readiness shell.

The central documents are:

- `R0_R1I_CAUSAL_ISOLATION_EXPERIMENT_PLAN.md` — complete design and predeclared interpretation;
- `R0_VARIANT_DEFINITION_MATRIX.csv` — machine-readable C0/C1/C2/C3 definitions;
- `R0_OUTCOME_INTERPRETATION_MATRIX.csv` — frozen result mapping;
- `R0_R1_IMPLEMENTATION_CONTRACT.md` — exact R1 source-change boundary;
- `R0_COLD_START_PROTOCOL.md` — separate ten-start qualified-R1i robustness test;
- `R0_INIT_DONE_TIMING_PROTOCOL.md` — counter/wall-clock clock-domain test;
- `R0_MARGIN_CHARACTERIZATION_TRIGGER.md` — mandatory R3 conditions and sweep outline.

Authoritative input is the published qualification package at:

`https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/main/v41-nvp-r1i-r2-qualified-poc-hardware-evidence`

The four canonical variants are an **anchored 2×2**. C1, C2, and C3 are controlled contrasts in the frozen R1i recovery/readiness background. C0 is the required exact R1h negative control and therefore also differs in recovery behavior; it establishes that the failure condition reproduces but is not, by itself, a clean single-factor contrast.

R0 ends here. R1 is not started by this publication.
