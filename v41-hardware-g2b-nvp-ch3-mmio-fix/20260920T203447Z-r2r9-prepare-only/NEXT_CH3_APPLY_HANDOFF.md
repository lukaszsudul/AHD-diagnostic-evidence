# NEXT CH3 APPLY handoff

R2R9 stopped with the last verified loader state at `CAMP_PREPARED`. The exact qualified driver was normally unloaded, and no MMIO was performed afterward.

A separately authorized continuation must first verify the current boot, exact image identity, lock ownership, exact driver and BAR mapping, then confirm `CAMP_PREPARED` before any APPLY command. This handoff does not authorize APPLY A/B, ONESHOT, C2H/H2C, DMA, camera qualification, capture, or PNG.
