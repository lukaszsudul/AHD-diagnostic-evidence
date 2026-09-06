# G2B-HW0-DRV1 Verification Receipt

## Disposition

| Field | Value |
|---|---|
| Candidate classification | OFFLINE_QUALIFIED_AHD_PCIE_XDMA_DRIVER_CANDIDATE |
| Verification mode | STATIC_OFFLINE_ONLY |
| Offline verification | PASS |
| Kernel offline compatibility | PASS_WITH_NONBLOCKING_WARNING |
| Binary reproducibility | BYTE_IDENTICAL |
| Runtime hardware qualification | NOT_PERFORMED |
| Evidence publication | PENDING |
| First offline engineering blocker | NONE |

## Authority and provenance

| Field | Value |
|---|---|
| Project state revision | 8 |
| PRODUCT source commit | 92e9b3d914134c044371779def1ee18eaaeda98a |
| PRODUCT source tree | cf6bf82249c90782eab1978c68541ed9c0e6430b |
| PRODUCT bitstream SHA-256 | AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7 |
| Driver branch | host/v41-g2b-hw0-ahd-xdma-driver |
| Driver branch base | 92e9b3d914134c044371779def1ee18eaaeda98a |
| Driver source commit | 0a201aab7adb13be079e784c6ed97dfad2ed7764 |
| Driver source tree | 6f079bf086878ddbce1f1ec82fece3039eae6573 |
| Upstream repository | https://github.com/Xilinx/dma_ip_drivers.git |
| Upstream commit | b8466090b4e812e191da9e9305ffb11cb7ace768 |
| Upstream tree | f9286c5d1bdae57285570ac5c23244d54076b99f |
| Patch SHA-256 | 415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7 |

## DUT and kernel

| Field | Value |
|---|---|
| Authoritative DUT | VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111 |
| Authenticated remote user | vcdeagent1 |
| Machine ID | 0e90f50d9465492b80258da5658446f8 |
| Boot ID | 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac |
| Kernel | 7.0.0-29-generic |
| Architecture | x86_64 |
| Headers | /usr/src/linux-headers-7.0.0-29-generic |
| Kernel config SHA-256 | D81A84B5BF2B94D5F08A5A87B6D052CD25E96DF5324BAB246790A679349A987B |
| Module.symvers SHA-256 | 88EC24BC876CCE4C2D7947424F964E5B2A76011801288209BD96539647BEE4BA |
| CONFIG_MODULES / CONFIG_PCI / CONFIG_MODVERSIONS | y / y / y |
| Secure Boot | SecureBoot disabled |

## Candidate module

| Field | Value |
|---|---|
| Filename | xdma_ahd_pcie.ko |
| Internal name | xdma_ahd_pcie |
| SHA-256 | E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77 |
| Size | 3296104 bytes |
| Architecture | x86_64 |
| Vermagic | 7.0.0-29-generic SMP preempt mod_unload modversions |
| Srcversion | EE8B149D1883AE8C6B1EE31 |
| Build ID | 1471c3a284ec1cb26115fe9e9bd59890a034f83e |
| Alias count | 1 |
| Dependencies | none |
| Signature | absent |
| Signature disposition | UNSIGNED_ACCEPTABLE_FOR_SEPARATELY_AUTHORIZED_TEST |
| Payload behavior | GENERIC_PCIE_XDMA_TRANSPORT_ONLY |

## Build and reproducibility gates

| Gate | Result |
|---|---|
| Build A | PASS |
| Build A modpost | PASS |
| Build B | PASS |
| Build B modpost | PASS |
| Build A SHA-256 | E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77 |
| Build B SHA-256 | E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77 |
| Module cmp | IDENTICAL |
| Source diff cmp | IDENTICAL |
| Source-input manifest cmp | IDENTICAL |
| Build-path leaks | NONE |

## PCI alias gates

Generated module alias:

    pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*

| Test | Result |
|---|---|
| Exact AHD modalias pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00 | MATCH / PASS |
| 10ee:7011 with subsystem 10ee:0008 | NO_MATCH / PASS |
| HDMI 10ee:7021 with subsystem 10ee:f0a1 | NO_MATCH / PASS |
| Generic Xilinx 10ee:9048 | NO_MATCH / PASS |
| platform:xdma | NO_MATCH / PASS |
| Installed Xilinx endpoint 0000:0b:00.0 | NO_MATCH / PASS |
| Unintended broad PCI aliases | 0 |

## Platform-module preservation

| Field | Value |
|---|---|
| Installed path | /lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst |
| SHA-256 | 523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490 |
| Internal name | xdma |
| Alias | platform:xdma |
| Candidate module-name collision | NO |
| Platform module modified | NO |
| Coexistence load test | NOT_AUTHORIZED_NOT_RUN |

The standard character-device class and node prefix remain xdma. Future R3
must keep the platform module unloaded unless coexistence is separately proven.

## Nonblocking warnings

- The upstream Makefile printed `XVC_FLAGS: .` three times per build; the
  governed XVC flags value was intentionally empty.
- Compiler executable names differ, but both compiler identity strings are
  Ubuntu 15.2.0-16ubuntu1, GCC 15.2.0.
- Pahole version reported by the module build differs from the kernel build
  record: 0 versus 131.
- BTF generation was skipped because matching vmlinux was unavailable.

These warnings did not cause compilation or modpost failure and do not alter
the exact vermagic or modversion proof.

## No-touch receipt

## Sealed-artifact receipt

| Field | Verified value |
|---|---|
| Remote module | /home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko |
| Controller module | C:\FPGA\V41_G2B_DRIVER_ARTIFACTS\G2B_HW0_DRV1_20260906T121539Z\xdma_ahd_pcie.ko |
| Module SHA-256 at both locations | E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77 |
| Module size at both locations | 3296104 bytes |
| Sealed-copy hash agreement | PASS |
| Remote manifest verification | PASS, 21 payload files |
| Remote directory mode | 0555 |
| Remote writable-file count | 0 |
| Controller module read-only attribute | true |
| Public `.ko` publication | NO |

## No-touch receipt

| Action or state | Result |
|---|---|
| Packages installed | NO |
| Module installed | NO |
| Candidate module loaded | NO |
| Platform module loaded by this task | NO |
| Endpoint bound | NO |
| driver_override or new_id used | NO |
| MMIO accessed | NO |
| DMA executed | NO |
| PCI reset or rescan | NO |
| JTAG or FPGA programming | NO |
| Reboot | NO |
| Power-cycle | NO |
| PRODUCT candidate modified | NO |
| AHD SSOT modified | NO |
| HDMI SSOT modified | NO |

The final candidate remains an offline artifact. Live load, automatic probe,
node-to-BDF correlation, MMIO identity, and C2H transfer proof belong only to a
separately authorized R3 run.

The final authenticated read-only DUT audit completed at
`2026-09-06T12:43:29Z`. It found the original boot ID unchanged, the exact
kernel still running, no candidate installed or loaded, the platform module
unloaded and byte-preserved, no XDMA nodes, and the AHD endpoint still unbound
at `0000:01:00.0` with a Gen2 x1 link.

## Direct raw evidence

- Controller raw export:
  C:\FPGA\V41_G2B_DRIVER_ARTIFACTS\G2B_HW0_DRV1_20260906T121539Z\raw_export
- Authenticated wrapper transcripts:
  C:\FPGA\G2B_HW0_DRV1_PREFLIGHT_20260906
- Raw verifier completion:
  2026-09-06T12:18:36.0662141Z
- Reproducibility completion:
  2026-09-06T12:19:11.5069127Z
