# Protected function preservation receipt

The initial read-only survey at `2026-09-16T21:54:18Z` and final targeted read-only check at `2026-09-16T21:56:01Z` agree:

| Field | Before | After |
| --- | --- | --- |
| Boot ID | `32d7b853-06fe-4004-9c4b-9b4abafbe896` | same |
| Protected BDF and IDs | `0000:0b:00.0`, `10ee:7021`, subsystem `10ee:f0a1` | same |
| Driver / module | `/sys/bus/pci/drivers/xdma` / `/sys/module/xdma` | same |
| `/dev/xdma0_user` | char `511:0` → protected `0000:0b:00.0` | same |
| `/dev/xdma0_c2h_0` | char `511:36` → protected `0000:0b:00.0` | same |
| `/sys/class/xdma` | present | present |
| AHD `0000:01:00.0` driver | unbound | unbound |
| `xdma_ahd_pcie` loaded | no | no |

No protected node was opened. No driver load/unload, bind/unbind, reset, JTAG/FPGA programming, warm reboot, MMIO, DMA, scan or functional NVP write was attempted. No controller or DUT hardware lock was acquired. All three SSH credential temporary files were deleted with zero remnants. The final read-only comparison establishes no change in the measured binding/node fields; it does not claim knowledge of unrelated device activity beyond the scoped survey.

Private raw receipt SHA-256: initial `C8612D50BCB214EC5903BE41768B298254C7F45B3F0281E8AF1C1A0823B42AE7`; module follow-up `BDE0F86374F41587A22FB268A2F69744F659A177EFB9ED4B5178408A2EC0FF39`; final comparison `F4C8562008C0B0F26584A6391ABC146C94395CB243B74B03450835228EDAD5EC`.
