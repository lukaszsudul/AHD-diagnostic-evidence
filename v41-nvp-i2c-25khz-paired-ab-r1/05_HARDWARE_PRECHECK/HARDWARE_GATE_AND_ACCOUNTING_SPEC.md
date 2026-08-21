# V41 NVP I2C 25-kHz paired A/B — hardware gate draft

This package is a draft only. Creating and inspecting it performs no SSH,
credential, Vivado, JTAG, MMIO, reboot, or other hardware action.

## No-bootstrap start proof

The exact formal Phase-2 bit is not self-identifying through the common runtime
identity alone. `A40A0C07 / 0000400B / 00031002 / diagnostic magic 0` is shared
by more than one image. A no-bootstrap start is valid only through continuity:

1. Verify the retained formal-restoration evidence and hashes, including the
   exact formal bit SHA-256, final boot ID
   `7f8db2e5-12aa-4421-b44a-28e72fff483f`, and final DONE=1.
2. Prove every later controlled task recorded zero hardware mutation.
3. Freshly read the same boot ID, kernel, exact single endpoint and geometry,
   exactly one global hardware target and exact single HS2/FPGA/IDCODE/DONE,
   pinned driver/nodes, runtime identity,
   diagnostic magic, no XDMA-node owners, zero DMA, and clean kernel/AER/XDMA
   health.
4. Rehash the exact formal bit immediately before accepting the gate.

There is no authorized formal bootstrap in this task. If the boot ID changed,
any retained/live evidence is missing, or exact formal Phase-2 continuity
cannot otherwise be proven, HARD STOP before all programming with
`FPGA_PROGRAMS=0`. Common runtime identity does not replace continuity. A wrong
JTAG target, foreign/multiple endpoint, wrong/in-use same-name `xdma`, or
critical kernel/AER finding is likewise a hard stop, never program permission.

If the driver is cleanly absent while continuity and endpoint/JTAG gates pass,
perform at most one separately accounted pre-Arm-A accepted-loader transaction,
then complete identity and node gates. Do not unload a wrong or unknown module.

`i25_host_precheck_readonly.sh` emits the host/PCIe/driver/node evidence but
deliberately leaves kernel/AER/XDMA health as `REVIEW_REQUIRED`; a grep result
must never silently promote itself to PASS. `Test-I25LocalStaticGate.ps1`
rehashes the formal bit, diagnostic bit, Plink, and supported Vivado wrappers
and reports any extant Vivado/hw_server owner without stopping or changing it.

The accepted pinned driver normally creates exactly 21 nodes:
`xdma0_user`, `xdma0_control`, `xdma0_c2h_0`, `xdma0_h2c_0`, `xdma0_xvc`,
and `xdma0_events_0` through `xdma0_events_15`. Their existence is not DMA
activity. The gate requires that exact set, zero processes owning any XDMA
node, and an operation ledger with zero C2H/H2C commands. Missing or extra
nodes fail closed; the mere presence of C2H/H2C/event/XVC nodes is expected.

## Secret-channel gate

- Rehash Plink 0.84 to
  `E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915`.
- Seal host key
  `SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8`.
- Use `-pwfile`; never use `-pw`. Use one randomized ACL-protected password
  file per invocation and prove deletion in `finally`.
- Send sudo password only via redirected stdin.
- Use `$HOME/...` in remote commands. The owner-authorized credential-channel
  exception forbids credential material in a password role or remote command.
- Retain no credential contents or sudo stdin.

## Program transition

The program procedure exposes only `ARM_A_25KHZ` and
`ARM_B_FORMAL_50KHZ`; it has no bootstrap role. It may be used only after
`PASS_EXACT_FORMAL_PHASE2_START_NO_BOOTSTRAP` and every remaining live gate.

Before each arm, verify the exact bit SHA-256, size, filename, source commit,
build provenance, no XDMA-node owners, zero DMA, no stale hardware owner, exact
JTAG target, pre-program DONE=1, and remaining operation budget. Use
`program_once_strong.tcl`. The script requires exactly one global target and
DONE=1 before it assigns PROGRAM.FILE or consumes the one program attempt.

The attempt is consumed at `PROGRAM_INVOCATION_CONSUMED=1`, immediately before
the sole `program_hw_devices` call. No error, EOS LOW, DONE!=1, or lost process
permits retry. The local supervisor records monotonic ticks on receipt of both
`I25_PROGRAM_RETURN_MARKER` and `I25_FRESH_DONE_MARKER`; the wait reference is
the later tick. The required wait policy from the controlling prompt is then
applied without shortening.

Use a separate fresh read-only session for final DONE. A read-only JTAG session
never increments the programming count.

`Invoke-I25ProgramSupervisor.ps1` is the corresponding later-run stopwatch
supervisor. It rehashes the bit and supported wrappers before launch, records
each stdout/stderr line with a monotonic tick, requires exactly one consumed,
return, fresh-DONE, EOS=1, DONE=1, and PASS marker, and exposes the later of the
return/DONE ticks as the wait reference. It is retained but must not be run
until every live hardware gate and authorization check passes.

## Read-only telemetry and normalization

`i25_collect_nvp_readonly.sh` performs 40 accepted-reader invocations:

- 4 strict common-identity reads;
- 6 provenance/build reads;
- 15 T0 reads and 15 T1 reads.

It performs zero AXI-Lite writes and zero DMA. The accepted reader returns 3
when a valid observed value differs from its supplied expected value; telemetry
collection must parse `AXI_LITE_OBSERVED` and must not classify that return code
as transport failure. Identity reads remain strict.

Each changing counter read has its own nanosecond start/end bracket. For counter
`C`:

```text
DELTA32 = wrap-safe(T1 - T0)
INTERVAL_MIN = T1_READ_START - T0_READ_END
INTERVAL_MAX = T1_READ_END - T0_READ_START
RATE_MIN = DELTA32 / INTERVAL_MAX
RATE_MAX = DELTA32 / INTERVAL_MIN
```

Static T0/T1 equality is required for STATUS, NACK, TIMEOUT, SUMMARY,
FIRST_ERROR, and DETAIL0..DETAIL5. `Analyze-I25Telemetry.ps1` also cross-checks
the first-error step encoded at `0x9C` with DETAIL3, decodes meta/physical bank,
register, value, and ORIGINAL_FF/RESTORED_FF, and calculates VCLK/SAV/frame
rate brackets. The parent campaign must apply its predeclared normal VCLK and
frame-rate ranges; the analyzer does not invent them.

DETAIL0..DETAIL5 are the complete 192-bit diagnostic detail exposed through
the formal BAR map. The internal eight-entry NACK log is not BAR-visible and
must not be claimed as collected. The analyzer is a preliminary observer gate:
the parent applies the frozen VCLK/frame-rate ranges plus reset-released and
VDD status requirements before any final arm classification. For Arm B it
also requires the accepted formal runtime signature of zero GIT_SHA_W0..W4
and zero BUILD_FLAGS, in addition to the exact formal bit transition hash.

Live read-only start discovery follows
`READ_ONLY_START_DISCOVERY_ORCHESTRATION.md`: local static/hash gate, one
global-target read-only JTAG inventory/DONE session, one contextual-pwfile
host/PCIe/driver/node collection, exact read-only formal identity/magic, then
the no-bootstrap continuity gate. No program command exists in that sequence.

## Accounting event boundaries

| Operation | Count becomes consumed when | Notes |
|---|---|---|
| FPGA program | Tcl emits `PROGRAM_INVOCATION_CONSUMED=1` immediately before `program_hw_devices` | Any subsequent outcome consumes; no retry |
| Warm reboot | The exact sudo reboot command is submitted | Require disappearance, return, and new boot ID; no second command |
| XDMA loader | `/usr/bin/bash <exact accepted loader> ...` begins remotely | Local helper/parser failure before remote start does not consume; one fresh evidence directory; no retry |
| MMIO read | Accepted reader process is invoked | The supplied telemetry transaction reports 40 reads |
| Read-only JTAG | Session opens | Account separately; it never increments FPGA programs |

For each arm retain: role, bit path/size/SHA, source commit/tree, program start
and end UTC, consumed marker, actual EOS/DONE, both supervisor ticks and
frequency, actual wait, old/new boot IDs, reboot submission/host return,
loader outcome, endpoint/driver/runtime identity, telemetry read count/raw
records/parsed rates, kernel health, and final read-only DONE.

Pair validity requires both arms to be infrastructure-valid. Arm B must use the
exact formal Phase-2 bit and is also the final restoration. Keep these counters
at zero: program retries, cold starts, physical actions, PCIe remove/rescan/
reset, driver-override writes, AXI-Lite writes, C2H, and H2C.

## Provenance anchors

- Diagnostic source commit:
  `f007dc172d43d30b02729755e60382f8ce3dbff4`, tree
  `b8f87966c8021396acb6341bd2d7d86a10fd7f13`.
- Exact Arm-A runtime provenance after a completed passing build:
  `GIT_SHA_W0=0xF007DC17`, `GIT_SHA_W1=0x2D43D30B`,
  `GIT_SHA_W2=0x02729755`, `GIT_SHA_W3=0xE60382F8`,
  `GIT_SHA_W4=0xCE3DBFF4`, `BUILD_FLAGS=0x00000002`.
- Completed-build diagnostic bit:
  `ahd_capture_v41_i2c_25khz_r1.bit`, 2,192,144 bytes, SHA-256
  `B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191`.
  The independent post-build gate is PASS and its result file SHA-256 is
  `DE8278390039793D2BE16870282C890F51D34B4F3AC35F0F9F83E6F3B5046E9C`.

- Strong accepted program-script basis:
  `C:\FPGA\T4_DELAYED_REBOOT_PHASE2_SINGLE_TEST_20260820\04_PROGRAM\program_phase2_once.tcl`,
  SHA-256 `A89726768AF2ABC549A7936FAA5A88BB677D51D3275BB3315934CEE50FFEA070`.
- Accepted read-only JTAG basis:
  `C:\FPGA\T4_DELAYED_REBOOT_PHASE2_SINGLE_TEST_20260820\03_FORMAL_BEFORE\read_jtag_identity_done.tcl`,
  SHA-256 `B13BB5D41CC1CCDA09524EC860A7796C0581D4DE3619A396E45EA7DCAB3E5F7E`.
- Accepted reader binary SHA-256:
  `808AA85670CCEBD288DE6EA7EE05BEF303272A6E555273E763D75DC45B68351E`.
- Exact formal bit SHA-256:
  `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`.

- Verified installed Vivado wrappers used by the static gate and supervisor:
  `C:\AMDDesignTools\2025.2\Vivado\settings64.bat` and
  `C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat`.
