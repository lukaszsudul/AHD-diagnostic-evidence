# Warm-reboot state retention

No direct reset-domain leakage into the NVP functional cone was found in either top level. A host reboot therefore cannot intentionally restart the sequencer or reassert physical R17 reset through user_reset/axi_aresetn. If the PCIe-derived clock pauses, state and SCL/SDA enables retain their instantaneous values and resume mid-operation. Whether either exact IP clock actually pauses is unproven. No REQP-1839-style XDMA reset leakage into the NVP cone was found.
