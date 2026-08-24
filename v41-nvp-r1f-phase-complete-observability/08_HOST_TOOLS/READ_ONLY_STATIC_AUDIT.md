# R1f host reader static read-only audit

```text
AUDIT_RESULT=PASS
LIVE_OPEN_FLAGS=O_RDONLY_OR_O_CLOEXEC
DEVICE_ACCESS_PRIMITIVE=os.pread
MMIO_WRITE_PRIMITIVE_PRESENT=NO
O_RDWR_PRESENT=NO
O_WRONLY_PRESENT=NO
PWRITE_PRESENT=NO
MMAP_PRESENT=NO
IOCTL_PRESENT=NO
AXI_LITE_WRITE_PATH_PRESENT=NO
DMA_PATH_PRESENT=NO
```

The read inventory is a constant tuple of 1,488 unique aligned offsets:

```text
LOCAL_WORDS=57
R1E_PAGE_WORDS=40
R1F_WORDS=1368
LEGACY_DETAIL_WORDS=23
TOTAL_UNIQUE_WORDS=1488
```

Four already-in-range 48-bit pairs receive bounded high/low/high coherence
reads; no new address range is introduced. Evidence output uses normal local
file creation after decoding and is separate from the `O_RDONLY` device file
descriptor.

Static token fixtures reject any introduction of `os.pwrite`, `os.write(`,
`O_RDWR`, or `O_WRONLY` in the reader. Manual inspection also found no mmap,
ioctl, subprocess, module-control, PCIe reset/rescan, or DMA interface.

The inherited R1e reader remains unmodified:

```text
R1E_READER_SHA256=0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037
R1E_READER_GIT_STATUS=UNCHANGED
```
