# Cleanup receipt

## Inherited DIAG1-R1 state

- Exact drain-helper identity: PASS
- Exactly one SIGTERM: YES
- Helper exit within 12 seconds: NO
- Exactly one graceful cleanup reboot: YES
- Old helper/holder/module/nodes after reboot: absent
- Exact old task locks: released

## Fresh FIX1 state

- FIX1 driver loaded: NO
- FIX1 MMIO/DMA opened: NO
- Fresh Linux lock released: PASS
- Fresh controller lock released: PASS
- Credential remnants: 0
- Forced kill/unload: NO
- Final pending FIX1 AIO: N/A (capture not reached; no helper launched)
