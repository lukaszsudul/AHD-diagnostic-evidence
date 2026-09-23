# I2C-TA1 — one proposed next action

Not executed; separate Owner authorization is required.

Perform one passive SCL/SDA capture covering the write-address ACK at the historical PC111 point on the unchanged R13R2 image, using only already approved instrumentation. Correlate the observed ACK/NACK and edge timing with the retained `I2C_WADDR_NACK` record.

The action must not include retry changes, PREPARE/APPLY repetition as a campaign, cleanup, driver changes, reprogramming, reset, reboot, power cycle, or any RTL/XDC/build change.

Purpose: distinguish an observed physical address-ACK failure from a digital-only hypothesis. It does not presume that power, pull-up, codec state, or FPGA timing is the cause.
