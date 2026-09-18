# AHD v41 CH3 TVI1080p25 two-PN continuation

**Overall result: FAIL.** The first failed engineering gate was post-opt resource use: candidate 1 required **21,828 Slice LUTs** against the strict **20,384** limit. Implementation stopped before placement, routing, sign-off, bitstream generation or DUT contact.

The source candidate is commit `a6bc53136b4c0cb1eb973011d62475a9ebf4aeb2`, tree `2dac5cd1a864f86a39c5947833da8fe787450f6e`. One of two authorized candidate revisions was built. A second revision was not built: the measured deficit is 1,444 LUTs, and no bounded change was found that preserves the ordered two-PN profile, readback/recovery, CH2 protection, scanner, common NVP initialization and frozen transport while closing that deficit.

No fresh CH3 camera measurement was made. Both PN variants, the CH3-to-VDO1 output gate and C2H first-frame capture are **NOT_RUN**. No bitstream or PNG exists from this continuation. Historical CH3 F0=0x34 and NOVID=1 remain prior context and are not reported as a fresh result.

The source worktree is clean, Vivado exited after the resource failure, and no task-owned DUT state, DMA, AIO, driver or locks were created. Detailed profile material and all private artifacts remain outside this public package.

Next executable step: establish a separately governed resource architecture change that demonstrates at least 1,444 LUTs of post-opt reduction while preserving required initialization and frozen interfaces, then obtain a new bounded build authority.
