# G2B-HW0-DRV-REUSE0 — HDMI SSOT driver authority

## Current SSOT identity

```text
HDMI_SSOT_REPOSITORY=lukaszsudul/HDMI-diagnostic-evidence
HDMI_SSOT_CANONICAL_BRANCH=FPGA_HDMI
HDMI_SSOT_REMOTE_HEAD=2317361094d599717a9509bd9d508efd58f6d1a2
HDMI_SSOT_REMOTE_TREE=7bf324a9afb02d8da6947cc0748b16e07d1d0c55
HDMI_PROJECT_STATE_REVISION=1
HDMI_STATE_TYPE=CURRENT_ACCEPTED_STATE
HDMI_ACCEPTED_BY_ROLE=OWNER_ARCHITECT
HDMI_DRIVER_AUTHORITY=VERIFIED
HDMI_DRIVER_AUTHORITY_AMBIGUOUS=NO
```

The current commit subject is `docs: establish HDMI SSOT revision 1 after board
0006 qualification`. Its parent is the bootstrap evidence commit
`3143b8775be671381ca19f5feae042b4daa9152d`.

## Accepted DUT driver identity

The SSOT, accepted C5 deployment source, and accepted board-0006 evidence agree
on one DUT module identity:

| Field | Accepted value | Authority |
|---|---|---|
| Role | `DUT` | `project-current-state/PROJECT_STATE.json` |
| Kernel | `7.0.0-29-generic` | `PROJECT_STATE.json`, `ACTIVE_BASELINES.md` |
| Governed deployed path | `/opt/fpga-hdmi-lab/driver/xdma.ko` | C5 `host/lab_service/deploy/lab-service.env` and `install-lab-service.sh` |
| Size | `3295008` bytes | SSOT and E-0006 result |
| Expected SHA-256 | `B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2` | SSOT and E-0006 result |
| Internal name | `xdma` | Historical exact-binary evidence |
| Bus type | `PCIE_XDMA` | PCI driver source and the exact PCI alias |
| Vermagic | `7.0.0-29-generic SMP preempt mod_unload modversions ` | Historical exact-binary build/use evidence |
| Exact alias count | `1` | SSOT and historical exact-binary evidence |
| Sole alias | `pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*` | SSOT and historical exact-binary evidence |
| AHD `10ee:7011` alias | `ABSENT` | SSOT and historical exact-binary evidence |

The accepted C5 source is:

```text
HDMI_ACCEPTED_SOURCE_REPOSITORY=lukaszsudul/FPGA_HDMI
HDMI_ACCEPTED_SOURCE_BRANCH=codex/demo-r0f-b123-universal-live-20260830
HDMI_ACCEPTED_SOURCE_COMMIT=6fd13fe7994e454065448303850b8eb9fd140603
HDMI_ACCEPTED_SOURCE_TREE=cab9a2d15a81f7687cdbee1c8e700744f14e8b64
HDMI_ACCEPTED_SOURCE_DIRECTORY=demo/r0f_b
```

The current SSOT maps the accepted hardware evidence as:

```text
HDMI_DRIVER_EVIDENCE_REPOSITORY=lukaszsudul/HDMI-diagnostic-evidence
HDMI_DRIVER_EVIDENCE_COMMIT=3143b8775be671381ca19f5feae042b4daa9152d
HDMI_DRIVER_EVIDENCE_TREE=411ad90f43a17ad25445439acf476124546bea95
HDMI_DRIVER_EVIDENCE_DIRECTORY=review/ssot_bootstrap_20260904
```

The principal accepted records are
`BOARD0006_FLASH_B1_B2_RESULT.json`, `BOARD0006_B1_MANIFEST.jsonl`,
`BOARD0006_B2_MANIFEST.jsonl`, `BOARD0006_EXTERNAL_LIVE100_RESULT.json`, and
`BOARD0006_EXTERNAL_MANIFEST.jsonl`.

## Distinct kernel-specific binaries

The HDMI SSOT also identifies a USB-environment binary:

| Role | Kernel | Size | SHA-256 |
|---|---|---:|---|
| DUT | `7.0.0-29-generic` | 3295008 | `B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2` |
| USB | `6.8.0-100-generic` | 3018800 | `617429B9A751ECE3A3FDAF9D684C2A6445DAE94CB4F47782C3D0CBC7EE04D82A` |

These are not interchangeable. The USB binary is not the DUT reuse candidate.
The existing Linux platform-bus module with internal name `xdma` is also a
different artifact: its alias is `platform:xdma`, not a PCI alias.

## Current artifact presence versus historical authority

The authority-scoped current DUT check did not find the governed module at its
deployed path. Therefore:

```text
HDMI_DRIVER_DUT_PATH=/opt/fpga-hdmi-lab/driver/xdma.ko
HDMI_DRIVER_EXPECTED_SHA256=B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2
HDMI_DRIVER_ACTUAL_SHA256=NONE_ARTIFACT_NOT_FOUND
HDMI_DRIVER_BINARY_IDENTITY_CURRENT=NOT_FOUND
HISTORICAL_EXACT_BINARY_IDENTITY=VERIFIED
```

The driver contract permits an immutable, capture-bound staging tree only at
`/run/r0f_a/<capture-id>/`, containing:

```text
R0F_A_XDMA_MODULE_BUILD_MANIFEST.txt
XDMA/linux-kernel/xdma/xdma.ko
```

The build-manifest SHA-256 is
`99FAE64B07D54D695361BFCF1034237B879399CD8E8FFF4E403C57BBE401F74A`.
This `/run` namespace is ephemeral; its contract is not evidence that a staging
instance survives now. No other persistent absolute DUT build-output path is
published as authoritative.

Current absence does not invalidate the historical evidence tying the exact
B08C... binary to source, build, load, binding, nodes, and DMA. Conversely,
historical proof does not make a missing current file available for static
inspection or reuse.

## Qualification and reuse policy

`project-current-state/COMPATIBILITY_MATRIX.csv` classifies the DUT XDMA
dependency as `FROZEN` for kernel `7.0.0-29-generic` and the restricted
`7021/f0a1` module. `CURRENT_INTERFACES.md` freezes dynamic HDMI BDF/`xdmaN`
discovery and explicitly excludes `7011/AHD` from the HDMI host path.

The module was deliberately built to match only:

```text
vendor/device=10ee:7021
subsystem=10ee:f0a1
```

It deliberately cannot match the AHD endpoint:

```text
vendor/device=10ee:7011
subsystem=10ee:0007
```

Thus the current SSOT does not authorize or support reuse of this exact binary
for AHD. It supports only HDMI use under a separate hardware authorization.

```text
HDMI_DRIVER_REUSABLE_OUTSIDE_HDMI_PROJECT=NO_FOR_AHD_EXACT_BINARY
PCI_ALIAS_10EE_7011=FAIL
CURRENT_AHD_MODALIAS_MATCH=FAIL
AHD_PCI_SUBSYSTEM_COMPATIBILITY=FAIL_HDMI_SPECIFIC_MATCH
HDMI_DRIVER_REUSE_DECISION=NOT_REUSABLE_PCI_ALIAS_MISMATCH
```

## Metadata not established by current SSOT

The SSOT and historical records do not publish or currently reverify all of:

- ELF header output for the now-missing DUT file;
- SHA-512 of the exact DUT file;
- actual binary `srcversion` and `retpoline` fields;
- dependency list from `modinfo`;
- signer, signature key, or signature algorithm;
- current Secure Boot or lockdown compatibility.

These fields remain `UNRESOLVED` rather than being inferred from the filename,
source, or historical load success.

## Explicit non-claims

- SSOT revision 1 is project-state authority, not hardware authorization.
- Historical `PASS` is not proof that the module remains on the DUT.
- A matching filename is not a matching artifact.
- The USB binary and platform-bus `xdma` module are not substitutes.
- No current module load, binding, node, MMIO, or DMA state is asserted by this
  authority record.
- No AHD source, HDMI source, or SSOT change is authorized by this record.

