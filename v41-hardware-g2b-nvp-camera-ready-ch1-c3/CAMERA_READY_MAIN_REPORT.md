# CONT1R3R4R10-CAMERA-READY-CH1-C3

## Result

**Engineering gate: PASS (bounded diagnosis and cleanup). Camera result: `NO_VIDEO_AFTER_AVAILABLE_CH1_ACTIONS`; CAMERA_READY=NO; CAPTURE_ADMISSION=NOT_GRANTED.** Evidence publication is assessed separately by commit-pinned remote readback outside this report. Owner confirmed the camera connected and powered on the known CH1 path, but did not provide connector label or actual camera setting. In 20/20 complete scans, CH1 NOVID=1 and Bank0/A8 PRE/POST=0x0F/0x0F. Analog standard is UNRESOLVED, resolution/scan mode/fps UNKNOWN. Settings were restored to baseline.

## Entry and bounded operations

Authorized endpoint `10.132.1.111:22`, pinned SSH fingerprint `SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8`, DUT `VCDE-DUT-1`, boot `0a86ba7c-b382-4c90-b2bd-cce33b8cf56b`, BDF `0000:01:00.0`, PCI `10ee:7011`/subsystem `10ee:0007`, Gen2 x1. Exact C3 source `70266f0b90c6fc6a853495eba1d526b285fd7286` and bitstream SHA-256 `8B6402C776AAF6B2D6E0F4453479B75462516AB79A9FE534257CD5339B95A51B` were linked to runtime identity. The task-loaded qualified `xdma_ahd_pcie` used dynamically resolved `_user` with sysfs/BDF and fstat verification. C2H was never opened.

Five initial complete scans established CH1 NOVID=1. CH1 Bank5/F2 gave 0x77, 0x56, 0x47, 0x4C, 0x4A while CH2–CH4 F2 were zero. This CH1 response, physical confirmation, compiled exact autoinit context, error-free I2C and fresh ACQ satisfied the conditional write gate; it did not establish actual format. Three matching baseline PREPAREs captured Bank5/08=0x70, Bank5/05=0x24, entry bank=0x00. One DRYRUN, then slices 0x50→0x40→0x60, each once with three scans, did not clear NOVID. One legal rollback restored all baseline bytes; three final scans reconfirmed NOVID=1. Total 20/30 scans, generations 258–277, 82/82 entries, 10 groups, 105 transactions each, no retries or telemetry events. ACQ sequence/completed sequence=8/8, functional writes=10, unauthorized writes=0, NACK/timeout/bank verify failures=0. Rollback PASS, campaign closed.

## Interpretation and limit

NVP Bank0/F4/F5=0x90/0x01. The last three confirming raw CH1 tuples and scan hashes are in `CAMERA_PROFILE_CH1.json` and `CAMERA_OBSERVATIONS.csv`. The C3 format decoder output was `SIGNAL_UNSTABLE` for a varying raw tuple; the CH1 A8 signal predicate was stable no-video. The compiled CH1→VDO1 AHD1080p25 profile is a setting, not the measured input format. Three stream-OFF digital observer windows showed VCLK and active SAV, with source status 0xC4, but background NVP output can account for that activity. Live CH1 source and output readiness remain NOT_CONFIRMED. See `FORMAT_AND_OUTPUT_BASIS.md`.

## End state and next gate

Last qualifying camera scan: 2026-09-18T14:55:51.457269Z. Final idle read: 2026-09-18T15:02:00.669029Z. Stream and W3a OFF, scanner/ACQ/I2C idle, restored entry bank and baseline, no new PCIe AER/DPC messages. Own `_user` FD closed, driver normally unloaded, DUT then controller lock released. Readiness was not remeasured after cleanup. No C2H/H2C request, frame, PNG, XSim, RTL regression, FPGA build/programming, reboot or power cycle. No driver, camera setting, SSOT/META/PRODUCT change. Product reliability qualification was not run; Owner's pre-10,000-scan exception applies only to this task.

The first missing condition is a stable live analog CH1 signal with NOVID=0. Investigate the source/connection/codec input under separate authority, then perform fresh short CH1 and runtime validation. The ACQ campaign is closed after rollback and its slices cannot just be repeated in this runtime. No capture admission is granted here.

## Evidence handling

All published `raw/` receipts are copied from the verified `dut-byte-exact/` tree. An initial private controller copy used Windows text mode and changed LF bytes; it was preserved outside this publication. The task-local copier was corrected to binary mode and original DUT transfer receipts were replayed without additional scans or ACQ. All published raw file sizes and SHA-256 values were checked against the original DUT receipts. `SHA256_MANIFEST.txt` covers this directory, excluding itself. Remote readback receipt is stored privately outside the committed directory.
