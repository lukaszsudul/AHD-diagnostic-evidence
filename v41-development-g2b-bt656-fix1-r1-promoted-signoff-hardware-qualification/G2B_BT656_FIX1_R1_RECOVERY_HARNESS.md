# Recovery harness

Task-local harness: `C:\FPGA\G2B_BT656_FIX1_R1_20260909T090813Z\scripts\g2b_fix1_r1_routed_recovery.tcl`  
Size: 163508 bytes  
SHA-256: `2A7850CDAA10F49BEE4CDEEBE59C80F700577D59CFA6D9B53EC618DDAF32DFD9`

The repository build harness was not changed. The external harness opened the exact routed checkpoint, executed the 11-plus-6 promoted sign-off architecture, restored the complete timing view, emitted a fresh signed-off DCP and called `write_bitstream` only after every offline gate passed.
