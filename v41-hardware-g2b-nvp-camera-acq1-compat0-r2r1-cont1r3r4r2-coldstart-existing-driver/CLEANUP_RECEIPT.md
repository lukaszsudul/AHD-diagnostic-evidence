# Safe cleanup receipt

After hard-stop registers and persisted data were secured, one governed
SCAN1 `ACK_CLEAR` write (`0x1200C=0x00000002`) changed the scanner from
`0x00000C18` to clean idle `0x00000011`; ACQ stayed idle at `0x00800011`.
Entry and exit bank both had valid Bank 0 (`0x00000100`), the restore flag
was set, and experimental ACQ functional/unauthorized write counters were
zero. No further ONESHOT, I2C command or camera capture occurred.

The task-owned AHD module had refcount zero and no open target user/C2H-0
node holders. One normal unload of the exact module succeeded; afterward
`xdma_ahd_pcie`, the XDMA class and `/dev/xdma*` nodes were absent, while the
`10ee:7011` AHD function remained enumerated but unbound. The protected
`10ee:7021` function was still absent; it was not manipulated. No pending
systemd job was observed. Task-created controller and DUT locks were
released in that order: DUT first, controller last. The controller lock
receipt was retained by a recoverable move into the task run's authority
directory; the active lock path is absent.

The exact diagnostic image is left in volatile SRAM. There was no final
reboot, power cycle, Flash programming, driver binary edit, driver namespace
change, autostart edit, mode/EQ/slice write, DMA video transfer or frame
capture. A separate stream-status register was not independently sampled at
final cleanup, so `stream disabled` is supported by the no-stream campaign
and untouched transport controls rather than claimed as a new register
measurement. Task-owned pending AIO is zero by no C2H open/transfer and
closed MMIO handles; no unrelated process was killed or unloaded.
