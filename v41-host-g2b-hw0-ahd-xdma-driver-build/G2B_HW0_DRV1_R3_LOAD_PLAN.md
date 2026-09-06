# G2B-HW0-PRODUCT-R3 exact driver load plan — documentation only

## Authorization boundary

This file is a future plan. It was not executed by G2B-HW0-DRV1.

R3 requires new, explicit Owner authorization covering each intended module
load/unload, automatic PCI probe, MMIO range, and bounded DMA operation. Until
that authority exists, stop before the first mutation. DRV1 authorizes none of
those operations.

## Pinned DRV1 candidate

| Field | Required R3 value |
|---|---|
| Candidate classification | `OFFLINE_QUALIFIED_AHD_PCIE_XDMA_DRIVER_CANDIDATE` |
| Driver source commit | `0a201aab7adb13be079e784c6ed97dfad2ed7764` |
| Driver source tree | `6f079bf086878ddbce1f1ec82fece3039eae6573` |
| Upstream repository | `https://github.com/Xilinx/dma_ip_drivers.git` |
| Upstream commit | `b8466090b4e812e191da9e9305ffb11cb7ace768` |
| Upstream tree | `f9286c5d1bdae57285570ac5c23244d54076b99f` |
| Patch SHA-256 | `415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7` |
| Module filename | `xdma_ahd_pcie.ko` |
| Internal module name | `xdma_ahd_pcie` |
| Module SHA-256 | `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77` |
| Module size | `3296104` bytes |
| Architecture | `x86_64` |
| Vermagic | `7.0.0-29-generic SMP preempt mod_unload modversions ` |
| Candidate alias | `pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*` |
| Signature disposition | `UNSIGNED_ACCEPTABLE_FOR_SEPARATELY_AUTHORIZED_TEST` |
| Final DRV1 evidence commit | `PENDING PUBLICATION`; R3 must cite the exact remotely read-back commit |

Pinned sealing targets:

- remote: `/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko`;
- controller: `C:\FPGA\V41_G2B_DRIVER_ARTIFACTS\G2B_HW0_DRV1_20260906T121539Z\xdma_ahd_pcie.ko`.

R3 must not proceed until the final DRV1 receipt proves that both paths contain
the exact size and SHA-256 above and the evidence commit has passed
commit-pinned remote read-back.

## Pinned DUT and endpoint policy

| Field | Required value |
|---|---|
| DUT | `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111` |
| Machine ID | `0e90f50d9465492b80258da5658446f8` |
| DRV1 boot ID reference | `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` |
| Kernel | `7.0.0-29-generic` |
| Architecture | `x86_64` |
| AHD vendor/device | `10ee:7011` |
| AHD subsystem | `10ee:0007` |
| Exact endpoint modalias | `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00` |
| DRV1 informational BDF | `0000:01:00.0` |
| Expected link | PCIe `5.0 GT/s x1` |
| Expected pre-load binding | `UNBOUND` |
| Installed platform module | internal name `xdma`, alias `platform:xdma` |
| Platform module SHA-256 | `523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490` |
| Platform module load state | must remain `UNLOADED` |

The BDF and boot ID are fresh-state gates, not substitutes for identity. A
changed boot ID is a hard stop because the R2 PRODUCT candidate was retained in
volatile SRAM; do not assume retained FPGA state after a reboot.

## Required R3 preflight

Before any load or other mutation:

1. verify the separately issued R3 authorization and its exact operation,
   MMIO, DMA, rollback, and retry limits;
2. authenticate the exact DUT using the governed connection method and pinned
   host key;
3. verify hostname, machine ID, boot ID, kernel, architecture, Secure Boot,
   locks, concurrent processes, and no unexpected XDMA nodes;
4. verify exactly one AHD endpoint by vendor, device, subsystem vendor,
   subsystem device, and full modalias; record its current BDF and link;
5. require the endpoint to be unbound with no `driver_override`;
6. require both `xdma` and `xdma_ahd_pcie` to be unloaded and the platform
   driver sysfs path to be absent;
7. rehash the exact sealed module in place and require its exact size,
   internal name, vermagic, alias set, dependency set, and signature policy;
8. verify the final DRV1 evidence commit by commit-pinned remote read-back.

Stop on any DUT, boot, kernel, endpoint, link, binding, module, hash, size,
vermagic, alias, dependency, signature-policy, source-authority, lock, or
sealed-copy drift. Do not repair drift inside R3 without new authority.

## Separately authorized load and expected probe model

Only after every preflight gate passes:

1. load only the exact sealed `xdma_ahd_pcie.ko` path;
2. do not install it in `/lib/modules`, do not run `depmod`, and do not use
   generic `modprobe xdma`;
3. do not use `new_id`, `driver_override`, PCI rescan, reset, or a broad manual
   bind;
4. prefer the kernel's automatic probe from the module's single exact PCI
   alias;
5. stop immediately if any endpoint other than exact
   `10ee:7011 / 10ee:0007` binds, or if the intended endpoint does not probe
   cleanly;
6. do not respond to a failed probe with retry, override, unbind/rebind,
   module substitution, reboot, power-cycle, or FPGA reprogramming.

The offline expected model is that loading the PCI driver registers its exact
ID table and probes the already enumerated, unbound AHD endpoint. This is an
offline model, not a DRV1 runtime claim.

## Node-to-BDF proof before MMIO

The module retains standard dynamic XDMA character naming. Expected minimum
functional nodes are `/dev/xdmaN_user` and `/dev/xdmaN_c2h_0`; `N` is dynamic.
Control, event, H2C, or bypass nodes may appear according to the discovered
hardware engines.

Before opening any node:

1. inventory every `/dev/xdma*` node and the active XDMA class;
2. derive each node's sysfs device ancestry;
3. prove the chosen user and C2H nodes resolve to the exact AHD BDF;
4. stop if the index is assumed, ancestry is ambiguous, a node maps to the
   other Xilinx endpoint, or unexpected nodes appear.

Node creation, node names, and node-to-BDF mapping must be recorded as new R3
runtime evidence. DRV1 claims none of them.

## Runtime scope and rollback

MMIO and DMA remain prohibited unless the R3 authorization explicitly pins the
permitted ranges, direction, transfer size, and count. Under that future scope,
R3 should verify runtime PRODUCT identity/readiness first and then perform one
bounded 4,096-byte C2H record capture for `AHD_C2H_TRANSPORT_ABI_V1`.

An unload, rollback, failed-probe recovery, endpoint reset, rescan, reboot,
power-cycle, JTAG action, or FPGA programming operation is not implied by load
authorization. Each requires explicit R3 authority. The platform `xdma` module
must remain unloaded unless coexistence is separately proven.

`DRV1_PLAN_EXECUTED = NO`

`R3_READY = YES_WITH_OWNER_AUTHORIZATION_AND_FINAL_DRV1_PUBLICATION`
