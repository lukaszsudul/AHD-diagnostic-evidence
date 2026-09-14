# G2B NVP camera physical-authority carry-forward

## Carried-forward findings

No broad design-file search was repeated in OFFLINE-ADVANCE1-R1. The accepted ADVANCE1 search found no KiCad schematic, PCB or as-built authority in the bounded roots.

- Tested connector instance to logical CH1: `HIGH CONFIDENCE FROM OFF/ON/OFF RESPONSE`.
- Logical CH1 to VIN1 / U6.76: `HIGH DOCUMENTARY CONFIDENCE`.
- Tested connector refdes: `UNKNOWN`.
- Physical refdes / external AFE path to VIN1: `NOT PROVEN`.
- Nominal 75-ohm input path: `DATASHEET EXPECTATION ONLY`.
- Camera model: `OWNER INPUT REQUIRED`.
- Camera standard: `UNKNOWN`.
- External DVR/tester: `NOT RUN`.

The connected device is not classified as AHD 1080p25. That classification requires external evidence or the governed COMPAT0-R2R1-CONT1 result.

## Exact Owner inputs still required

1. Tested connector refdes.
2. Schematic, PCB and as-built file/location governing that connector.
3. Camera manufacturer and exact model.
4. Camera power voltage and measured/current-rated current.
5. Camera output standard.
6. Camera resolution and frame rate.
7. External DVR/tester result.
8. Cable type and length.
9. Camera OSD or physical standard-selector state.

## Boundary

This addendum is an authority carry-forward only. It performs no DUT access, hardware action, design-file search, camera classification or electrical qualification.
