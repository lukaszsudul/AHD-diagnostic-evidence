# Bootstrap host-cycle observer recovery audit

The single authorized bootstrap warm reboot was submitted once and was not
repeated. The original local TCP observer contained a runtime whitespace typo
in each `return` statement. Its first probe entered the false/exception branch,
which proves TCP/22 was not connected during the reboot interval, then failed
before it could seal its normal receipt. The later accepted pre-loader SSH
session proves the host returned with a different boot ID and exact kernel 29.

Only the task-local read-only TCP helper syntax was corrected (`return$false`
to `return $false`, and `return$client.Connected` to
`return $client.Connected`) for future Arm-A/Arm-B cycles. No reboot, FPGA,
driver, PCIe, MMIO, DMA, JTAG-frequency, or scientific behavior was changed.

```text
INITIAL_OBSERVER_SHA256=35E1406DBBA4F943274E1C3FDF657A962F48952CD0E75ED1DEF2222D38FB9D0F
CORRECTED_OBSERVER_SHA256=097B25287F8BD261C48F9718C75DD7618F5E908293047C8E61B5D9DBA3A64443
POWERSHELL_PARSE_ERRORS_AFTER_FIX=0
HOST_DOWN_PROOF=TCP22_FALSE_OR_EXCEPTION_BRANCH
HOST_RETURN_PROOF=PRELOADER_SSH_PASS
BOOT_ID_CHANGED=YES
SECOND_WARM_REBOOT=NO
HOST_CYCLE_GATE=PASS_HOST_DISAPPEARED_AND_RETURNED
```
