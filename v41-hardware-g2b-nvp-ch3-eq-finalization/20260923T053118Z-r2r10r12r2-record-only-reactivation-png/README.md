# AHD v41 — R2R10R12R2 record-only reactivation result

## Result

**Mode: RECORD_ONLY, no oscilloscope. The same R11R1 image was reactivated successfully. PREPARE failed before APPLY_A with terminal 18. No SCAN1, C2H, frame, or PNG was produced. Cleanup passed.**

The exact R11R1 bitstream was programmed once to volatile SRAM. JTAG selected the expected single `xc7a35t` (`IDCODE=0362D093`) and reported `DONE=1`. The controlled warm reboot changed the boot ID from `5f668214-77a7-4950-a661-4ebd90916160` to `c2ca3204-12c0-467b-86f2-45e17e4653d9`.

Fresh runtime admission passed with source identity `d0f28b35c44d66bfd46c2b02388cdf03923e0c0a`, `CAMP_VIRGIN`, an empty reset record `0xF1100000`, autoinit complete, NACK count 0, idle loader/scanner/master, stream OFF, and quiescent transport.

## PREPARE and first failure

| Field | Actual result |
|---|---|
| Command attempts | 1 |
| Before / busy / terminal | `0xC3C00000` / `0xC3C00001` / `0xC3C02402` |
| Terminal | 18 — `I2C_REGADDR_NACK` |
| First post-terminal MMIO access | record header at `0x127E0`, operation 29 |
| Coherent record | `F11E9065 / 00018416 / 00200101 / F11E9065` |
| Source location | PREPARE PC22, microcode `2C271` |
| Transaction | Bank1 / register `0xC2` / READ / cause `0x02` |
| Timeout | no |

This is a distinct later failure from R12. The current execution reached PC22, so the sequential hard-stop program necessarily passed the PC14 Bank9/`0x6C` read in this attempt. This is source-derived evidence; no individual pin ACK or SCL/SDA trace was retained.

## PC14 repeatability

For the exact R11R1 bitstream the cohort now contains 2 independent PREPARE executions:

- PC14 reached: 2/2.
- PC14 pass: 1/2, source-derived from the later PC22 first-failure record.
- PC14 `I2C_RADDR_NACK`: 1/2, the historical R12 event.
- Classification: `FAILURE_AND_PASS_OBSERVED_NO_SECOND_FAILURE`.

The separate older-image cohort remains 3/3 clean traversals of the equivalent PC14 sequence. The new result does not prove that the historical PC14 NACK was fixed, random, or electrical.

## Conditional stages

PREPARE did not reach clean `CAMP_PREPARED`, so the authorized conditional stages were correctly not executed: APPLY_A=0, EQ finalization=NOT_RUN, SCAN1=0, C2H sessions=0, received bytes=0, complete frames=0, PNG=NOT_CREATED. Payload comparison against R8/R10 is not possible.

## Runtime and cleanup

The exact qualified driver was loaded once. The active mapping was `/dev/xdma0_user` (`511:0`) and `/dev/xdma0_c2h_0` (`511:36`) on `0000:01:00.0`; user BAR0 was `0xF6E00000`, length `0x20000`, with config BAR1.

Final MMIO was readable and safe for normal unload: loader done in `CAMP_VIRGIN`, terminal 18, scanner idle, stream OFF, transport status `0xC4`, W3a OFF. The driver was normally unloaded once. Module, binding, nodes, task FDs/maps, and AIO were absent afterward. The DUT lock and controller lock were released. The image remains in SRAM; the physical NVP rollback/baseline state is not proven by the terminal alone.

## Limits and next action

No oscilloscope trace was required or collected. The result does not prove the physical cause of either NACK, execute the EQ completion, establish CH3 sync, or qualify the product.

One next action: separately authorize a narrow offline retained-evidence and source review of PREPARE PC22 Bank1/`0xC2` `REGADDR_NACK`, with a repeatability table against prior clean PREPARE executions. Do not retry hardware automatically.