# Authority and local payload gate

- Owner-authorized execution context: `CURRENT_R3_WINDOW`; historical SCAN0/SCAN1/ACQ1 window not required. No additional hardware scope inferred.
- Project revision at start/end: **9/9**, from `project-current-state/PROJECT_STATE.json` and `TRACK_STATUS.json`. Their SHA-256 values stayed `B441296763785CB0FD8764DB78175F1F0D2A5DA891D174FEF364417901C6A6C2` and `11B99A80D76C81C514FB24131F847EECFB75B6AD7E7B08563A383A98A4CA4686`.
- Evidence repository baseline and pinned CONT1R3R3 generation commit: `20a4edeceb9ca77294f6e121c1b48686737c980b`.
- Frozen FPGA source commit/tree: `09cd7cbb426027acaefd0cf3989579b80a451f3a` / `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`, tracked clean at the task start check.
- Accepted routed DCP: 17,469,233 bytes, SHA-256 `C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2`; inherited sign-off, not reopened or regenerated.
- Exact firmware: `C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R3_20260916T185629Z\firmware\AHD_v41_CONT1R3R3_DIAGNOSTIC.bit`, 2,192,144 bytes, SHA-256 `CD80C84E17467BCB03DEE58DC7FF64D50FD2CB6E5C409E21F871C3E05052BA09`. It was not copied to or activated on the DUT.
- Original preregistration: SHA-256 `18CDD7FBC67ABDB799475CE509BC686C3A2CD0E7153BC4E44910ABC809B5DF8C`; unchanged, no execution-context addendum was needed because no scan began.
- Inherited CONT1R3R1 payload: 33 exact files, manifest SHA-256 `B9D3A57E8AA910675944F3AB384FED4073101A178829E8C778403068C58592A2`. Task-local byte copy passed its isolated verifier: all file sizes/hashes, 0 missing resources, 0 unresolved imports, 0 module-origin violations, projection preflight PASS, 1,000-scan constant. This does not claim complete task-specific admission or DUT bundle deployment.
- Runtime implementation expected if later activated: `CONT1R3R1_BRAM_TELEMETRY`; no runtime value was read in this task.
- No synth, opt, place, phys_opt, route or bitstream-generation action occurred.
