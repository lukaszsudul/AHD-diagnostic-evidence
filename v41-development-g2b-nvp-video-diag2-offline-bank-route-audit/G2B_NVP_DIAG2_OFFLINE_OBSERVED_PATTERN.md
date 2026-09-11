
# Observed route pattern

| Route | Channel | Expected private bank | Result |
|---:|---:|---:|---|
| 0 | CH1 | 5 | BT.656 PASS 4/4 |
| 1 | CH2 | 6 | VCLK active, SAV absent 4/4 |
| 2 | CH3 | 7 | BT.656 PASS 4/4 |
| 3 | CH4 | 8 | VCLK active, SAV absent 4/4 |

All channels reported NO_VIDEO_STABLE. Route and BGDCOL readback passed; the failure precedes DMA and is not attributed to XDMA, AIO, host validation, or transport.
