
# AHD v41 G2B-NVP-CAMERA-SCAN1-R1R1 main report

## Result

- Engineering prerequisites before publication: `PASS`
- Evidence publication gate: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `PASS_SCAN1_HARDWARE_QUALIFIED_SIGNAL_RESPONSE_FORMAT_UNRESOLVED`
- Scientific outcome: `CAMERA_SIGNAL_RESPONSE_PRESENT_FORMAT_UNRESOLVED`

## Hardware qualification

The exact accepted SCAN1-R1 bitstream was programmed once to volatile SRAM, followed by one authorized warm reboot. The exact qualified driver bound only `0000:01:00.0`. Runtime identity, 16/16 MMIO sanity cycles, one immutable single scan, 256/256 repetition scans, all bank restores, autoinit exclusion, and video/DMA noninterference passed with zero prohibited reads, NACK, timeout, bank mismatch, partial publication, or snapshot mutation.

The noninterference sequence completed three exact 2500-record captures. The reference, overlap, and post runs passed record, active-frame, bounded VBI, complete-frame, overflow, malformed-record, drop, AIO, and quiescence gates. The scanner operation demonstrably overlapped the middle capture. No camera frames or pixels are published.

## Physical campaign and classification

All 20 OFF/ON/OFF scans passed scanner integrity: 5 disconnected baseline, 10 connected, and 5 disconnected return-control. Every scan was A8-bookend-stable. Exactly CH1 showed a repeatable phase-correlated private detector change: F2/F3 `0x00/0x00 → 0xC0/0x03 → 0x00/0x00`. CH2/CH3/CH4 remained unchanged control arms. This yields a high-confidence bounded mapping candidate `UNKNOWN→CH1`, not final as-built authority.

NOVID remained asserted and F0 stayed `0xFF`; lock and private ACC/slope metrics did not transition. The camera response is therefore credible and reversible, but its format is unresolved. No AHD1080p25 or 0x31 compatibility claim is made.

## Cleanup

Final live pre-unload state showed scanner idle at generation 278, acknowledged snapshot, restored bank, unchanged autoinit, disabled stream, AIO 0, physical quiescence, and no native helper process. The exact normal unload `sudo rmmod xdma_ahd_pcie` ran once; the module and all XDMA nodes disappeared and the endpoint became unbound. The DUT lock was released first and the controller lock last. There was no reboot or power-cycle after the campaign; the SCAN1 image remains in volatile SRAM.


## Preserved non-hardware corrections

- MMIO sanity completed all 16 engineering cycles, then its first persistence step found the reports directory absent. The CSV was reconstructed solely from the durable gate JSON; no MMIO cycle was repeated.
- The first noninterference orchestration preflight used version/generation offsets as status/generation. It failed before scan, transport enable, or capture. Correct offsets were recorded and the hardware sequence then ran once.
- The first connected-phase offline self-check lacked permission to read root-owned baseline artifacts. It failed before device open and was repeated only with read authority.
- Connected-phase remote evidence read-back passed; a subsequent local-only controller-lock path check initially treated the lock directory as a file. The receipt was then read from its exact child path without DUT access.
- The first post-reboot connection observation occurred before the new boot was reachable; the second observation found the changed boot. Only one reboot was delivered.


## Non-claims and next step

No PRODUCT source, SSOT, RTL, active XDC, NVP functional state, route, BGDCOL, Flash, or persistent configuration changed. ACQ1 was not executed. A separately governed ACQ1 compatibility campaign may now be prepared for CH1, but only after baseline-read authority, format/compatibility resolution, a minimal whitelisted action set, and rollback proof.
