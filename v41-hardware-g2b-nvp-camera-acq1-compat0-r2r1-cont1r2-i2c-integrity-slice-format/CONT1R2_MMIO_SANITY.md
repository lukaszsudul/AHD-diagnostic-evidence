# CONT1R2 MMIO Sanity

- SCAN1: `16/16 PASS`
- ACQ: `16/16 PASS`
- `0xFFFFFFFF` reads: `0`
- MMIO timeouts: `0`
- Functional NVP writes: `0`

The first runtime invocation stopped before MMIO because isolated module bootstrap was incomplete. The second stopped before MMIO on unprivileged device access. The governed sudo execution then passed the unchanged identity/MMIO contract. Neither stopped attempt performed an NVP operation.
