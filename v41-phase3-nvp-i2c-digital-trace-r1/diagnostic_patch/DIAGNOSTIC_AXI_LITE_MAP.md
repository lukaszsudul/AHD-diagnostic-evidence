# Ephemeral read-only diagnostic AXI-Lite window

The accepted 53-register control plane remains byte-for-byte unchanged at
`0x0000..0x00E0`. The preserved application slots occupy `0x0000..0x1FFF`.
The observer therefore overlays only the previously unmapped/reserved-zero
range below. All addresses remain in BAR0's 128 KiB aperture.

- Status/identity: `0x2000..0x20FF`
- Chronological trace: `0x3000..0xAFFF`
- Trace sample `n`: lower word at `0x3000 + 8*n`, upper word at
  `0x3004 + 8*n`

Trace reads are remapped from the physical circular BRAM to chronological
order. Logical sample 3072 is the trigger. Reads before freeze return zero.
Writes anywhere in either diagnostic range are acknowledged by the existing
AXI-Lite transport but have no state effect and are not forwarded.

| Offset | Name |
|---:|---|
| 0x2000 | `DIAG_MAGIC` = `0x4E565054` (`NVPT`) |
| 0x2004 | schema version |
| 0x2008 | flags: bit0 ephemeral, bit1 not release candidate |
| 0x200C | status: armed, triggered, frozen, full, overflow |
| 0x2010 | trigger reason |
| 0x2014 | sample clock Hz |
| 0x2018 | sample depth |
| 0x201C | sample width bits |
| 0x2020 | pre-trigger count |
| 0x2024 | post-trigger count including trigger |
| 0x2028 | logical trigger index |
| 0x202C | final physical write index |
| 0x2030 | overflow |
| 0x2034..0x2044 | base functional commit W0..W4 |
| 0x2048..0x2064 | diagnostic patch SHA-256 W0..W7 |
| 0x2068 | first error valid |
| 0x206C | first error phase/code |
| 0x2070 | first error step |
| 0x2074 | first error metadata bank |
| 0x2078 | first error physical bank |
| 0x207C | first error register |
| 0x2080 | first error value |
| 0x2084 | valid sample count |
| 0x2088 | physical trigger index |
