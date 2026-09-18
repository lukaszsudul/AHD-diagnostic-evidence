# FIRST-FRAME1 C3 bounded CH1 attempt

**No complete real-camera frame was received; no PNG exists.** Engineering gate `BLOCKED`; overall result `BLOCKED_SAFE_C2H_READER_UNAVAILABLE`. Evidence publication was `PENDING_REMOTE_READBACK` when this immutable report was built.

The Owner's task-local exception permits a CH1/C2H demonstration before the 10,000-scan qualification, but does not waive safe termination of pending DMA. Offline preparation verified `PROJECT_STATE_REV=9` (18/18 SSOT hashes), exact source C3 tree, exact 2,192,144-byte bitstream SHA-256, and a byte-identical 42-file W4 R1 host base. The exact C3 source has a four-record G2B ring and the frozen ABI is v41D. Host preparation found no reader with a demonstrated bounded safe stop/drain on the qualified XDMA driver. The detailed code and prior-hardware basis is in `FIRST_BLOCKER.md`.

The gate failed before current DUT admission. Current boot, BDF, FPGA identity, camera signal and format were not measured. The last W4 boot `0a86ba7c-b382-4c90-b2bd-cce33b8cf56b` and C3 runtime are historical only; W4 left the driver unloaded. A camera-ready confirmation was requested but no CH1 scan was begun. This result does not claim that the camera is absent or that the C3 video path cannot produce a frame.

Actual work on DUT: zero SSH connections, scans, ACQ commands, C2H sessions or bytes, controller/DUT locks, module loads, functional NVP writes, SRAM programming and reboots. No frame, UYVY or PNG was created. W3a policy remained OFF; current hardware readback was not attempted. `TEN_THOUSAND_SCAN_QUALIFICATION=NOT_RUN`, `FIRST_FRAME_DEMO_BEFORE_10000=OWNER_AUTHORIZED_SCOPED_EXCEPTION`, `PRODUCT_RELIABILITY_QUALIFICATION=NOT_CLAIMED`, and `W4_PAUSE_EFFECT=INCONCLUSIVE_LOW_EVENTS`.

During local publication staging, the evidence checkout's sparse selection was briefly changed by a command run in the wrong worktree. Its original five selections were restored immediately; the checkout returned to its original untracked-only status and all 18 SSOT hashes revalidated. No tracked file content or repository commit changed.

The next action is qualification of a bounded reader completion/cancellation and drain mechanism on this exact driver, or separately authorized driver remediation. A new scoped capture attempt can then resume from current DUT/camera admission. No FPGA, source, driver or SSOT change was made in this task.
