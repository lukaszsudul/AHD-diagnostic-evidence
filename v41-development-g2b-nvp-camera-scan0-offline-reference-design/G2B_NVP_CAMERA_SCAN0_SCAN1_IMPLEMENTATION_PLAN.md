# Ordered SCAN1-R1 implementation plan

No implementation occurs in SCAN0. A later authorized task follows this order:

1. Create `diag/v41-g2b-nvp-camera-scan1-r1` in a fresh worktree at exact diagnostic commit `fc37d815b5d64ef90dfbd99c57ae4cc09567b56f`; reverify branch/HEAD/tree/clean state.
2. Limit source scope to new `rtl/g2b/g2b_nvp_camera_scan1.sv`, new manifest package/ROM, the diagnostic-only fixed-master error-cause output, top-level compile-time arbitration/decode wiring, new host decoder/runtime files and profile-specific tests/build scripts. Do not touch PRODUCT RTL behavior, active XDC, SSOT, G2B ABI, capture format or prior evidence.
3. Add compile-time `ENABLE_NVP_CAMERA_SCAN1=0` default and mutual-exclusion assertions against DIAG1/executor. Absent scanner/executor releases remain constant high.
4. Instantiate the frozen 82-entry ROM and ten group descriptors; make 0xFF the only NVP write reachable from scanner RTL.
5. Integrate group-granular arbiter priority autoinit > executor > scanner and finish-group preemption.
6. Implement the frozen FSM, at-most-one retry, entry-bank fallback/degraded policy, exact restore and one frozen snapshot.
7. Intercept `0x12000..0x123FF` only in SCAN1 and implement the frozen header, group directory, manifest SHA and entry array with correct write responses.
8. Build the hash-pinned host runtime bundle and decoder; pass isolated positive/negative import tests.
9. Run all simulation/fault-injection/MMIO/noninterference tests before Vivado.
10. Under separate build authority, run one fresh Vivado build and evidence closure.
11. Under separate hardware authority, qualify 10,000 ONESHOT scans, bank restore and byte-exact video noninterference.
12. Restore/verify PRODUCT profile independently; do not infer PRODUCT from diagnostic success.
