# R1 Power Assumptions

Vivado 2025.2 `report_power` was run on the exact routed R1 checkpoint without `set_switching_activity`, SAIF generation, or any change to the checkpoint or power assumptions.

- Overall confidence: **Low**.
- Design implementation: High confidence; the design is routed.
- Clock activity: High; the report says more than 95% of clocks are user specified.
- Internal-node activity: Medium; fewer than 25% of internal nodes are user specified.
- I/O activity: Low; more than 75% of inputs lack user activity specification.
- Device models: High; production models.
- Activity basis: mixed propagated/user clock activity plus vectorless/default static probabilities and toggle rates. No setting file or simulation activity file was supplied.
- The SCL/SDA `report_io` rows show Vivado off-chip termination model `FP_VTT_50`. The physical board context supplied by the owner is instead a 4.7-kΩ pull-up on each line to 3.3 V. The routed DCP therefore does not contain a complete external analog bus model.

Consequently, the report can compare estimated on-chip power under identical assumptions, but cannot prove board Vcco droop, ground bounce, I²C rise time, or VIH margin. The aggregate `Vcco33` supply-class value is not a bank-14-only breakdown.