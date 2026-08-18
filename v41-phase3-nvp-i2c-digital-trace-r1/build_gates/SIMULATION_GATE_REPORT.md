# Diagnostic simulation gate

The untouched base export and the exact sealed diagnostic source were run with
Vivado Simulator 2025.2. The existing NVP regression produced the same PASS
sequence and the same simulation completion times in both trees:

- all ACK initialization;
- first, middle, and final NACK injection;
- SDA stuck low;
- bounded SCL-low timeout (`code=7`, count 36);
- bank-select write failure and readback mismatch containment;
- two-cycle raw SDA glitch rejection;
- reset during initialization;
- D2b retained sequence;
- 500 ms reset / 1.5 s start scaling.

The observer-specific simulation additionally passed:

- clean all-ACK completion trigger;
- address-, register-, and data-byte NACK triggers;
- early-stage-low / filtered-high delayed-ACK distinction;
- SCL observed low after master release;
- circular ordering and complete BRAM readout;
- frozen trace byte identity across PCIe `user_reset`;
- diagnostic magic/identity reads;
- unchanged formal request path;
- diagnostic write-no-effect.

```text
BASE_NVP_REGRESSIONS=PASS
SEALED_DIAGNOSTIC_NVP_REGRESSIONS=PASS
OBSERVER_SPECIFIC_REGRESSIONS=PASS
FUNCTIONAL_BASE_VS_DIAG_SIM_OUTPUTS_EQUAL=PASS
TRACE_SURVIVES_PCIE_USER_RESET=PASS
DIAGNOSTIC_AXIL_READOUT=PASS
DIAGNOSTIC_WRITE_NO_EFFECT=PASS
SIMULATION_GATE=PASS
```

The final pre-build replay used the exact sealed R2 source tree and Vivado
Simulator 2025.2 in the VHDL-2008 testbench mode required by the inherited
testbenches. Production VHDL source compatibility with the preserved project
mode was verified separately. Exact sealed-R2 identities were:

```text
DIAGNOSTIC_PATCH_SHA256=0D7BD2907296D65401D83EF9F41CF7270940DF4FB392264C32B76E455CD45A6F
DIAGNOSTIC_SOURCE_MANIFEST_SHA256=3C415A97490E723829E6DE3A1B9F2CDE0F3A2A5AE605A1996A613A50CAF597BD
SEALED_R2_ALL_SIMULATIONS=PASS
```
