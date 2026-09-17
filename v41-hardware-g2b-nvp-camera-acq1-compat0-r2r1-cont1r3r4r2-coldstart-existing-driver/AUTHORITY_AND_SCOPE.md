# Exact authority and scope

- DUT: `10.132.1.111:22`, pinned host key
  `SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8`, hostname
  `VCDE-DUT-1`, machine ID `0e90f50d9465492b80258da5658446f8`.
- Project state revision at start and end: `9`; project-state JSON SHA-256
  `B441296763785CB0FD8764DB78175F1F0D2A5DA891D174FEF364417901C6A6C2`.
  No SSOT/META/PRODUCT write was made.
- Exact `.bit`: 2,192,144 bytes, SHA-256
  `CD80C84E17467BCB03DEE58DC7FF64D50FD2CB6E5C409E21F871C3E05052BA09`.
- Existing routed DCP: 17,469,233 bytes, SHA-256
  `C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2`.
- Existing driver `.ko`: 3,296,104 bytes, SHA-256
  `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`.
- Inherited 33-file bundle manifest SHA-256
  `B9D3A57E8AA910675944F3AB384FED4073101A178829E8C778403068C58592A2`;
  34-file task-local bundle manifest SHA-256
  `ABD3E857EDE3114F1AB1BE3C8389A502E6F9E8D996B34E9B019382E2415F7BEF`.

No synthesis, implementation, timing/CDC/DRC, bitstream generation, driver
build or source edit occurred. SCAN1 was read-only except its governed
ONESHOT/ACK MMIO controls and bank-selection/restoration within the scanner.
No experimental functional NVP write, C2H transfer, mode/EQ/slice action or
camera capture was authorized or performed.
