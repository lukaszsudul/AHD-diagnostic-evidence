# Delayed-sample salvage comparison

The original delayed sample met its 3.060054400-second wait and preserved EOS/DONE evidence, but stopped before telemetry because the XDMA runtime/nodes were absent. This task proved the same boot and PCIe geometry remained live, but the one permitted loader transaction stopped before `insmod`; therefore no new NVP data exist. The prior RC-A 3/3 functional passes remain valid controls, while the delayed Phase-2 functional question remains unanswered.

