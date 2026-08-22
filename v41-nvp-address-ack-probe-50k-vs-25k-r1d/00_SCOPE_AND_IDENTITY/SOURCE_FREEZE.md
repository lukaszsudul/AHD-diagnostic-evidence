# R1d exact source freeze

```text
GITHUB_REPOSITORY=lukaszsudul/FPGA_AHD
BASE_BRANCH=dev/v41-xdma-offline-next
BASE_COMMIT=8464af66611f7c22b8a36a4aab915d598eedda3f
BASE_TREE=4bf1988785baf4bae46bdfaf5bb12d0d25f26e68
DIRECT_PARENT=c89e88bcdf389614c884fb129e8b2d42a585bccb
ASSIGNED_BRANCH=diag/v41-nvp-address-ack-probe-r1d
DEDICATED_WORKTREE=C:\FPGA\WORKTREES\V41_NVP_ADDRESS_ACK_PROBE_R1D
PRIMARY_SHARED_CHECKOUT_USED_FOR_WORK=NO
PART=xc7a35tcsg325-2
VIVADO_VERSION_REQUIRED=2025.2 build 6299465
```

The only tracked base-to-parent change is the accepted provenance hardening in
`scripts/v41/phase3_build.tcl` (33 added/changed lines in the base commit).

The formal autoinit instantiation remains `CLK_HZ=62500000` and
`I2C_HZ=50000`. Its I2C divider is 625 and its state tick is 626 cycles. The
protected autoinit retains `C_RESET_HOLD_CYCLES=CLK_HZ/2` (500 ms) and
`C_START_CYCLE=CLK_HZ+CLK_HZ/2` (1.5 s).

The protected Git blob IDs exactly match the Owner-supplied identities; see
`PROTECTED_BLOB_MATRIX.csv`. SHA-256 values are also retained there. The XDMA
XCI SHA-256 is
`EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C`.
The NVP-control XDC SHA-256 is
`B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318`.

The installed wrapped launcher resolves to
`C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat`; the prompt's additional
`Vivado\2025.2` path component is absent on this workstation. No raw
`unwrapped\win64.o\vivado.exe` invocation is permitted.

