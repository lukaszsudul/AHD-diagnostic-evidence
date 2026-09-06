# G2B-HW0-DRV1 Binary Reproducibility Report

## Result

| Field | Value |
|---|---|
| Result | PASS |
| Clean build count | 2 |
| Third build required | NO |
| Module comparison | IDENTICAL |
| Source-diff comparison | IDENTICAL |
| Source-input-manifest comparison | IDENTICAL |
| Build-path leak, Build A | NO |
| Build-path leak, Build B | NO |
| Binary reproducibility | BYTE_IDENTICAL |

The two modules were produced in independent, initially absent build roots.
No Build A object or generated file was copied into Build B.

## Pinned inputs

| Field | Value |
|---|---|
| Upstream repository | https://github.com/Xilinx/dma_ip_drivers.git |
| Upstream commit | b8466090b4e812e191da9e9305ffb11cb7ace768 |
| Upstream tree | f9286c5d1bdae57285570ac5c23244d54076b99f |
| Patch SHA-256 | 415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7 |
| Source diff SHA-256 | 415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7 |
| Source-input manifest SHA-256 | 7D28F66A4253A213E75B73036ED38D8E2F8974DEDDA4378CB3D028B5C2956019 |
| Kernel release | 7.0.0-29-generic |
| Headers root | /usr/src/linux-headers-7.0.0-29-generic |
| Architecture | x86_64 |
| Kernel config SHA-256 | D81A84B5BF2B94D5F08A5A87B6D052CD25E96DF5324BAB246790A679349A987B |
| Module.symvers SHA-256 | 88EC24BC876CCE4C2D7947424F964E5B2A76011801288209BD96539647BEE4BA |
| Compiler version | gcc (Ubuntu 15.2.0-16ubuntu1) 15.2.0 |
| Make version | GNU Make 4.4.1 |
| Git version | git version 2.53.0 |

## Deterministic environment

| Variable | Exact value |
|---|---|
| SOURCE_DATE_EPOCH | 1787236279 |
| KBUILD_BUILD_TIMESTAMP | Thu Aug 20 14:31:19 UTC 2026 |
| KBUILD_BUILD_USER | ahd-drv1 |
| KBUILD_BUILD_HOST | vcde-dut-1 |
| KBUILD_BUILD_VERSION | 1 |
| Canonical debug/source prefix | /usr/src/xdma_ahd_pcie |

Each physical source path was mapped to the same canonical prefix with
fdebug-prefix-map, ffile-prefix-map, and fmacro-prefix-map.

## Independent build results

| Field | Build A | Build B |
|---|---|---|
| Wrapper UTC start | 2026-09-06T12:17:19.3422661Z | 2026-09-06T12:18:01.7405981Z |
| Wrapper UTC end | 2026-09-06T12:17:26.9259375Z | 2026-09-06T12:18:09.0383392Z |
| Build root | /home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_A | /home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_B |
| Result | PASS | PASS |
| modpost | PASS | PASS |
| Module filename | xdma_ahd_pcie.ko | xdma_ahd_pcie.ko |
| Internal module name | xdma_ahd_pcie | xdma_ahd_pcie |
| Size | 3296104 bytes | 3296104 bytes |
| SHA-256 | E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77 | E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77 |
| Vermagic | 7.0.0-29-generic SMP preempt mod_unload modversions | 7.0.0-29-generic SMP preempt mod_unload modversions |

The controller raw-export copies independently re-hash to the same SHA-256 and
have the same 3296104-byte size.

## Warning inventory

Both builds emitted the same four nonblocking diagnostic types:

1. The upstream Makefile printed `XVC_FLAGS: .` three times per build; the
   governed XVC flags value was intentionally empty.
2. The kernel records compiler executable name x86_64-linux-gnu-gcc, while the
   build used x86_64-linux-gnu-gcc-15. Both report the exact package/version
   string Ubuntu 15.2.0-16ubuntu1, GCC 15.2.0.
3. The kernel build records pahole version 131, while the module build
   environment reported version 0.
4. BTF generation was skipped because
   /usr/src/linux-headers-7.0.0-29-generic/vmlinux was unavailable.

No compile error or modpost unresolved-symbol error occurred. The candidate
contains the running kernel's modversion metadata and exact vermagic. These
diagnostics therefore classify the aggregate result as:

KERNEL_OFFLINE_COMPATIBILITY = PASS_WITH_NONBLOCKING_WARNING

## Evidence boundary

This report proves reproducible source inputs and byte-identical offline module
output. It does not claim installation, load, PCI probe, node creation, MMIO,
DMA, or runtime hardware qualification.
