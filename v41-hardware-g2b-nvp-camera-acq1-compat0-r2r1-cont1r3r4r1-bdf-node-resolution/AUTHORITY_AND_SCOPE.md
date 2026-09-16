# Authority and scope

- Owner prompt: CONT1R3R4R1, BDF-bound XDMA node resolution and non-disruptive conditional resume.
- Current endpoint only: `10.132.1.111:22`, pinned host key `SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8`; no fallback endpoint or discovery.
- Governed state: project revision 9. Read-only start hashes: `PROJECT_STATE.json` `B441296763785CB0FD8764DB78175F1F0D2A5DA891D174FEF364417901C6A6C2`; `TRACK_STATUS.json` `11B99A80D76C81C514FB24131F847EECFB75B6AD7E7B08563A383A98A4CA4686`.
- Frozen source commit/tree: `09cd7cbb426027acaefd0cf3989579b80a451f3a` / `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`; frozen DCP and firmware SHA-256 in main report.
- Prior blocker receipt: `e7af1de0a57fe8044e8c2f80800b212e645bf66a`; historical driver qualification source commit `0a201aab7adb13be079e784c6ed97dfad2ed7764`, upstream commit `b8466090b4e812e191da9e9305ffb11cb7ace768`, exact sealed module SHA-256 `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`.
- Current task was authorized to read live metadata and proceed only after safe class/probe/non-target admission. Actual admission path C failed before intervention. The conditional permissions to program SRAM, load driver, reboot or run scans were not exercised.
- No authorization for foreign-function open/unbind/reset/reprogram, shared module unload, speculative insertion, driver rebuild, FPGA rebuild, camera, functional NVP writes, capture or DMA transfer.
- No frozen FPGA/driver/characterizer source, SSOT, META, PRODUCT, runtime image or module binary was changed by this task. Only task-local read-only survey scripts and evidence were authored. No task-owned hardware lock was acquired.
