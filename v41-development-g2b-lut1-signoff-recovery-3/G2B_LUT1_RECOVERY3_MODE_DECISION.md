# Recovery mode decision

`RECOVERY_MODE = ROUTED_DCP_REUSE`

The META-6 change is constraints-only: RTL and netlist are unchanged, the accepted routed DCP remains valid, and the candidate constraints were applied post-route with timing-database updates. No full rebuild was technically required or executed.

- Routed DCP SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`
- Device: `xc7a35tcsg325-2`
- Vivado: `2025.2`, SW build `6299465`

