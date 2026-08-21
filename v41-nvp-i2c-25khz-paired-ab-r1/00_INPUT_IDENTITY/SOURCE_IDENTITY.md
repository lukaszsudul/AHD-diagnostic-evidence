# Source Identity — V41 NVP I2C 25-kHz Paired A/B R1

```text
GITHUB_REPOSITORY=lukaszsudul/FPGA_AHD
FORMAL_BRANCH=v41/xdma-v40.1.0-base
FORMAL_CHECKPOINT_COMMIT=c89e88bcdf389614c884fb129e8b2d42a585bccb
FORMAL_CHECKPOINT_TREE=417820c69c134161fcafae0947dc5976919814d1
FORMAL_TAG=v41.0.0-phase2-p2
FORMAL_FUNCTIONAL_SOURCE_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9

BASE_BRANCH=dev/v41-xdma-offline-next
BASE_COMMIT=8464af66611f7c22b8a36a4aab915d598eedda3f
BASE_TREE=4bf1988785baf4bae46bdfaf5bb12d0d25f26e68
BASE_DIRECT_PARENT=c89e88bcdf389614c884fb129e8b2d42a585bccb
BASE_TO_PARENT_TRACKED_DIFF_COUNT=1
BASE_TO_PARENT_TRACKED_DIFF=scripts/v41/phase3_build.tcl
BASE_TO_PARENT_FUNCTIONAL_DIFF=NONE

DIAGNOSTIC_BRANCH=diag/v41-nvp-i2c-25khz-r1
ISOLATED_WORKTREE=C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\worktree
WORKTREE_ASCII_ONLY=YES
INITIAL_WORKTREE_CLEAN=YES

BASE_FUNCTIONAL_RTL_XDC_XCI_EQUALS_FORMAL_CHECKPOINT=YES
FORMAL_CHECKPOINT_FUNCTIONAL_RTL_XDC_XCI_EQUALS_FD32_REFERENCE=YES
```

The `fd32fcb6..c89e88b` range contains documentation/evidence updates plus the
Phase-3 build script. Restricting both that comparison and the
`c89e88b..8464af6` comparison to `rtl/`, `ip/`, `xdc/`, `tb/`, and `tests/`
returns no change. Thus the diagnostic base is functionally byte-identical to
the accepted Phase-2 source inputs before the authorized generic connection is
changed.

## Vivado launcher layout

The prompt-style nested wrappers are absent on this workstation. The installed
supported wrappers, previously proven to launch Vivado 2025.2 build 6299465,
are:

```text
SETTINGS=C:\AMDDesignTools\2025.2\Vivado\settings64.bat
SETTINGS_SHA256=4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA
LAUNCHER=C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat
LAUNCHER_SHA256=4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994
RAW_UNWRAPPED_EXECUTABLE_AUTHORIZED=NO
```

This is an installed-layout adaptation only; the required Vivado version/build
gate remains unchanged.
