# R1d functional-freeze gate

- Protected NVP blob IDs: exact match.
- Existing autoinit instantiation: `CLK_HZ=62500000`, `I2C_HZ=50000`.
- Existing NVP comprehensive self-checking regression: pass, including ACK,
  NACK, stuck-bus, filter, reset, table-boundary, and error-latch cases.
- Existing control/status and AXI-Lite bridge regressions: pass.
- Existing NVP diagnostics have no input from the probe engine. Probe counters
  are separate wires consumed only by `nvp_address_probe_regs`.
- Probe has no output or fanout to NVP reset, power, autoinit start, autoinit
  generics, table, or diagnostic-detail logic.
- Before `probe_owns_bus`, the top-level OEN mux selects the original init OEN
  signals exactly. Ownership is configuration-initialized low and can assert
  only after init done/not-busy, init OEN release, and filtered SCL/SDA high.
- Ownership is never cleared by RTL; reprogramming the formal image is the
  only hand-back.
- The engine has no `axi_aresetn` or user-reset input. The reset-perturbation
  simulation proved an active campaign and counters are not reset.
- Every decoded transaction in both campaign modes is exactly START, `0x60`,
  one address ACK/NACK, STOP.

```text
FORMAL_AUTOINIT_TRANSACTION_STREAM_UNCHANGED=YES
PROBE_TO_NVP_INIT_FUNCTIONAL_FANOUT=0
PROBE_TO_NVP_RESET_POWER_FANOUT=0
PROBE_BUS_MUX_DORMANT_EQUIVALENCE=PASS
BLOCKED_PROBE_AFFECTS_AUTOINIT=NO
FUNCTIONAL_FREEZE_GATE=PASS
```

