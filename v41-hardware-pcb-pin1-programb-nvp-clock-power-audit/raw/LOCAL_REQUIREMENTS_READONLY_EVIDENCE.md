# Local Requirements Read-Only Evidence

Source file:

C:/Users/Łukasz Suduł/Downloads/NXC-0410H_wymagania_sprzetowe_do_projektu_PCB_v1.1.md

SHA-256:

F0E2851335A3A49A33092C0EE1BB7B0D8C93156CDF20E0B31D6FF7A241E242F4

Only the following architecture facts were used:

- Lines 135-146 require native Artix-7 MultiBoot, Master-SPI strapping, and accessible INIT_B/PROGRAM_B. They do not require an FPGA user-I/O feedback route to PROGRAM_B.
- Lines 226-230 identify a 27.000 MHz NVP SYS_CLK with 45-55 percent duty-cycle goal and the NVP 3.3 V/1.2 V control set.
- Lines 232-250 record prior SYS_CLK degradation after a series resistor, prohibit unreviewed downstream loading, require a SYS_CLK measurement point, and require first-board waveform documentation.
- Lines 325-326 call for test access to SYS_CLK, reset, rail enables, and supply rails.

Application to PCB-PIN-1:

- Removing the T12 self-loop remains compatible with the accessible dedicated PROGRAM_B and MultiBoot requirements.
- A14 series damping, the required low-state pull-down, and any test feature must be assessed together using the final topology. The pull-down should not be treated as a harmless add-on to a previously problematic clock net.
- This audit does not adopt the example series-resistor range in the requirements document. Final values require the new FPGA-driven topology, stackup, receiver model, and SI analysis.

