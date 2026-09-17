# W3 final pin-level and master verification

All evidence is offline digital simulation using Vivado Simulator 2025.2. No DUT, analog rise time, or physical clock stretching was exercised.

## Frozen inputs

- W3 master SHA-256: `62F2383B3F6E72FB2FCF513A28ABA2D0A34E388DB159FB747CEBE8F803FA73B9`
- W3 telemetry SHA-256: `E545FB629F3269168C626E7768A4EEA1D77EE7409439D84ED250D6DA71FEA587`
- W3 scanner SHA-256: `46488440CC33FEB9A4CD7FC34F727D87D3F3302D91FC691B1749B67DA5BF0855`
- Frozen W1 parent clean trace: `C:\FPGA\CONT1R3R4R5_W1W2_20260917T151605Z\W1\simulation\xsim.log`, SHA-256 `08D979680922183F075F94DCE70393CEF1BA98AE373FA14080E8B15BAE5A32A6`.
- W1 selected-boundary CSV: `C:\FPGA\CONT1R3R4R5_W1W2_20260917T151605Z\W1\reports\W1_TRANSACTION_GAPS.csv`, SHA-256 `9DB758A6F4FA264DEC93ECCDFBD5C5AC74202665003A0124337196FD6D642B14`.

## Clean OFF/ON scan

`simulation/delay-final3/receipt.json` records all source, authority, log, and CSV hashes. The real master and pin-level digital slave completed 105 accepted commands and 82 valid entries in both modes. OFF command identities and the complete resolved START/STOP pin-edge trace matched the frozen W1 parent exactly. All 104 adjacent parent gaps were compared; the W1 CSV's 21 selected boundaries also matched the exact W1 trace. ON preserved command identity and added exactly 18,750 FPGA cycles after each of 11 successful bank writes, 206,250 cycles total. The remaining 93 gaps were unchanged. The ON bench checked admitted configured/locked/effective mode and zero control rejection before accepting its result.

## Bank5 faults, paired OFF/ON

`simulation/delay-negative/FINAL_NEGATIVE_RECEIPT.json` records ten full simulation logs, five paired timing CSVs, comparator results and the frozen negative bench SHA. That bench is byte-exact to `source/tests/w3/tb_w3_delay_negative.sv` SHA-256 `C6EB3C2C39ED7DF3B85B661F2AC9C4856D5300D2A7237D9E303DF1CD49E29928`.

| Fault | Commands | Failed tx | First raw / mapped | Select / verify | Successful bank writes paused |
|---|---:|---:|---|---|---:|
| DATA_NACK | 51 | 49 | 4 / 10 | FAILED / NOT_ATTEMPTED | 6 |
| WADDR_NACK | 51 | 49 | 1 / 1 | FAILED / NOT_ATTEMPTED | 6 |
| REGADDR_NACK | 51 | 49 | 2 / 2 | FAILED / NOT_ATTEMPTED | 6 |
| RADDR_NACK | 52 | 50 | 3 / 3 | SUCCESS / TRANSPORT_FAILED | 7 |
| SCL_TIMEOUT | 51 | 49 | 5 / 4 | FAILED / NOT_ATTEMPTED | 6 |

All five cases preserved 37 valid entries, no complete publication, exact committed first/terminal failure transaction identity, and successful restore verification. Paired OFF/ON comparisons matched all accepted command identities and all pin edges relative to each command. Successful bank writes alone added 18,750 cycles each; the failed select added zero. SCL timeout retained distinct first raw cause 5 and legacy mapped cause 4. The timeout trace includes an SDA release edge after the next command was accepted but before its START; both modes preserve that exact edge. It is excluded only as the closing STOP for the next command's gap.

## Fixed master

`simulation/master-telemetry/receipt.json` records the final rerun: 16 real-master commands and 120 assertions for ACK/NACK, waits, first versus completion causes, below-limit hold, timeout boundary, reset, plus wait saturation. The W3 master matched the pinned parent cycle-exactly in functional outputs and pins for 9 commands and 3,374 compared cycles.

These receipts do not establish full T25 sequence-wrap coverage, analog SCL rise-time behaviour, hardware capture, or a complete W4 qualification result.
