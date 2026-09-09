# DIAG1-R1 retained-state cleanup

- Initial pending AIO: 1023 (Owner-confirmed)
- Exact C2H holder: PID 3522, expected DIAG1-R1 drain-helper lineage
- Initial module refcount: 1
- SIGTERM signals sent: exactly 1
- Result after 12 seconds: helper still present, C2H still held, refcount 1
- Authorized fallback: exactly one graceful warm reboot
- Forced signal/unload: none
- Post-reboot old helper: absent
- Post-reboot `xdma_ahd_pcie`: absent
- Post-reboot `/dev/xdma0_user` and `/dev/xdma0_c2h_0`: absent
- Exact DIAG1-R1 Linux/controller locks: released
- Cleanup result: **PASS**
- Cleanup method: `ONE_GRACEFUL_WARM_REBOOT`

The reboot was cleanup-only and occurred before any FIX1 bitstream existed.
