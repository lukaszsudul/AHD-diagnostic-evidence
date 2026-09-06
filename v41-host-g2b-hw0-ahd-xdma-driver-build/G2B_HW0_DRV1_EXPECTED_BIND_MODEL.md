# G2B-HW0-DRV1 expected bind model

## Classification

```text
BIND_MODEL=OFFLINE_SOURCE_AND_ALIAS_DERIVATION
DRIVER_BUS=PCI
AUTOMATIC_EXACT_ALIAS_PROBE_EXPECTED=YES
NEW_ID_REQUIRED=NO
DRIVER_OVERRIDE_REQUIRED=NO
LIVE_BIND_CLAIM=NO
```

This model describes expected future kernel behavior if the exact candidate is
loaded under separate R3 authorization. It is not a statement that the module
has loaded or that its probe has completed.

## Pinned identities

| Field | Required value |
|---|---|
| Module file | `xdma_ahd_pcie.ko` |
| Internal module name | `xdma_ahd_pcie` |
| Module SHA-256 | `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77` |
| Module size | `3296104` bytes |
| Kernel | `7.0.0-29-generic` |
| Architecture | `x86_64` |
| Candidate PCI alias | `pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*` |
| AHD modalias | `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00` |

## Source-derived registration sequence

The exact patched `XDMA/linux-kernel/xdma/xdma_mod.c` provides:

- a `pci_device_id` table containing only
  `PCI_DEVICE_SUB(0x10ee, 0x7011, 0x10ee, 0x0007)`;
- `struct pci_driver pci_driver` with name `xdma_ahd_pcie`, the exact
  `pci_ids` table, `probe_one`, `remove_one`, and the upstream error handlers;
- `xdma_mod_init`, which initializes the standard XDMA character-device class
  and then calls `pci_register_driver(&pci_driver)`;
- `probe_one`, which retains the upstream device-open, engine-discovery, and
  character-device creation behavior.

Linux PCI driver registration evaluates already-enumerated, currently unbound
devices against the registered `id_table`. Therefore, if the endpoint remains
already enumerated, unbound, and exactly identified when a separately
authorized R3 loads the exact module, the expected path is an automatic call to
`probe_one`. No dynamic-ID insertion, override, or broad manual binding is
required.

## Expected matching outcomes

| Device/modalias | Expected future discovery result | Reason |
|---|---|---|
| Exact AHD `10ee:7011 / 10ee:0007` | Candidate matches; automatic probe expected | All four PCI/subsystem identity fields match the only table entry. |
| `10ee:7011` with any other subsystem | No match | Exact subsystem device `0007` is required. |
| HDMI `10ee:7021 / 10ee:f0a1` | No match | Device and subsystem device differ. |
| Generic/other Xilinx endpoint | No match | Candidate has no broad vendor or other-device entry. |
| `platform:xdma` device | No match | Candidate registers a PCI driver and exports no platform alias. |

The offline alias matrix executed all of these classes, including the current
other installed Xilinx endpoint modalias, with the required results.

## Dynamic node consequence

If and only if the unmodified upstream probe succeeds, standard XDMA
character-device naming is expected. Device index allocation remains dynamic:
the first registered XDMA PCIe device receives 0, and a later device receives
the last index plus one. The module rename does not rename class `xdma` or the
`/dev/xdmaN_*` prefix.

R3 must discover the actual index and prove node-to-BDF ancestry before using a
node. It must not assume `/dev/xdma0_*` belongs to the AHD endpoint.

## Observed pre-build state

Read-only DRV1 inventory observed the exact AHD endpoint at informational BDF
`0000:01:00.0`, with Gen2 x1 link, no bound driver, no override, neither
`xdma` nor `xdma_ahd_pcie` loaded, and zero `/dev/xdma*` nodes. The build did
not depend on endpoint presence and did not alter that state.

## Required R3 stops

A separately authorized R3 must stop before load or use if the DUT, boot,
kernel, architecture, module path/hash/size/name/vermagic, endpoint identity,
subsystem, modalias, current binding, or authorization has drifted. It must also
stop if:

- the installed platform module `xdma` is loaded;
- any endpoint other than exact `10ee:7011 / 10ee:0007` binds;
- the AHD endpoint fails to bind cleanly;
- a created node cannot be proven to map to the exact AHD BDF.

R3 should prefer automatic probe from the built exact alias. It must not use
`new_id`, `driver_override`, or a broad manual bind to bypass a mismatch.

## DRV1 non-claims

DRV1 did not install, load, or unload either module; bind or unbind an endpoint;
create device nodes through a live probe; access MMIO; execute DMA; reset or
rescan PCI; reboot; power-cycle; or program the FPGA. Runtime load, probe,
node-to-BDF, MMIO identity, and C2H transfer remain unproven until R3.
