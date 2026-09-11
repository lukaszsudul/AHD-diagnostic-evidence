
# Canonical transaction replay

The model parses the exact active stage-2 Marek table, resolves the frozen R3 overlay (AHD1080p25, phase A, CH1, AUTO=0), and applies the physical bring-up executor. Logical bank changes are expanded into a Bank-0xFF write plus verification read before the target write. The fixed preinit and post-init windows are expanded. Two 26-transaction PREPARE passes, four five-transaction BGDCOL rounds, sixteen 30-transaction route/status sessions, and the 13-transaction restore are appended.

Counts:

- Active Marek entries: 122 (121 target writes and 1 delay)
- Resolved public overlay target writes: 66
- Physical autoinit transactions: 275
- Diagnostic runtime transactions from CLEAR state through restore: 565
- Total effective transactions: 840
- Later overwrites recorded: 70
- Unresolved source operations: 0

Unknown masked/runtime values are carried symbolically. No unknown byte is assumed zero.
