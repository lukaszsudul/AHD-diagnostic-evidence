# Selected resolved-pin timelines (simulation only)

Times below are converted from the XSim 1 ps records to ns. Each listed case is from the preregistered matrix and has a private full log/pin trace whose hashes are in `PRIVATE_ARTIFACT_MANIFEST.json`; selected originals are also under `simulation-receipts/`. These are digital resolved/input events, **not** measured PCB edges or analog 30–70% rise times.

| Case | Purpose | Master releases SCL | Slave releases SCL / resolved HIGH | Sync-2 / filtered HIGH | ACK sample | Result |
|---|---|---:|---:|---:|---:|---|
| 12 | 256 extra cycles at DATA ACK, stable ACK | 1,123,256 | 1,127,360 | 1,127,384 / 1,127,432 | 1,147,448, SDA=0 | raw0, success, wait261 |
| 16 | 1240 extra cycles, zero input delay, phase8 | 1,123,256 | 1,143,104 | 1,143,128 / 1,143,176 | 1,163,192, SDA=0 | raw0, success, wait1245 |
| 17 | 1248 extra cycles, same anchor | 1,123,256 | 1,143,232, before recognized high | no target filtered-high observation | no ACK sample | raw5/timeout1, wait1250 |
| 211 | deliberately premature DATA ACK release | 1,123,256 | 1,127,360 | 1,127,384 / 1,127,432 | 1,147,448, SDA=1 | ACK released at 1,127,376 ns, raw4; **invalid hold** |
| 214 | deliberately premature REGADDR ACK release | 762,248 | 766,352 | 766,376 / 766,424 | 786,440, SDA=1 | ACK released at 766,480 ns, raw2; **invalid hold** |

At case12 the asserted ACK existed before the SCL high phase and remained low through the sample. Case211 demonstrates why *setup alone* is insufficient: its ACK was initially low but ended during SCL high. Case17 does not show an ACK misread; the master reached its local SCL-low budget before a recognized high/sample. The 1240–1248 transition is specific to this phase and zero-delay model, not a universal chip/board threshold. Generic Standard-mode extension can still be legal beyond this implementation's finite wait; the NVP6134C's actual stretch capability/limit is not established by the reviewed data sheet.
