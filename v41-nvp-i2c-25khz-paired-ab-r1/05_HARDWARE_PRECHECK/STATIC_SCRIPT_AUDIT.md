# Static audit — V41 NVP I2C 25-kHz paired A/B hardware drafts

This audit is offline only. It performed no SSH, credential read, Plink
session, Vivado launch, JTAG access, MMIO, reboot, FPGA program, driver action,
or other hardware action.

## Authorization correction

```text
FORMAL_BOOTSTRAP_AUTHORIZED=NO
FORMAL_START_PROOF_FAILURE_ACTION=HARD_STOP
FPGA_PROGRAMS_AT_FORMAL_START_PROOF_FAILURE=0
PROGRAM_ROLES=ARM_A_25KHZ,ARM_B_FORMAL_50KHZ
```

`FORMAL_BOOTSTRAP` was removed from the Tcl role allow-list and PowerShell
supervisor validation set. `Test-I25NoBootstrapGate.ps1` now returns a nonzero
status for every missing, changed, contradictory, or unsafe exact-formal start
proof and explicitly emits `FPGA_PROGRAMS_REQUIRED_AT_HARD_STOP=0`. It never
recommends a bootstrap.

The retained closure is evidence of the last controlled state, not proof of
the current volatile state:

- final report:
  `C:\FPGA\V41_NVP_AXI_CLOCK_MEASURE_R1\10_FINAL\V41_NVP_AXI_ACLK_LIFECYCLE_MEASUREMENT_R1_REPORT.md`,
  SHA-256 `128C4A6ACE44E78D4935711CA390319845C47E96BF303DBE023C959FCFF837A8`;
- formal-restoration identity log:
  `C:\FPGA\V41_NVP_AXI_CLOCK_MEASURE_R1\08_FORMAL_RESTORE\FORMAL_RESTORE_IDENTITY.log`,
  SHA-256 `6866AAF1D630686C34AF42E37B84A1DB6BF10CA1F65E4F01050527548B2AA886`;
- final read-only DONE log:
  `C:\FPGA\V41_NVP_AXI_CLOCK_MEASURE_R1\08_FORMAL_RESTORE\FINAL_DONE.log`,
  SHA-256 `728E5465370C251E36595EAFC801E198A9CC6C676D074CA4822918B79B53DC1D`;
- retained boot ID: `7f8db2e5-12aa-4421-b44a-28e72fff483f`;
- retained closure: exact formal Phase 2, common identity/magic PASS, pinned
  XDMA present, final DONE=1.

A live exact-formal start proof still requires the same boot ID, a complete
subsequent no-mutation review, exact endpoint/JTAG geometry, exact driver and
nodes, common runtime identity/magic, no node owner or DMA activity, clean
kernel/AER/XDMA review, and a fresh DONE=1. Unknown physical continuity is not
claimed. Failure of any proof field is terminal for this campaign.

## Diagnostic provenance

The final source commit is:

```text
DIAGNOSTIC_SOURCE_COMMIT=f007dc172d43d30b02729755e60382f8ce3dbff4
DIAGNOSTIC_SOURCE_TREE=b8f87966c8021396acb6341bd2d7d86a10fd7f13
EXPECTED_GIT_SHA_W0=0xF007DC17
EXPECTED_GIT_SHA_W1=0x2D43D30B
EXPECTED_GIT_SHA_W2=0x02729755
EXPECTED_GIT_SHA_W3=0xE60382F8
EXPECTED_GIT_SHA_W4=0xCE3DBFF4
EXPECTED_BUILD_FLAGS=0x00000002
```

The GIT words match the exact eight-hex-character slicing implemented by the
unchanged build script and its preserved provenance preflight. The completed
independent build gate is PASS. The exact diagnostic bit is
`ahd_capture_v41_i2c_25khz_r1.bit`, 2,192,144 bytes, SHA-256
`B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191`.
The gate-result SHA-256 is
`DE8278390039793D2BE16870282C890F51D34B4F3AC35F0F9F83E6F3B5046E9C`.

## Static findings

- PowerShell parser: zero AST errors in all four `.ps1` drafts.
- Synthetic no-bootstrap gate: an exact complete fixture passed; the blank
  template failed closed with `HARD_STOP=YES` and zero programs.
- Synthetic Arm-A telemetry: exact GIT words/build flags reconstructed
  `f007dc172d43d30b02729755e60382f8ce3dbff4`; boot stability, 40-read
  accounting, static-field consistency, wrap-safe counter deltas and the
  functional parse gate passed.
- The programming Tcl contains exactly one active `program_hw_devices` line.
  The read-only DONE Tcl contains zero.
- Both Tcl scripts enumerate all hardware targets, require one global target,
  one exact HS2 target and one exact device. The programming Tcl additionally
  requires pre-program DONE=1 before assigning PROGRAM.FILE or consuming the
  sole attempt.
- The programming supervisor binds Arm B to the exact formal filename, size,
  SHA-256 and functional source commit. Arm A is bound to the exact diagnostic
  filename, size, SHA-256 and `f007dc17...` source commit.
- The supervisor rehashes its exact programming Tcl, the bit, and both
  supported Vivado wrappers before launch. Its stopwatch remains in one epoch
  through program return, fresh DONE, and the full minimum 5-second wait.
- The host precheck contains no bind/unbind, module load/unload, reset/rescan,
  MMIO, DMA, reboot or write action. Driver provenance and kernel health remain
  explicit review gates rather than inferred PASS results. It enumerates the
  exact accepted 21-node XDMA set; C2H/H2C/event/XVC node existence is expected
  and is not counted as DMA activity. Zero owners and zero ledgered DMA
  commands remain mandatory.
- The telemetry shell invokes only the accepted read-only BAR reader, exactly
  40 times: four strict identity, six provenance, and two sets of fifteen
  snapshot reads. It records zero AXI-Lite writes and zero DMA transfers.
- The analyzer validates accepted-reader return semantics, exact read count,
  zero prohibited operations, boot stability, per-counter read brackets,
  wrap-safe deltas, static T0/T1 fields, Arm-A runtime provenance, and the
  accepted all-zero formal GIT/build signature for Arm B. It explicitly defers
  frozen rate-range and reset/VDD gates to the parent classification.
- DETAIL0..DETAIL5 are documented as the full 192-bit BAR-visible detail. The
  internal eight-entry NACK log is not BAR-visible and is not claimed.
- The task-local contextual Plink helper clone differs from the accepted helper
  only in its secret-directory line; its dedicated audit and hashes are in the
  task-root precheck package. It was not executed and no credential was read.

No standalone `tclsh.exe`, `bash.exe`, or `shellcheck.exe` was available in the
local command path. Consequently Tcl and Bash validation in this audit is
static; Vivado and DUT execution were deliberately not used. The programming
Tcl retains the accepted A897... structure and its sole active program call.

## Remaining pre-execution blockers

1. Current exact formal Phase-2 continuity must be proven live. A changed boot
   ID or any missing field means hard stop with FPGA programs still zero.
2. The targeted kernel/AER/XDMA log requires explicit review; grep count alone
   cannot produce PASS.
3. These files do not authorize execution;
   the parent campaign must rehash the copied files and complete all remaining
   gates immediately before any live action.

## Operation accounting at this audit

```text
SSH_SESSIONS=0
CREDENTIAL_READS=0
VIVADO_LAUNCHES=0
JTAG_SESSIONS=0
FPGA_PROGRAMS=0
WARM_REBOOTS=0
MMIO_READS=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
```

