# G2B-HW0-DRV-REUSE0 Exact Modalias Match

## Inputs

- Fresh AHD endpoint: `0000:01:00.0`.
- Fresh modalias: `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00`.
- Governed HDMI module identity: SHA-256 `B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2`.
- Its sole hash-linked alias: `pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*`.
- PCI table construction: `PCI_DEVICE_SUB(0x10ee, 0x7021, 0x10ee, 0xf0a1)`.

## Deterministic comparison

| Field | AHD modalias | HDMI alias requirement | Match |
|---|---|---|---|
| Vendor | `10EE` | `10EE` | `PASS` |
| Device | `7011` | `7021` | `FAIL` |
| Subsystem vendor | `10EE` | `10EE` | `PASS` |
| Subsystem device | `0007` | `F0A1` | `FAIL` |
| Base/subclass/interface | `05/80/00` | wildcard | `PASS` |

The first nonmatching required field is the PCI device ID; the subsystem-device requirement independently fails. Class wildcards cannot override those exact failures.

## Classifications

- `PCI_ALIAS_10EE_7011 = FAIL`.
- `CURRENT_AHD_MODALIAS_MATCH = FAIL`.
- `AHD_PCI_ID_COMPATIBILITY = FAIL_HDMI_SPECIFIC_MATCH`.
- `HDMI_SPECIFIC_DRIVER_CUSTOMIZATION = INCOMPATIBLE`.
- `HDMI_DRIVER_REUSE_DECISION = NOT_REUSABLE_PCI_ALIAS_MISMATCH`.

The exact module would not auto-probe the AHD endpoint. A later forced bind or `driver_override` write is neither an alias match nor authorized here and was not attempted. The separate installed `platform:xdma` alias also cannot match a PCI modalias.
