# R3R2 pre-connection MMIO authorization review

Result: PASS. Owner R3R2 decision grants only aligned full 32-bit little-endian
writes: CONTROL 0x380C={0,1,4}, SNAPSHOT 0x3844=1, conditional ERROR_STATUS
0x383C=(immediately preceding post-reset read & 0x38), nonzero, once/session.
Maximum reset/enable/fatal-W1C operations: 3/3/3. No retries.

Verified source: integration/v41-g2b-onech-c2h,
92e9b3d914134c044371779def1ee18eaaeda98a, clean tracked RTL.
rtl/g2b/v41_g2b_onech_c2h.sv lines 1286-1309 assign CONTROL bit 0 enable,
bit 1 statistics clear, and bit 2 stream reset. Lines 1900-1943 implement reset
with stored enable zero and next epoch modulo 2^32. Lines 1945-1953 qualify
fatal W1C with a completed reset, disabled/inactive/empty/not-busy state.
ERROR_STATUS[2:0] is nonfatal; [5:3] is fatal. Lines 1965-1978 give event-set
priority over W1C. LAST_ERROR_CAUSE at 0x3840 is retained history; W1C does
not clear it, as confirmed by frozen MMIO contract section 7.2.

ABI SHA256: AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6.
The frozen session requirement mandates a new reset epoch before reader attach
and enable. R3R2 satisfies it. No clean-boot/first-reader exception is used.

All predecessor roots and prior evidence are read-only. Current allowed roots:
C:\FPGA\G2B_HW0_PRODUCT_R3R2_20260906T182010Z;
C:\FPGA\V41_G2B_EVIDENCE\v41-hardware-g2b-hw0-product-live-path-bringup-r3r2;
C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK.
The fresh exact R3R2 root is the sole exception to historical PRODUCT_R3* roots.
