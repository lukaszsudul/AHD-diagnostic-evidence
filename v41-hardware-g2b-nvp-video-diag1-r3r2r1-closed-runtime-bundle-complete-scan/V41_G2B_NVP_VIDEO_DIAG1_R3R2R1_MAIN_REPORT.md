
# AHD v41 G2B-NVP-VIDEO-DIAG1-R3R2R1

## Result

Engineering gate: **PASS**  
Overall result: **PASS_MULTI_CHANNEL_MULTI_COLOR_PATH_PROVEN_MATRIX_COMPLETE**

The R3R2 dependency omission was corrected with one closed 25-file runtime
bundle. Static closure found 17 local modules and 9 runtime resources with zero
unresolved/ambiguous imports or missing resources. The local and DUT isolated
gates passed, including the expected negative failure when `abi_v1.py` was
removed.

## Hardware matrix

- 16/16 coherent snapshots, unique sessions, route readbacks, availability
  classifications, and firmware acknowledgements passed.
- CH1 and CH3 were BT.656-ready in 4/4 rounds; each captured all four BGDCOL
  colors with exact pixel matches and distinct hashes/dominant UYVY values.
- CH2 and CH4 retained active VCLK but had zero SAV in 4/4 rounds. No AIO was
  submitted and stream was never enabled for those eight observations.
- Eight attempted captures completed 2500/2500 with zero short/failed/missing,
  integrity, overflow, malformed, or source-drop events and complete 1920x1080
  frames.
- CH1 showed a stable legal VBI tail of 21 intervals (delta 22); CH3 showed a
  stable legal tail of 1 interval (delta 2). All bounded VBI gates passed.
- All 16 NVP states were `NO_VIDEO_STABLE`; no live camera image was proven.

## Final state

PRODUCT NVP baseline was restored to BG78=`0x88`, BG79=`0x88`, route=`0x00`;
firmware-private bank verification passed. The stream is disabled, pending AIO
is zero, the driver is unloaded, XDMA nodes are absent, and both fresh locks are
released. No FPGA programming, reboot, power-cycle, source, SSOT, or META change
occurred.

The first direct `python3 -I script.py` launch stopped before controller import
because isolated mode omitted the script directory. An equivalent isolated
wrapper inserted only the exact bundle path and ran the still-unstarted single
scan. Likewise, the frozen cleanup utility's legacy lock literals failed before
mutation; an exact R3R2R1 task-local adapter completed normal cleanup. Both
events and receipts are preserved.
