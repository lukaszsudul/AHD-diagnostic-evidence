# W3 T18 compound fault and T23 same-kind control record verification

**Result: PASS for the bounded digital cases below.** The final guarded run used Vivado Simulator 2025.2 and the frozen source test `source/tests/w3/tb_w3_t18_t23_record.sv` (SHA-256 `15BB5000FA8C3F497E7775B58413A9B8E971B91B0B31B54876570713BCCC8821`). The run, source-path and source-hash receipt is `simulation/t18_t23/receipt.json`; its run log SHA-256 is `567C84482936D46D1A0B8E20C01A49C3130C2F26CC09E6BC7CD8750A16B48E6F`. Pinned master SHA-256: `62F2383B3F6E72FB2FCF513A28ABA2D0A34E388DB159FB747CEBE8F803FA73B9`; W3 telemetry SHA-256: `E545FB629F3269168C626E7768A4EEA1D77EE7409439D84ED250D6DA71FEA587`.

The test uses the real fixed I2C master and resolved SCL/SDA pins. It drives the W3 telemetry block with registered master acceptance, completion, observation and first-fault pulse. It asserts both committed BRAM contents and host-visible synchronous MMIO readback. No production RTL, master output or state is forced. The slave controls its own ACK response and holds SDA low to create the second error.

## T18 compound fault

One group-5 verify read receives a REGADDR NACK, then SDA is held low during STOP until the master reports BUS_IDLE_TIMEOUT. The master first-detected cause is raw 2 at the register ACK phase; its final completion is raw 6 with timeout true. Both committed first and terminal W3 records retain the same transaction sequence and same-operation link. Their word 7 is raw-first 2, and word 8 is raw-completion 6, timeout 1, legacy-mapped 5. First and terminal MMIO addresses `0x13900/0x1391C/0x13920` and `0x13980/0x1399C/0x139A0` return the committed values. Verify attempt/failure/timeout counters each read 1. With no preceding same-kind success, sample-valid is 0 and all seven embedded sample words are zero through MMIO.

Completion marker: `PASS T18_COMPOUND_W3_FIRST_TERMINAL_RECORD`.

## T23 same-kind control and availability

After resetting only W3 retained state, a clean group-5 verify read returns the manifest bank `0x05`; a later verify read receives REGADDR NACK. The successful kind-2 control has the exact real-master transaction sequence, register `0xFF`, target bank `0x05`, clean outcome, block ID 0, scan-attempt sequence 1, and group-5/entry-37 location `0x0A55` with group-valid and entry-invalid flags. The control's ACK mask is `1011`; the unreached DATA ACK has valid=0 and wait=0. Its four attempt words and three context words are committed to the successful-control MMIO slot. The first and terminal failure records set sample-valid and embed all seven values byte-exactly. Their transaction sequence is the subsequent master sequence. Verify attempt/success/failure counters read 2/1/1; timeout reads 0. All compared addresses are read from W3 MMIO after freeze.

Completion marker: `PASS T23_SAME_KIND_SAMPLE_DATA_VALIDITY_CONTEXT`.

This directed run covers a representative successful-control kind (group verify, kind 2), together with an unavailable sample for the same kind. It does not exhaust all six operation kinds, all possible wait values, or a physical NVP device. The existing scanner/MMIO and master benches provide separate coverage for other operation contexts; this receipt claims only the exact cases above.
