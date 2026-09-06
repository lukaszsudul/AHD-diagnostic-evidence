# G2B-HW0-DRV1 DUT build environment

## Qualification result

```text
DUT_BUILD_ENVIRONMENT=PASS
RUNNING_KERNEL_DRIFT=NO
EXACT_KERNEL_HEADERS=PASS
PACKAGE_INSTALLATION=NO
KERNEL_OFFLINE_COMPATIBILITY=PASS
BUILD_WARNINGS=NONBLOCKING_INVENTORIED
```

This report combines the fresh read-only DUT inventory captured immediately
before the builds with the source/build manifests and post-build static
verification receipt. It does not claim a runtime module probe.

## Authoritative DUT identity

| Field | Captured value |
|---|---|
| Logical authority | `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111` |
| Authenticated user | `vcdeagent1` (`uid=1000`) |
| Hostname | `VCDE-DUT-1` |
| Machine ID | `0e90f50d9465492b80258da5658446f8` |
| Boot ID | `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` |
| Inventory start UTC | `2026-09-06T12:11:33.7807485Z` |
| Inventory end UTC | `2026-09-06T12:11:35.3281609Z` |
| `uname -r` | `7.0.0-29-generic` |
| Architecture | `x86_64` |
| `uname -a` | `Linux VCDE-DUT-1 7.0.0-29-generic #29-Ubuntu SMP PREEMPT_DYNAMIC Fri Jul 17 20:52:35 UTC 2026 x86_64 GNU/Linux` |
| Operating system | Ubuntu 26.04 LTS |

The running release and architecture exactly match the authorized DRV1 target.

## Toolchain inventory

| Tool | Captured identity |
|---|---|
| Compiler | `gcc (Ubuntu 15.2.0-16ubuntu1) 15.2.0` |
| `make` | GNU Make `4.4.1` |
| Git | `2.53.0` |
| GNU binutils | `2.46` |
| kmod / `modinfo` | `34.2` |
| `lspci` | pciutils `3.14.0` |

`gcc`, `cc`, `make`, Git, `ld`, `as`, `objcopy`, `objdump`, `readelf`, `nm`,
`strip`, `modinfo`, `modprobe`, kmod, `lspci`, `mokutil`, `file`, and
`sha256sum` were present. Clang was absent but was not required by the selected
kernel-compatible GCC build process. No package was installed or upgraded.

## Exact kernel build authority

| Field | Captured value |
|---|---|
| Build link | `/lib/modules/7.0.0-29-generic/build` |
| Link target | `/usr/src/linux-headers-7.0.0-29-generic` |
| Required header/build files | Makefile, generated `autoconf.h`, `auto.conf`, `utsrelease.h`, `modpost`, and `Module.symvers` present |
| Kernel config path | `/boot/config-7.0.0-29-generic` |
| Kernel config SHA-256 | `D81A84B5BF2B94D5F08A5A87B6D052CD25E96DF5324BAB246790A679349A987B` |
| `Module.symvers` SHA-256 | `88EC24BC876CCE4C2D7947424F964E5B2A76011801288209BD96539647BEE4BA` |
| `Module.symvers` size / records | `2382007` bytes / `32698` lines |

Required configuration values were present:

```text
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
CONFIG_PCI=y
CONFIG_MODVERSIONS=y
CONFIG_SMP=y
CONFIG_PREEMPTION=y
CONFIG_MODULE_SIG=y
CONFIG_MODULE_COMPRESS=y
CONFIG_MODULE_COMPRESS_ZSTD=y
```

Both build manifests independently record the same headers target, config hash,
`Module.symvers` hash, compiler identity, and kernel release. `modpost`
completed in each build without an unresolved-symbol error. Because
`CONFIG_MODVERSIONS=y`, static verification also required and found a populated
ELF `__versions` section.

## Secure Boot and signature policy

| Field | Value |
|---|---|
| Secure Boot | `DISABLED` |
| Lockdown | `none` |
| Candidate signer fields | Empty |
| Candidate signature state | Unsigned |
| DRV1 disposition | `UNSIGNED_ACCEPTABLE_FOR_SEPARATELY_AUTHORIZED_TEST` |

No signing key was created, accessed, or exposed. This is an offline policy
finding only; it is not a load authorization or a runtime signature result.

## Isolated deterministic builds

| Field | Build A | Build B |
|---|---|---|
| Root | `/home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_A` | `/home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_B` |
| Upstream commit | `b8466090b4e812e191da9e9305ffb11cb7ace768` | Same |
| Upstream tree | `f9286c5d1bdae57285570ac5c23244d54076b99f` | Same |
| Patch SHA-256 | `415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7` | Same |
| Prepared-source input-manifest SHA-256 | `7D28F66A4253A213E75B73036ED38D8E2F8974DEDDA4378CB3D028B5C2956019` | Same |
| Build target | upstream `all` | upstream `all` |
| Module SHA-256 | `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77` | Same |
| Module size | `3296104` bytes | Same |
| Result | `PASS` | `PASS` |

The independent source trees did not share objects or generated build files.
The resulting modules compare byte-for-byte identical.

The deterministic metadata was identical:

```text
SOURCE_DATE_EPOCH=1787236279
KBUILD_BUILD_TIMESTAMP=Thu Aug 20 14:31:19 UTC 2026
KBUILD_BUILD_USER=ahd-drv1
KBUILD_BUILD_HOST=vcde-dut-1
KBUILD_BUILD_VERSION=1
BUILD_A_DEBUG_PREFIX_MAP=/home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_A/source=/usr/src/xdma_ahd_pcie
BUILD_B_DEBUG_PREFIX_MAP=/home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_B/source=/usr/src/xdma_ahd_pcie
```

## Build warning inventory

Build A and Build B emitted the same nonblocking warnings:

1. The upstream Makefile printed `XVC_FLAGS: .`; the governed value was empty.
2. Kbuild warned that the compiler executable name differed:
   kernel `x86_64-linux-gnu-gcc`, used `x86_64-linux-gnu-gcc-15`. Both report
   the identical package/compiler version `Ubuntu 15.2.0-16ubuntu1`, GCC
   `15.2.0`.
3. Kbuild warned `pahole version differs from the one used to build the kernel`,
   recording kernel value `131` and used value `0`.
4. BTF generation was skipped because `vmlinux` was unavailable.

These warnings are disclosed, not suppressed. They are nonblocking because
both builds linked successfully, `modpost` passed, the exact kernel config and
`Module.symvers` were used, the required modversion metadata is present, static
identity/alias/ELF verification passed, and the two independent modules are
byte-identical. No runtime-load success is claimed.

## Read-only coordination and hardware snapshot

The pre-build inventory found no active AHD or HDMI hardware-test/build process,
no relevant task lock, no active package-lock holder, no loaded `xdma` or
`xdma_ahd_pcie` module, and zero `/dev/xdma*` nodes. No process was terminated.

The AHD endpoint was observed read-only at `0000:01:00.0` with exact identity
`10ee:7011 / 10ee:0007`, the authorized modalias, Gen2 x1 link, no bound driver,
and no driver override. A separate installed Xilinx endpoint at
`0000:0b:00.0` had HDMI identity `10ee:7021 / 10ee:f0a1`. Endpoint presence was
informational and was not a prerequisite for compilation.

The existing platform module file was present at
`/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst` with
SHA-256
`523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490`.
It was not modified or loaded.

## Offline boundary

The build scripts invoked neither `install` nor `depmod`, `insmod`, `modprobe`,
bind/unbind, `new_id`, or `driver_override`. The module was built and inspected
as an ordinary file. No MMIO, DMA, reset, rescan, JTAG, FPGA programming,
reboot, power-cycle, kernel change, OS upgrade, or package mutation occurred.
