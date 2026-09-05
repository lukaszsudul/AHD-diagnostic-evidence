# G2B HW0 PRODUCT Pre-program Inventory

Result: `NOT_REACHED_DUE_TO_EARLIER_GATE`

The mandatory authorization review stopped execution before fresh JTAG and
PCIe inventories.

## Windows/JTAG

- Vivado installation authority: version `2025.2`, build `6299465` from the
  accepted candidate evidence.
- Fresh hardware-server connection: `NOT_RUN`.
- Fresh cable/chain/IDCODE/DONE inventory: `NOT_RUN`.
- Local competing Vivado/hardware-server process: none observed before stop.

## Linux/PCIe

- Authoritative host binding: identified from accepted prior receipts and
  intentionally sanitized in this public package.
- Fresh authenticated system inventory: `NOT_RUN`.
- Fresh `lspci`, topology, link, AER, driver, sysfs, device-node, kernel-log,
  and open-owner inventory: `NOT_RUN`.
- Historical mappings were treated only as discovery authority, never as
  current device-node proof.

No endpoint, BDF, `/dev/xdma*` node, or JTAG device was selected for action.
