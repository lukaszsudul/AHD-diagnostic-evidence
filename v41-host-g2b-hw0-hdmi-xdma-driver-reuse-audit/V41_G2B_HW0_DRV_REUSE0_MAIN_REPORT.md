# AHD v41 G2B-HW0-DRV-REUSE0 HDMI XDMA Driver Cross-Project Reuse Compatibility Audit

## Outcome

- Engineering gate: `BLOCKED`.
- Evidence publication: `PASS`, completed by the external commit-pinned size/SHA-256 read-back reported after push.
- Overall result: `BLOCKED`.
- First blocker: `BLOCKED — HDMI_DRIVER_DUT_ARTIFACT_NOT_FOUND`.
- Exact reuse decision: `NOT_REUSABLE_PCI_ALIAS_MISMATCH`.
- Final execution point: `HARD STOP AFTER G2B-HW0-DRV-REUSE0 DRIVER REUSE AUDIT`.

This was a cross-project read-only audit. No driver build or rebuild, package change, module load/unload, bind/unbind, `driver_override` write, PCI rescan/reset, MMIO access, DMA, FPGA programming, reboot, power-cycle, source edit, or SSOT edit occurred.

## Owner authorization boundary

The owner granted cross-project read, HDMI SSOT read, HDMI driver-artifact read, and DUT read-only inventory. Module load, driver bind, module install, package install, reboot, power-cycle, and FPGA programming were denied. Driver build, MMIO, and DMA were denied for this task. Those denials were treated as hard execution boundaries; the audit did not test them by mutation.

## Authority

The AHD evidence repository began at required commit `9caa9c339966eda999219e4ed686c01654b9a87e`. Revision-8 SSOT was verified with all `18/18` manifest entries matching; manifest SHA-256 is `B935E05F75AC1357D29ACB91E08978BD9A6701CD06024F9E6E2C6EB071993EC6`. META-8A promoted the accepted Recovery-4 offline-qualified PRODUCT candidate, no supersession is recorded in rev8, controlled G2B-HW0 execution remains separately authorized, and G2B-HW qualification remains `NOT_PROVEN`.

Required R2 evidence was verified at directory `v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot` and completion commit `9caa9c339966eda999219e4ed686c01654b9a87e`. Its 128-entry self-excluded manifest matched, and its accepted endpoint state was used only as a prior-state authority before fresh read-only verification. The authorized R2 warm reboot was not repeated.

HDMI authority was discovered, not guessed:

- source repository `lukaszsudul/FPGA_HDMI`, default `main`, current commit `2d64e00b15c4dbb875cd04b4ba7df7c16f4fed1f`, tree `2a643626235b9b9e1ae67798e1069d140eaabc1e`;
- evidence/SSOT repository `lukaszsudul/HDMI-diagnostic-evidence`, canonical branch `FPGA_HDMI`, current commit `2317361094d599717a9509bd9d508efd58f6d1a2`, tree `7bf324a9afb02d8da6947cc0748b16e07d1d0c55`;
- HDMI SSOT revision `1` and driver authority `VERIFIED`.

No local HDMI source or evidence worktree was found in the targeted `C:\FPGA` discovery scope. Authenticated GitHub read access supplied the immutable repository objects; neither HDMI repository was cloned, fetched, checked out, or modified.

## Fresh DUT state

Authenticated read-only access to `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111` passed. Initial capture at `2026-09-06T11:03:29Z` and final capture at `2026-09-06T11:22:53Z` agree:

| Property | Value |
|---|---|
| User / machine | `vcdeagent1` / `0e90f50d9465492b80258da5658446f8` |
| Architecture / kernel | `x86_64` / `7.0.0-29-generic` |
| Boot ID | `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` |
| Endpoint / upstream | `0000:01:00.0` / `0000:00:01.1` |
| IDs / class | `10ee:7011`, subsystem `10ee:0007`, class `058000` |
| Modalias | `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00` |
| Link | `5.0 GT/s PCIe`, width `1` |
| Driver / override | `UNBOUND` / `(null)` |
| `xdma` loaded / nodes | `NO` / `0` |
| Secure Boot / lockdown | `DISABLED` / `none` |

The refined concurrent-operation capture found no matching process, systemd job, or package-lock holder. No relevant concurrent mutator was attributed or terminated.

## Exact HDMI driver authority and current artifact blocker

HDMI governance names one exact PCIe reuse candidate:

| Property | Value |
|---|---|
| Governed path | `/opt/fpga-hdmi-lab/driver/xdma.ko` |
| Expected bytes | `3295008` |
| Expected SHA-256 | `B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2` |
| Internal name | `xdma` |
| Driver version | `2025.2.0` |
| Build kernel | `7.0.0-29-generic` |
| Historical vermagic | `7.0.0-29-generic SMP preempt mod_unload modversions ` |
| Build architecture/compiler | `x86_64` / GCC `15.2.0-16ubuntu1` |
| Bus | `PCIE_XDMA` |

Fresh inspection found the governed path absent. The only additional staging root named by authority, `/run/r0f_a`, was also absent. An authority-scoped search returned zero candidates and zero exact-hash matches. Therefore actual hash, stat, SHA-512, file/ELF identity, fresh `modinfo`, signature metadata, and dependency metadata cannot be verified. This is `BLOCKED — HDMI_DRIVER_DUT_ARTIFACT_NOT_FOUND` and prevents Engineering PASS. No arbitrary `xdma.ko` was used as a substitute.

The installed `/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst` is separately preserved at SHA-256 `523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490`. It exposes only `platform:xdma` and is not the PCIe reuse candidate.

## Provenance and source delta

The HDMI binary identity is complete historically even though the current file is absent:

- upstream repository `Xilinx/dma_ip_drivers`;
- upstream commit `b8466090b4e812e191da9e9305ffb11cb7ace768`, tree `f9286c5d1bdae57285570ac5c23244d54076b99f`;
- HDMI driver-control commit `b7ef83efcba95e74c25f67996e8c5686a6fa887c`, tree `01d33fea7f9d36e6772342e536990151ffd1ecc3`;
- source-files manifest SHA-256 `144B73F8B30529E7A420A21E574BE6E9F3083C7FE4ACEE8E43661059349AC19A`;
- prepared-tree manifest SHA-256 `67FF79F42BCD55E2647C0AFA9CAC1C5B47664D4AD8A9BA51C943C5761DA7C394`;
- build-evidence commit `ecb760da97a597460c16959a564979f3836dfd24`, tree `91e5840925b770d8ac0c305e76def6e1af0563e5`.

All 417 prepared files are governed and exactly two files differ from upstream. The Makefile replaces three deprecated `EXTRA_CFLAGS` assignments with equivalent `ccflags-y` assignments and is `GENERIC_KERNEL_COMPATIBILITY`. The `xdma_mod.c` patch replaces the upstream 57-entry PCI table—including a generic `7011` entry—with the single HDMI `PCI_DEVICE_SUB` entry and is `HDMI_SPECIFIC_AND_AHD_INCOMPATIBLE`. No other probe/remove, BAR, engine, channel, DMA, interrupt, node, descriptor, polling, alignment, BDF/index, ioctl, sysfs, or module-parameter customization exists.

The kernel module remains `GENERIC_TRANSPORT_ONLY`: it transports bytes and exposes MMIO/DMA nodes. It does not parse `AHD_C2H_TRANSPORT_ABI_V1` or HDMI frame semantics. AHD userspace remains AHD-specific and must not be replaced by HDMI tools.

## Deterministic PCI incompatibility

The exact governed binary's sole hash-linked alias is:

`pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*`

The fresh AHD modalias is:

`pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00`

Device ID `7021` does not match `7011`; subsystem device `f0a1` independently does not match `0007`. Hence:

- `PCI_ALIAS_10EE_7011 = FAIL`;
- `CURRENT_AHD_MODALIAS_MATCH = FAIL`;
- `AHD_PCI_ID_COMPATIBILITY = FAIL_HDMI_SPECIFIC_MATCH`;
- `HDMI_SPECIFIC_DRIVER_CUSTOMIZATION = INCOMPATIBLE`;
- `AHD_HDMI_XDMA_CONFIGURATION_COMPATIBILITY = FAIL` for the exact governed module.

The core XDMA transport configuration is otherwise `PASS_WITH_CONSTRAINTS`: both projects use XDMA 4.2, Gen2 x1, AXI Stream, one C2H and one H2C engine, 64-bit AXI, 62.5 MHz, user BAR0, configuration BAR1, and no bypass path. BAR0 sizes and project policies differ, while the exact accepted HDMI MSI/MSI-X setting is not frozen in available evidence. Those facts do not cure PCI discovery failure.

## Historical exact-binary proof

The exact SHA-256 is hash-linked to the same DUT and kernel in HDMI evidence:

- A8-C1 built and verified the exact binary, stopping before load.
- A9 rehashed that binary locally/remotely, performed one governed load, bound only HDMI endpoint `0000:0b:00.0`, left the AHD endpoint unbound, and created 21 `xdma0_*` names without MMIO/DMA.
- A10 retained that exact loaded binary, mapped user and `c2h_0` nodes to the HDMI BDF, and validated an exact 4,147,280-byte C2H frame.
- Current HDMI SSOT evidence later records the same SHA, alias, HDMI-only binding, node proof, and further governed DMA frames.

Thus previous module load, node creation, and DMA are each `PASS_EXACT_BINARY`. Exact-source inspection also proves dynamic `xdmaN` allocation and BDF/sysfs correlation support, so `MULTI_DEVICE_AND_DYNAMIC_INDEX_SUPPORT = PASS`. A future task must never assume `xdma0`.

## Host policy, dependencies, and collision

`MODULE_LOAD_SIGNATURE_READINESS = READY` because current Secure Boot is disabled, lockdown is `none`, and `CONFIG_MODULE_SIG_FORCE` is not set. This does not authorize loading and is independent of the missing artifact and alias failure. `MODULE_DEPENDENCY_READINESS = UNRESOLVED` because the absent current file cannot receive fresh exact-path `modinfo`.

Both the installed platform module and governed HDMI PCIe module use internal name `xdma`. Collision management is `SAFE_WITH_EXACT_PATH_LOAD` in principle only when no `xdma` module is loaded, the exact path/hash is verified, and generic `modprobe xdma` is prohibited. Final response classification is `YES_MANAGED`; no cleanup is required or authorized. This cannot approve the incompatible HDMI binary for AHD.

## Final decision and successor boundary

`HDMI_DRIVER_REUSE_DECISION = NOT_REUSABLE_PCI_ALIAS_MISMATCH`.

The specific incompatibility enum is used because the authoritative, historically hash-linked binary has a conclusive built alias mismatch. The current artifact absence separately blocks full Engineering acceptance; it does not make the alias result unresolved.

Do not automatically execute a driver build. The recommended exact next action is to obtain separate owner authorization for a new AHD-compatible XDMA driver build task targeting kernel `7.0.0-29-generic` and the AHD `10ee:7011 / 10ee:0007` policy. REUSE0 ends here.

## Publication

Repository/branch: `lukaszsudul/AHD-diagnostic-evidence` / `main`.

Directory: `v41-host-g2b-hw0-hdmi-xdma-driver-reuse-audit`.

Required commit message: `Audit reuse of HDMI PCIe XDMA driver for AHD v41`.

The SHA-256 manifest covers every published file except itself. Because a commit cannot contain a truthful receipt of its own not-yet-existing hash, commit-pinned remote size/SHA-256 validation is recorded externally in the final task result after push.
