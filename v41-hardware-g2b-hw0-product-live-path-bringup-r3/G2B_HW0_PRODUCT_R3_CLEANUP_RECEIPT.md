# G2B-HW0-PRODUCT-R3 cleanup receipt

Result: **PASS_CLEAN_PRELOAD_STATE**

No runtime rollback was needed: no reader, descriptor, stream, DMA or module
ever started. Final state showed both XDMA modules absent, no XDMA nodes/class,
and the endpoint present/unbound at Gen2 x1. Linux lock release was recorded
before controller lock release.

- final controller wrapper log SHA-256:
  `2A4D04E80519C6AFB399CAD8B622204280ADC480EF27267B660D831814CE5CFD`
- controller release receipt SHA-256:
  `D36BD7AF312B5C9E9170C2C33E16A0359F0B1B95D155D1C1C7032FBF83A3782A`

The remote Linux release-receipt SHA-256 was reported as
`129D1978B153BDDF10F80A5194BF40842A229CB3C26DD7F7EC92A7CF91AB1010`;
that receipt was not copied locally for independent rehash.

