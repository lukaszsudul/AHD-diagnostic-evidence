# G2B-HW0-PRODUCT-R3R2 — AUTHORIZATION_RECEIPT

Owner decision: G2B-HW0-PRODUCT-R3R2 supplied in this task. GRANTED.
Fresh root and helper only. Exactly three sessions maximum, no gate retries.
Reads: aligned 32-bit little-endian 0x0000..0x0030, 0x0080..0x00B4, 0x3800..0x3858.
Writes: CONTROL 0x380C exactly 0,1,4; SNAPSHOT 0x3844 exactly 1; post-reset conditional ERROR_STATUS W1C 0x383C exactly the immediately preceding active mask &0x38, once/session and at most three. Nonfatal W1C and statistics clear DENIED.
Mandatory disabled negotiation, reset, quiescent completion within five seconds, epoch +1, conditional exact fatal W1C, final baseline snapshot, reader ready, explicit enable, bounded capture, disable/drain. No mid-epoch or clean-boot exception.
One exact insmod, one normal unload if safe, read-only JTAG inventory and no FPGA programming were authorized. No persistent driver installation, modprobe, depmod, manual PCI binding, H2C, legacy writes, source/SSOT/prior-evidence changes, reboot or power cycle was authorized.
Actual capture sessions started: 0. Reset/enable/W1C/snapshot writes: 0/0/0/0. T3 launch timed out while DUT continuity was lost; no retry.
