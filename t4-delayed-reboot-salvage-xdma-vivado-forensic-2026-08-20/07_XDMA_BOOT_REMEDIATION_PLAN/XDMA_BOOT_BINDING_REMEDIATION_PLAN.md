# XDMA boot-binding remediation plan (not installed)

## Finding

The pinned PCIe XDMA module is not configured for boot. Ubuntu's same-named in-tree `platform:xdma` module is what an unqualified `modprobe xdma` resolves, creating a module-name collision risk.

## Proposed fail-closed mechanism

Prepare an owner-reviewed helper plus oneshot systemd unit. The helper should:

1. Require kernel `7.0.0-29-generic` and exactly one endpoint matching `10ee:7011`, subsystem `10ee:0007`, at the approved BDF policy.
2. Require the pinned artifact at its sealed path and SHA-256 `1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A`.
3. Verify module name, PCI alias, vermagic, and Secure Boot/signature policy before loading.
4. Refuse if any same-name module is already loaded; also prove its on-disk path rather than accepting `modprobe` resolution.
5. Load the exact artifact by absolute path only. Permit normal PCI probe; never remove, rescan, reset, use `driver_override`, or program the FPGA.
6. Wait boundedly for `/dev/xdma0_user` and `/dev/xdma0_control`; verify the endpoint driver symlink, module metadata, node major/minor, and kernel health.
7. Write a concise journal PASS or an explicit fail-closed reason.

The unit should run after local filesystems and udev are available and before any AHD consumer. It must use `RemainAfterExit=yes`, a bounded timeout, and no automatic restart loop.

## Rollback

Disable the proposed unit, remove only the proposed unit/helper/config files, reload systemd configuration, and reboot only in a separately authorized maintenance window. Do not unload an in-use driver.

## Validation checklist

- Cold/warm boot validation must be separately authorized.
- Confirm exact kernel, artifact hash, vermagic, alias, endpoint count/IDs, binding, nodes, and journal PASS.
- Confirm no reset/rescan/programming action and no arbitrary same-name module acceptance.

Nothing in this plan was installed or enabled during this task.

