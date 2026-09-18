# Build and sign-off summary

- Tool: Vivado 2025.2, SW build 6299465.
- Candidate 1 source: `a6bc53136b4c0cb1eb973011d62475a9ebf4aeb2`; tree `2dac5cd1a864f86a39c5947833da8fe787450f6e`.
- Completed: synthesis and `opt_design`.
- Slice LUTs: post-synthesis **23,426**; post-opt **21,828**; strict post-opt limit **20,384**. The physical device capacity is 20,800.
- Measured CH3 executor: **1,702** post-opt LUTs. Removing that whole executor from the measured design would leave 20,126 LUTs, only 258 below the gate. A safe complete executor of that size was not substantiated for candidate 2.
- Place, route, routed resources/timing, DRC, methodology, CDC, bus-skew, signed-DCP reopen and bitstream: **NOT_REACHED**.
- Candidate revisions used: **1/2**. No resource waiver or limit increase was applied.
- The post-opt DCP is unqualified; its identity appears in the private-artifact index as a hash only.
