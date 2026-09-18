# C3-PNR1 ordinary DRC and methodology warnings

The current routed reports have **zero Error and zero Critical Warning** findings in both DRC and methodology. Ordinary warnings remain visible and are not silently inherited from the older R2R1 build.

| Report | Current ordinary warnings | R2R1 accepted-build count | Current additions |
|---|---:|---:|---|
| DRC | 24 | 14 | `IOSR-1` 2 on `nvp_scl`/`nvp_sda` reset sharing; `REQP-1840` 8 on the SCAN1 `entry_index_reg_rep` RAMB18 asynchronous control path. |
| Methodology | 18 | 15 | `SYNTH-6` 2 on SCAN1 `entry_index_reg_rep` and `telemetry_ram_reg` output-register merging; `ULMTCS-1` 1 for 659 control sets (8.09% of 8150 available). |

The unchanged DRC warning classes are `PDCN-1569` 1, `REQP-1839` 12 and `RTSTAT-10` 1. The unchanged methodology classes are `LUTAR-1` 2, `TIMING-9` 1, `TIMING-34` 11 and `TIMING-39` 1. The new ordinary warnings are **not** reclassified as accepted historical findings or hidden by a waiver. Positive routed timing and routing do not establish reset-time RAM contents or board electrical sign-off; the raw warnings and those limits remain part of the W4 handoff if a release is otherwise qualified.
