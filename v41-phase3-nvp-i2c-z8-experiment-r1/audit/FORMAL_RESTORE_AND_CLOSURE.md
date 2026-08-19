# Formal Phase-2 baseline verification and closure

## Scope and decision

This closure was performed under the owner instruction to verify the current
image and restore the exact accepted Phase-2 image only if the Z8 diagnostic
magic was present. All live checks were read-only.

The current image was already the accepted formal Phase-2 baseline. The formal
identity block passed and the proven diagnostic identity address returned zero.
Consequently no SRAM programming operation and no Ubuntu reboot were performed.

## Live read-only verification

Ubuntu was reached from the approved Windows host context using the previously
qualified, pinned ED25519 host fingerprint. Authentication completed as
`vcdeagent1` on `VCDE-DUT-1`.

```text
SSH_AUTHENTICATED=YES
HOST=10.132.1.111
HOSTNAME=VCDE-DUT-1
SSH_USER=vcdeagent1
BOOT_ID=b636cf27-8373-4ca0-8819-ef2b8a722822
HOST_SNAPSHOT_TIME=2026-08-19T22:07:25+02:00

ENDPOINT_COUNT=1
BDF=0000:01:00.0
VID_DID=10ee:7011
SUBSYSTEM=10ee:0007
CLASS=058000
LINK=Gen1_x1
BAR0_BYTES=131072
BAR1_BYTES=65536
XDMA_MODULE_LOADED=YES
XDMA_DRIVER_COMMIT=8721136e74a66500b02d16cb41922d966139cd46
XDMA_NODES_PRESENT=YES

BLOCK_ID=0xA40A0C07
PROTOCOL=0x0000400B
CAPABILITIES=0x00031002
DIAGNOSTIC_MAGIC_ADDRESS=0x00002000
DIAGNOSTIC_MAGIC_OBSERVED=0x00000000
```

A fresh Vivado 2025.2 read-only hardware session used the exact pinned HS2
target. The session did not assign `PROGRAM.FILE` and performed no programming.

```text
JTAG_TARGET=localhost:3121/xilinx_tcf/Digilent/210241768436
DEVICE_COUNT=1
FPGA_PART=xc7a35t
FPGA_IDCODE=0362D093
FPGA_DONE=1
READ_ONLY_JTAG_GATE=PASS
FPGA_SRAM_PROGRAMS_THIS_JTAG_SESSION=0
JTAG_SNAPSHOT_TIME=2026-08-19T22:11:40+02:00
```

## Current-image determination

```text
Z8_DIAGNOSTIC_MAGIC_EXPECTED=0x4E565052
Z8_DIAGNOSTIC_MAGIC_PRESENT=NO
Z8_IS_CURRENTLY_ACTIVE=NO
FORMAL_PHASE2_ALREADY_ACTIVE=YES
CURRENT_IMAGE_BEFORE_ACTION=FORMAL_PHASE2_ACCEPTED_REFERENCE
```

The accepted formal bit remains identified by:

```text
FORMAL_BIT=ahd_capture_v41_phase2_p1.bit
FORMAL_BIT_SIZE=2192144
FORMAL_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
FORMAL_BIT_SOURCE_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
```

Because the formal image was already active, the conditional restoration path
was not entered.

```text
FORMAL_RESTORE_PROGRAMS=0
FORMAL_RESTORE_EOS=NOT_RUN_ALREADY_FORMAL
FORMAL_RESTORE_DONE=NOT_RUN_ALREADY_FORMAL
WARM_REBOOTS_THIS_CLOSURE=0
FINAL_DONE=1
```

## Formal repository no-change gate

The formal project repository was inspected read-only before publication.

```text
FORMAL_BRANCH=v41/xdma-v40.1.0-base
FORMAL_HEAD=c89e88bcdf389614c884fb129e8b2d42a585bccb
PHASE2_P2_TAG_TARGET=c89e88bcdf389614c884fb129e8b2d42a585bccb
FORMAL_WORKTREE=CLEAN
FORMAL_COMMITS_THIS_CLOSURE=0
FORMAL_PUSHES_THIS_CLOSURE=0
FORMAL_TAGS_THIS_CLOSURE=0
FORMAL_REPOSITORY_MUTATION=0
```

## Required closure block

```text
CURRENT_IMAGE_BEFORE_ACTION=FORMAL_PHASE2_ACCEPTED_REFERENCE
FORMAL_RESTORE_PROGRAMS=0
FORMAL_RESTORE_EOS=NOT_RUN_ALREADY_FORMAL
FORMAL_RESTORE_DONE=NOT_RUN_ALREADY_FORMAL
FORMAL_IDENTITY=PASS_A40A0C07_0000400B_00031002
DIAGNOSTIC_MAGIC_AFTER_RESTORE=0x00000000
FORMAL_REPOSITORY_MUTATION=0
FORMAL_PHASE2_ACTIVE_AT_END=YES
PHASE3_RESUMED=NO
```

No diagnostic experiment, RTL modification, AXI-Lite write, DMA transfer,
Phase-3 resume, tag, pull request, or release occurred.
