# G2B-HW0-PRODUCT-R3 authorization receipt

- Owner R3 hardware authorization: `GRANTED`
- Module-load authorization: `GRANTED`
- Automatic-bind authorization: `GRANTED`
- Legacy MMIO read authorization: `GRANTED`
- G2B control-write authorization: `GRANTED_LIMITED`
- C2H read authorization: `GRANTED`
- Module-unload authorization: `GRANTED_LIMITED`

The authorization applied only to the exact DUT, exact sealed module, automatic
exact-alias probe, documented read ranges, two exact G2B write offsets/values,
and bounded C2H operations. Actual operations stopped earlier:

| Operation | Actual |
|---|---:|
| exact module loads / unloads | 0 / 0 |
| automatic binds | 0 |
| MMIO reads / writes | 0 / 0 |
| C2H reads | 0 |
| FPGA / Flash programming | 0 / 0 |
| PCI config writes, reset, rescan | 0 |
| reboot / power cycle | 0 / 0 |

No hardware authorization was broadened. The unauthorized controller artifact-
directory boundary crossing is separately classified in the lock receipt and
main report.
