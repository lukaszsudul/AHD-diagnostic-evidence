# G2B-HW0-DRV1 PCI table proof

## Result

```text
PCI_TABLE_PROOF=PASS
GENERATED_PCI_ALIAS_COUNT=1
EXACT_AHD_MODALIAS_MATCH=PASS
UNINTENDED_BROAD_PCI_ALIASES=0
HDMI_MODALIAS_MATCH=NO
PLATFORM_XDMA_ALIAS_MATCH=NO
```

This is an offline source-and-alias proof. No `new_id`, `driver_override`,
manual bind, module load, endpoint probe, MMIO, or DMA operation was used.

## Source authority

| Field | Value |
|---|---|
| Upstream repository | `Xilinx/dma_ip_drivers` |
| Upstream commit | `b8466090b4e812e191da9e9305ffb11cb7ace768` |
| Upstream tree | `f9286c5d1bdae57285570ac5c23244d54076b99f` |
| Source file | `XDMA/linux-kernel/xdma/xdma_mod.c` |
| AHD patch SHA-256 | `415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7` |
| Built module SHA-256 | `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77` |

## Upstream table before patch

The exact upstream table is broad. It contains 56 unconditional entries and
one additional entry under `INTERNAL_TESTING`:

- Xilinx vendor `10ee` with device IDs
  `9048, 9044, 9042, 9041, 903f, 9038, 9028, 9018, 9034, 9024, 9014,
  9032, 9022, 9012, 9031, 9021, 9011`;
- Xilinx vendor `10ee` with device IDs
  `8011, 8012, 8014, 8018, 8021, 8022, 8024, 8028, 8031, 8032, 8034,
  8038`;
- Xilinx vendor `10ee` with device IDs
  `7011, 7012, 7014, 7018, 7021, 7022, 7024, 7028, 7031, 7032, 7034,
  7038`;
- Xilinx vendor `10ee` with device IDs
  `6828, 6830, 6928, 6930, 6a28, 6a30, 6d30, 4808, 4828, 4908, 4a28,
  4b28, 2808`;
- AWS vendor `1d0f`, devices `f000` and `f001`;
- under `INTERNAL_TESTING`, vendor/device `1d0f:1042`.

All default upstream entries use `PCI_DEVICE`, including the relevant broad
entry:

```c
{ PCI_DEVICE(0x10ee, 0x7011), },
```

That entry does not restrict subsystem vendor/device and is therefore not
acceptable for AHD DRV1.

## Exact patched table

The patch removes every upstream PCI identity and replaces the table body with
one exact subsystem entry plus the terminator:

```c
static const struct pci_device_id pci_ids[] = {
	{ PCI_DEVICE_SUB(0x10ee, 0x7011, 0x10ee, 0x0007), },
	{0,}
};
MODULE_DEVICE_TABLE(pci, pci_ids);
```

`PCI_DEVICE_SUB` constrains all four identity fields:

| Field | Required value |
|---|---|
| PCI vendor | `0x10ee` |
| PCI device | `0x7011` |
| PCI subsystem vendor | `0x10ee` |
| PCI subsystem device | `0x0007` |

The entry does not constrain class, subclass, or programming interface, so the
generated class components are wildcards. This does not broaden vendor/device
or subsystem matching.

## Generated binary alias

Static `modinfo` of the byte-identical candidate reports exactly one alias:

```text
pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*
```

No vendor-only, device-only, HDMI, AWS, other Xilinx-device, or platform-bus
alias remains.

## Offline match proof

The verification script performs anchored wildcard matching of each complete
modalias against every generated module alias. Its exact results are:

| Test | Input modalias | Expected | Actual | Result |
|---|---|---|---|---|
| AHD exact modalias | `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00` | MATCH | MATCH | PASS |
| AHD alternate subsystem | `pci:v000010EEd00007011sv000010EEsd00000008bc05sc80i00` | NO_MATCH | NO_MATCH | PASS |
| Synthetic HDMI-ID class variant | `pci:v000010EEd00007021sv000010EEsd0000F0A1bc05sc80i00` | NO_MATCH | NO_MATCH | PASS |
| Generic Xilinx PCI device | `pci:v000010EEd00009048sv000010EEsd00000000bc05sc80i00` | NO_MATCH | NO_MATCH | PASS |
| Platform XDMA | `platform:xdma` | NO_MATCH | NO_MATCH | PASS |
| Other installed Xilinx endpoint `0000:0b:00.0` | `pci:v000010EEd00007021sv000010EEsd0000F0A1bc07sc00i01` | NO_MATCH | NO_MATCH | PASS |

For the positive case, vendor `10ee`, device `7011`, subsystem vendor `10ee`,
and subsystem device `0007` all match literally; `bc05sc80i00` is accepted by
the class wildcards. The alternate AHD subsystem fails at `sd00000008`; HDMI
fails at both device and subsystem device; generic `10ee:9048` fails at the
device; `platform:xdma` fails at the bus/prefix.

The verifier's source label for the synthetic `bc05sc80i00` row uses
"HDMI authoritative identity" as shorthand, but HDMI authority pins the
wildcard alias `pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*`, not that
class tuple. This report and the alias matrix therefore label that row as a
synthetic HDMI-ID class variant. The independently tested installed HDMI
endpoint modalias ending `bc07sc00i01` is the exact fresh observation.

## Proof boundary

This proves that the module's generated offline PCI alias selects the intended
AHD identity and excludes the tested negative identities. It does not claim
that Linux will successfully load the module or that `probe_one` will complete
against hardware. That runtime proof belongs to a separately authorized R3.
