# CONT1R3R1 I²C master authority audit

The low-level master `rtl/v41/nvp_i2c_fixed_master.sv` remains byte-identical to CONT1R3 (SHA-256 `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF`). The top instantiates it at `CLK_HZ=NVP_AUTOINIT_CLK_HZ=62,500,000` and `I2C_HZ=25,000`, with unchanged default SCL and bus-idle timeout cycles of 1,250 and 62,500. No new clock, I²C parameter, readiness or retry path was added in candidate 1.

The frozen master already exposes raw WADDR/REGADDR/RADDR/DATA NACK and SCL/bus-idle timeout causes, physical filtered SCL readiness, SDA sampling and open-drain release controls. The CONT1R3 first-attempt scanner telemetry captures the original cause on its valid completion edge; candidate 1 changes only where the captured record is stored and how it is read over MMIO. A successful retry does not replace the recorded first cause, as checked in the three-event and 82-event parent-payload comparisons.

The task-local full-parameter master simulation (`simulation/candidate1_extended/c1r3r1_real_master.log`) observes command acceptance at cycle 19, START_A at 1,270 and completion at 102,791. The 1,251-cycle stable-idle minimum is larger than the conservative 12-cycle telemetry writer bound. Inherited SCAN1 master tests and extended scanner cycle-by-cycle comparisons passed. This is a timing-service proof in the declared FPGA clock domain, not a measurement of analog line quality or physical routing equivalence.

The same candidate still needs final routed clock/timing sign-off before hardware access.
