# Host discovery manual review

```text
BAR0_BYTES=131072
BAR1_BYTES=65536
BAR_GEOMETRY_METHOD=RAW_SYSFS_RESOURCE_PLUS_LSPCI_READ_ONLY_SUPPLEMENT

LOADED_XDMA_PROVENANCE=PASS_EXACT_PINNED_ARTIFACT_AND_ACCEPTED_LOAD_CHAIN
LOADED_XDMA_VERSION=2025.2.0
LOADED_XDMA_SRCVERSION=E2C680AF6D8BF5E3A2F6ACB
PINNED_MODULE_SRCVERSION=E2C680AF6D8BF5E3A2F6ACB
CURRENT_BOOT_ID_MATCHES_RETAINED_ACCEPTED_LOAD_SESSION=YES
WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND=NO

XDMA_ALL_NODES_CLASSIFICATION=PASS_EXACT_ACCEPTED_21_NODE_SET
XDMA_OPEN_PROCESS_COUNT=0
TASK_C2H_TRANSFERS=0
TASK_H2C_TRANSFERS=0
DMA_ACTIVITY=0

TARGETED_KERNEL_MATCH_COUNT=1
TARGETED_KERNEL_MATCH_CLASSIFICATION=EXPECTED_UNSIGNED_OUT_OF_TREE_MODULE_TAINT_WARNING
AER_FATAL_MATCHES=0
AER_NONFATAL_MATCHES=0
AER_UNCORRECTED_MATCHES=0
XDMA_RUNTIME_FAILURE_MATCHES=0
PCIE_DEVICE_STATUS_ERRORS=0
KERNEL_AER_XDMA_HEALTH=PASS
```

The installed same-named in-tree platform-driver file reported by an
unqualified `modinfo -n xdma` is not the loaded module: the live module exposes
the exact pinned version and source-version, remains continuous with the
retained accepted-loader boot session, and owns only the exact expected PCIe
endpoint. The one kernel match is the already-loaded unsigned out-of-tree
module taint warning, not a critical AER or runtime failure.

The initial observer script left BAR sizes blank because its arithmetic parser
did not strip Linux's `0x` prefix. No state changed. The separate raw resource
table and `lspci -vv` read-only supplement proves Region 0 is 128 KiB and
Region 1 is 64 KiB.
