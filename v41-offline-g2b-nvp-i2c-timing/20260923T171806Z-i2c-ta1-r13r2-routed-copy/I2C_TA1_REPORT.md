# AHD v41 — I2C-TA1 — sanitized routed-copy result

## Decision

`I2C_SCOPE_PASS_WITHIN_EXISTING_MODEL`

The deferred R13R2 checks had left an evidence gap. A read-only analysis of a verified private copy of the exact routed checkpoint closed the declared internal STA and structure-review scope. It found no timing violation, unjustified ignored endpoint, synchronizer defect, or reset-structure defect in that scope.

This is not physical I²C qualification, does not prove that the R14 NACK was fixed, and does not identify its physical root cause.

## Identity and execution

| Field | Result |
|---|---|
| FPGA source | `lukaszsudul/FPGA_AHD@88ac649a8484ff359270ec19ab539478edf534c0` |
| Source tree | `8120a9560d85c1a147b30941e47901e52af0b306` |
| Routed DCP | 17,718,175 bytes; SHA-256 `C907318FB88B93C224B03468AACF9880D14399383F0F6A77E8FC29F59C9B376D` |
| Associated bitstream | SHA-256 `22DACBCF9245BB04901B106A27BB37248B14CC877B92DB1774FFAF63FA4B716A` |
| Part / top | `xc7a35tcsg325-2` / `ahd_capture_top_xdma` |
| Tool | Vivado 2025.2, SW build 6299465 |
| Checkpoint use | one reporting session, one `open_checkpoint`, no checkpoint write |
| Build / simulation / hardware | 0 / 0 / 0 |

The original and copied DCP were re-hashed before and after analysis and remained byte-identical to the released identity. The analyzed file was an independent copy, not a hardlink, symlink, or junction.

## Scoped STA results

| Area | Worst setup | Worst hold | Timing result | Coverage |
|---|---:|---:|---|---|
| NVP autoinit engine | +2.824 ns | +0.066 ns | `PASS_WITHIN_CHECKED_MODEL` | `COMPLETE_FOR_DECLARED_SCOPE` |
| PREPARE/APPLY diagnostic master | +5.074 ns | +0.114 ns | `PASS_WITHIN_CHECKED_MODEL` | `COMPLETE_FOR_DECLARED_SCOPE` |
| Shared wrapper/loader/SCAN1 | +2.824 ns | +0.029 ns | `PASS_WITHIN_CHECKED_MODEL` | `COMPLETE_FOR_DECLARED_SCOPE` |
| Scoped reset/start controls | +2.824 ns | +0.418 ns | `PASS_WITHIN_CHECKED_MODEL` | `COMPLETE_FOR_DECLARED_SCOPE` |

Endpoint accounting ended with zero unresolved entries:

| Group | Setup/hold analyzed | Static | Structurally justified async boundary | Disabled primitive-internal RAM pin, N/A |
|---|---:|---:|---:|---:|
| Autoinit | 5,017 | 105 | 2 | 0 |
| Diagnostic master | 480 | 46 | 2 | 0 |
| Shared I/O | 40 | 28 | 4 | 0 |
| Wrapper/loader/SCAN1 | 8,186 | 1,069 | 0 | 1,459 |
| Scoped reset/start | 3,917 | 681 | 0 | 0 |

The endpoint register is separate from `report_exceptions -coverage`, which only describes exception-object coverage. Targeted `get_timing_paths -user_ignored -to <declared endpoints>` returned no paths for the final I²C groups; analyzed synchronous endpoints also had finite max/min paths with identified clocks.

## Synchronization, pins, and reset

Both engines use a separate two-register SCL synchronizer and two-register SDA synchronizer. All eight registers carry `ASYNC_REG=TRUE` and `SHREG_EXTRACT=NO`; each first stage fans out only to the second stage. No raw-input bypass to the filter or ACK decision was found.

Worst stage0→stage1 slack was +15.215 ns setup / +0.127 ns hold. Worst stage1→filter/ACK slack was +14.603 ns setup / +0.211 ns hold.

The SCL/SDA IOBUF topology is open-drain: the data input is constant zero and tristate control releases the pin. Both engines are present in the realized shared-control cone. The review found no additional active driver or unsynchronized input bypass.

`check_timing` reports missing input delay for SCL/SDA at severity HIGH and missing output delay for SCL/SDA and codec reset. SCL/SDA are architecturally treated as asynchronous inputs, so no synchronous port→stage0 slack is claimed. Likewise, no FPGA→codec external slack is claimed. A zero-result scoped `report_cdc` does not cover this raw I/O boundary; the boundary was checked structurally.

The checked I²C/wrapper region uses synchronous FDRE/FDSE reset controls. The scoped reset register contains 3,917 analyzed max/min pins and 681 constant pins, with zero unresolved entries. Nominal source-derived 500 ms codec reset-low and 1.5 s autoinit start depend on continuity of the 62.5 MHz application clock; the DCP cannot prove that continuity or a physical pin duration.

## Global context, distinct from I²C

A fresh summary on the copied DCP reported WNS +0.076 ns, TNS 0, WHS +0.029 ns, and THS 0, with zero failing constrained setup and hold endpoints in the current model. Routing was complete for 39,821/39,821 routable nets.

The retained native-router estimate was WNS +0.083 ns / WHS +0.029 ns. Both results are preserved; one was not adjusted to match the other.

The global summary also contains user-ignored and unconstrained clock-pair rows, missing I/O delays, and two LOW-severity PCIe GT pulse-width-clock findings outside I²C scope. The global WNS is therefore not a claim of complete global coverage or external I²C sign-off.

## Protocol and relation to historical R14

Source-derived timing uses a divider value of 1,250 on 62.5 MHz: a tick every 1,251 cycles (20.016 µs) and a nominal complete SCL period near 40.032 µs (about 24.98 kHz). The implemented state machines release SDA before ACK sampling, wait on filtered SCL/SDA, and enter STOP after a write-address NACK before transmitting register address or data.

Historical R14 reported autoinit NACK count 17; this counter counts qualifying NACK observations, including retry attempts, not necessarily 17 distinct unrecovered registers. Historical PREPARE was clean: 46 accepted main transactions, 36 first read attempts, 16 eligible first read attempts, no first-attempt NACK, no accepted retry, generation 1 coherent telemetry, and four empty slots. This did not exercise retry recovery.

Historical APPLY ended with terminal `0xC3C02283`, loader terminal code 17, at PC111 / Bank 0x0B / register 0x68 / planned write 0x03. Raw I²C cause 1 is `I2C_WADDR_NACK`; it is not evidence that register 0x68 rejected data value 0x03.

The digital path from filtered SDA through the WADDR ACK decision to cause/status exists and was analyzed. No timing, constraint, or structural defect was found that causally links it to the historical R14 NACK. The result is `NO_LINK_ESTABLISHED`, not proof of an external cause.

## Limits and next action

No waveform, pull-up value, load, voltage, codec state, or physical rise/fall time is present in a DCP. Retry effectiveness and EQ execution were not tested. DUT containment was untouched and no fresh hardware measurement was made.

The one proposed follow-up, not authorized or executed here, is a single passive SCL/SDA capture around the WADDR ACK at historical PC111 on the unchanged image, using only already approved instrumentation and without retry, cleanup, or a broader campaign.
