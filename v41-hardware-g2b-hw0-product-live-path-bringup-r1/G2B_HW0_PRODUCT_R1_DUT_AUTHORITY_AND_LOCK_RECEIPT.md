# G2B-HW0-PRODUCT-R1 DUT Authority and Lock Receipt

Result: `PASS`

## Authoritative DUT

| Field | Exact value |
|---|---|
| Logical identity | `VCDE-DUT-HOST-01` |
| Authenticated hostname | `VCDE-DUT-1` |
| IPv4 / SSH port | `10.132.1.111 / 22` |
| User | `vcdeagent1` |
| Machine ID | `0e90f50d9465492b80258da5658446f8` |
| Kernel | `7.0.0-29-generic` |
| Boot ID throughout task | `37131b8d-0e38-4b4e-b77a-b3bda55b4e97` |
| ED25519 host-key pin | `SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8` |
| Authentication | `PASS`, sanitized pwfile workflow |

The stale alias `ahd-ubuntu -> developer@10.132.1.227` was excluded. No secret
or transient password file is published. Plink SHA-256 was
`E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915`.

## Exclusivity and lock lifecycle

- Fresh DUT inventory at `2026-09-05T21:55:37Z` found no relevant process,
  lock, XDMA node, or node user. The exact Windows and Linux locks were then
  acquired at `2026-09-05T21:57:13Z` and `2026-09-05T21:57:30Z`.
- A supplemental controller snapshot at `2026-09-05T21:57:34Z`, after those
  acquisitions, found no competing Vivado, hw_server, JTAG, XDMA, or capture
  process and no listener on controller ports 3121, 3122, or 2542.
- One Xilinx Platform Cable USB II firmware loader was present at the expected
  controller USB identity; this established controller presence only.
- Windows lock started `2026-09-05T21:57:13.1232489Z` for task
  `G2B-HW0-PRODUCT-R1`, controller `NBLSUDUL`, this Codex task, and candidate
  SHA `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`.
- Linux lock `/tmp/ahd-g2b-hw0-product-r1.lock` was acquired at
  `2026-09-05T21:57:30Z` and freshly verified before programming.
- Final state was captured while both locks were held.
- Linux release: `PASS` at `2026-09-05T22:17:04.349801Z`; exact lock directory
  absent afterward.
- Windows release: `PASS` at `2026-09-05T22:17:51.0513312Z`; the original
  `.windows.lock` path was removed from the lock namespace and its released
  receipt was retained under `raw/`.
- Final endpoint BDF in both receipts: `N/A_ENDPOINT_NOT_RECOVERED`.

Lock release state: `RELEASED_AFTER_FINAL_STATE_CAPTURE` for both task-local
locks.
