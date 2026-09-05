# G2B-HW0-PRODUCT-R1 PCIe and XDMA Inventory

T1 result: `BLOCKED`

| Field | Result |
|---|---|
| Bounded automatic recovery | Complete; `AUTO_RECOVERY_FOUND=0` |
| Exact AHD endpoint | `FAIL`, absent after programming |
| Endpoint BDF / vendor-device | `N/A / N/A` |
| AHD LnkCap / LnkSta | `N/A / N/A` |
| PCIe Gen2 x1 gate | `NOT_REACHED` |
| Targeted recovery | `0` operations |
| XDMA gate / exact bind | `NOT_REACHED / NOT_RUN` |
| `xdma` loaded / driver sysfs | `NO / ABSENT` |
| XDMA user / C2H nodes | `N/A / N/A` |
| XDMA node count | `0` |

The accepted AHD root `0000:00:01.1` did not exist. The current AMD switch
subtree includes multiple downstream branches and unrelated Ethernet, USB,
and SATA endpoints. No firmware slot map or other evidence uniquely selected
an AHD branch. Consequently there was no exact root-port sysfs object, endpoint
BDF, or AHD-only subtree on which the conditional recovery or bind could act.

No broad bus rescan, bridge remove, guessed downstream-port rescan, endpoint
reset, config write, module load/unload, or sysfs bind was issued. No unrelated
endpoint was changed. First blocker:
`BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE`.
