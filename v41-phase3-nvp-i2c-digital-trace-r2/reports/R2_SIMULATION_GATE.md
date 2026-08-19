# R2 simulation gate

Vivado Simulator 2025.2 (SW build 6299465) compiled the final R2 RTL and the
exact-base RTL in separate fresh ASCII-only simulation roots.

R2 observer-specific simulation passed:

- all four ACK byte phases;
- correct-phase slave ACK with unchanged early functional NACK;
- real digital NACK throughout the correct SCL-high phase;
- SCL never reaching qualified high;
- multiple ACK-event and preceding FSM-tick context records;
- 4096 x 64 trace, 512 x 128 context, and 256 x 256 event readout;
- read-only/non-aliased AXI-Lite overlay and diagnostic write-no-effect;
- frozen trace and metadata retention across PCIe `user_reset`;
- `INIT_DONE_NO_NACK` fallback.

The exact base and R2 inherited suites produced the same deterministic PASS
sequence and simulation completion times for:

- all-ACK initialization;
- first, middle, and final NACK injection;
- SDA stuck low;
- bounded SCL-low timeout;
- bank-select write failure;
- bank-readback mismatch;
- two-cycle raw-SDA glitch rejection;
- reset boundaries;
- D2b sequence;
- VDD-enable, 500 ms reset hold, and 1.5 s start scaling.

FUNCTIONAL_BASE_VS_R2_NON_DIAGNOSTIC_OUTPUTS_EQUAL=PASS
TRACE_SURVIVES_PCIE_USER_RESET=PASS
DIAGNOSTIC_WRITE_NO_EFFECT=PASS
INHERITED_NVP_REGRESSIONS=PASS
OBSERVER_SPECIFIC_REGRESSIONS=PASS
SIMULATION_GATE=PASS

