# Implemented comparison

The authoritative RC-A DCP and proven v41 precursor both show userclk1, 16.000 ns, generated through the PCIe pipe MMCM and BUFG from GT TXOUTCLK. Both place R17/T17/T18 at the same package pins/IOBs with LVCMOS33, drive 12 and slow slew. This rejects a simple nominal-frequency or IOB-property divergence in the compared checkpoints. Exact v41 Phase-2 route delay, skew and I/O path margin cannot be compared because its DCP is missing. Implementation/electrical margin remains plausible.
