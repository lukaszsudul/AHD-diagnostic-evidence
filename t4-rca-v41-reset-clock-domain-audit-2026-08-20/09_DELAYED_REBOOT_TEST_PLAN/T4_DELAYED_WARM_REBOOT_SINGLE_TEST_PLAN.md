# One delayed warm-reboot test plan — not executed

Purpose: vary only the wait between successful SRAM programming and one warm reboot.

Image: exact formal `ahd_capture_v41_phase2_p1.bit`, 2,192,144 bytes, SHA-256 `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`. No rebuild, Phase-3, observer, Z8 or RC-A image.

Preconditions: formal repository unchanged; Plink password/host-key/sudo preflight PASS; fresh formal host/JTAG identity; exact rehash; one target `xc7a35t/0362D093/HS2 210241768436`; no physical/cold/concurrent hardware action.

Authorized future limit: one Phase-2 program, no retry; one calculated wait; one warm reboot; one read-only NVP/video baseline; one final read-only DONE; zero AXI-Lite writes, DMA, source changes or builds. Formal Phase 2 remains active, so no restoration program is expected.

Wait definition:

    DELAY_REFERENCE=FIRST_TIMESTAMP_AFTER_PROGRAM_RETURNS_EOS_HIGH_AND_FRESH_DONE_1
    CALCULATED_AUTOINIT_COMPLETE_US=1810937
    SAFETY_MARGIN_US=1000000
    DELAYED_REBOOT_WAIT_US=2810937
    DELAYED_REBOOT_WAIT_SECONDS=2.810937

Use a Windows helper based on `System.Diagnostics.Stopwatch`: start immediately at DELAY_REFERENCE; wait until `Elapsed.TotalMilliseconds >= 2810.937`; record UTC start/end and stopwatch elapsed ticks/milliseconds. Sleeping may be used only in short bounded increments while the monotonic stopwatch remains authoritative. Do not round below 2.810937 s.

Then submit exactly one proven Plink/sudo warm reboot; require disappearance, return and new boot ID. Verify one 10ee:7011 endpoint, Gen1 x1, BAR0 128 KiB, BAR1 64 KiB, pinned driver/nodes, formal runtime identity, diagnostic magic 0 and DONE=1. Run only the established read-only baseline: INIT_DONE/ERROR, NACK/TIMEOUT, first-error tuple and VCLK/SAV/FRAME deltas.

PASS requires INIT_DONE=1, INIT_ERROR=0, zero NACK/timeouts, all three deltas positive and healthy host/kernel/DONE. A valid violation is FAIL. Infrastructure invalidity is inconclusive.

PASS -> `DELAYED_REBOOT_RECOVERS_V41_NVP_BASELINE`; overlap or reboot-lifecycle dependence is strongly supported, but do not resume Phase 3. FAIL -> `DELAYED_REBOOT_DOES_NOT_RECOVER_V41_NVP_BASELINE`; simple overlap is weakened; prioritize exact clock lifecycle and implementation/I/O margin. Invalid -> `INCONCLUSIVE_DELAYED_REBOOT_INFRASTRUCTURE`.

Hard stop: formal Phase 2 active; Phase 3 not resumed; Phase 4 not started; no patch; owner/auditor review required.