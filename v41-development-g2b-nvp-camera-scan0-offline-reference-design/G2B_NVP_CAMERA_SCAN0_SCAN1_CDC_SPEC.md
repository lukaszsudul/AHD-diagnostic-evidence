# SCAN1 CDC disposition

`SINGLE_DOMAIN_NO_NEW_CDC`.

The current top defines `autonomous_clk = axi_aclk`; autoinit, the diagnostic fixed master, DIAG1 core and MMIO control all use that same clock. SCAN1 is specified in `axi_aclk`, including FSM, frozen RAM, generation and host handshake. The fixed master retains its existing input synchronizers/glitch filters for physical SCL/SDA. No new DONE/ACK toggle and no independent synchronization of wide counters are required. If a future implementation moves any component to another domain, this disposition expires and must be requalified.
