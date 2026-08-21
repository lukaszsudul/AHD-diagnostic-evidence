# Post-driver host classification

```text
HOST_PRECHECK_RAW=PASS_WITH_KNOWN_BAR_SIZE_OBSERVER_PARSE_LIMITATION
ENDPOINT_COUNT=1
ENDPOINT=0000:01:00.0_10EE:7011_SUBSYSTEM_10EE:0007
LINK=GEN1_X1
BAR0_BYTES=131072_FROM_ACCEPTED_LOADER_LOG
BAR1_BYTES=65536_FROM_ACCEPTED_LOADER_LOG
BOUND_DRIVER=xdma
PINNED_MODULE_SHA256=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
PINNED_LOADER_SHA256=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
EXACT_ACCEPTED_NODE_SET=PASS_21_OF_21
XDMA_OPEN_PROCESS_COUNT=0
TASK_DMA_TRANSFERS=0
WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND=NO
KERNEL_AER_XDMA_HEALTH=PASS
```

The driver was loaded through the exact accepted loader immediately after the
reboot. Its loaded version and `srcversion` match the exact pinned module. The
generic module search path names Ubuntu's same-name in-tree module, but that
path was not used; the retained loader transcript proves the explicit pinned
`insmod` chain. The sole targeted kernel match is the expected unsigned
out-of-tree module verification/taint warning. No AER, probe, symbol, or XDMA
runtime failure was reported.

The task-local BAR-size helper retained the already known `0x` parsing
limitation. The same accepted loader transcript independently records BAR0 as
131072 bytes and BAR1 as 65536 bytes, so endpoint geometry is fully proven.
