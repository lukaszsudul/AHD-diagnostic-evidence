# Read-only exact-formal start discovery orchestration

This is the required fail-closed sequence for the later live precheck. It is a
procedure, not evidence that any live action has run.

1. Run `Test-I25LocalStaticGate.ps1` and require exact diagnostic/formal bit,
   source/worktree, Plink 0.84, and verified installed Vivado-wrapper hashes.
2. Run `read_jtag_identity_done_strong.tcl` through the verified installed
   settings/wrapper. Require one global target, one exact HS2 target, one
   `xc7a35t / 0362D093` device, DONE=1, and zero program calls.
3. Invoke `i25_host_precheck_readonly.sh` through the audited contextual
   `-pwfile` helper and redirected sudo stdin. Pass the exact module and loader
   paths plus their sealed SHA-256 values. Require exact endpoint geometry,
   exact accepted 21-node set, zero XDMA node owners, exact loaded-module
   provenance, zero ledgered DMA commands, and explicit kernel/AER review.
4. Use the accepted read-only BAR reader (SHA-256
   `808AA85670CCEBD288DE6EA7EE05BEF303272A6E555273E763D75DC45B68351E`)
   to require `A40A0C07 / 0000400B / 00031002 / diagnostic magic 0`. No write,
   ioctl reset, DMA, or capture command is permitted.
5. Populate `NO_BOOTSTRAP_GATE_INPUT_TEMPLATE.txt` only from retained hashed
   closure evidence and those fresh logs. Apply `Test-I25NoBootstrapGate.ps1`.

Only `PASS_EXACT_FORMAL_PHASE2_START_NO_BOOTSTRAP` may authorize Arm A.
Every missing/mismatched field is a hard stop with `FPGA_PROGRAMS=0`.
No bootstrap role or bootstrap command exists in the package.

Verified installed Vivado launch chain:

```text
C:\AMDDesignTools\2025.2\Vivado\settings64.bat
C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat
```
