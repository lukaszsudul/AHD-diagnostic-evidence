# W1 exact resolved-line transaction gap

## Authority and endpoint

Frozen design: `lukaszsudul/FPGA_AHD@09cd7cbb426027acaefd0cf3989579b80a451f3a`, tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`. The compiled master, scanner and manifest files are byte-identical to that commit; see `W1_MINIMAL_SIMULATION_RECEIPT.md`. The actual top instantiates the master with `CLK_HZ=62,500,000` and `I2C_HZ=25,000` (`ahd_capture_top_xdma.sv` lines 65, 395–403). Thus `DIVIDER=1250`, `TICK_CYCLES=1251`, one FPGA cycle is 16 ns, and one divider interval is 20.016 µs. `state_tick` compares the **old** `divider_count >= DIVIDER` (`nvp_i2c_fixed_master.sv` lines 46–47, 151, 291–293, 426–428), so a reset count takes 1,251 clock edges to tick.

The primary endpoint is resolved SDA low→high with resolved SCL high at successful `SELECT_GROUP_BANK` STOP, followed by the **initial** resolved SDA high→low/SCL-high START of the `VERIFY_GROUP_BANK` read. The separately reported second endpoint is the successful verify-read STOP followed by the first `READ_GROUP_ENTRIES` initial START. Each read also has an internal repeated START; it remains inside that read transaction and is excluded from inter-transaction gaps. The same pin-level rule is used for the entry-bank restore write→verify context.

## Source equation for the clean owned path

Let `t0` be the clock-aligned resolved STOP. In `LL_STOP_A` the master pulls both lines low. `LL_STOP_B` releases SCL while holding SDA low. Once SCL is filtered high, its divider tick enters `LL_STOP_C`; the combinational outputs release SDA, so the digital pullup produces STOP at `t0` (`nvp_i2c_fixed_master.sv` lines 193–204, 406–408). `LL_STOP_C` starts from a reset divider and waits one full `TICK_CYCLES`; at `t0+1251` cycles it registers `done=1`, `busy=0`, and `state=LL_IDLE` after filtered SDA is high (lines 408–414). The resolved SDA high reaches the two-flop synchronizer/filter well before that completion in the zero-rise-delay model. Specifically, after the STOP edge the first following FPGA sample enters sync stage 0, the second enters stage 1, the third changes the candidate and sets count 1, the fourth sets count 2, and the fifth updates `sda_filtered` (lines 69–101).

The scanner observes registered `i2c_done` one cycle later (`g2b_nvp_camera_scan1.sv` lines 625–630, 726–737), clears `txn_inflight`, and changes state to `VERIFY_GROUP_BANK`. Its `i2c_cmd_valid` is combinationally gated by `!txn_inflight && i2c_cmd_ready`; the master accepts the verify command at `t0+1253` cycles, two cycles after completion and 1,253 cycles after STOP (scanner lines 478–500; master lines 208, 237–254). The frozen combined wrapper has a combinational scanner grant while SCAN1 owns the bus and masks ready only if the ACQ executor owns it (`g2b_nvp_camera_scan1_acq1_compat0_r2.sv` lines 67–83, 88–109). In the no-other-client condition it adds no register stage. The simulation wires scanner directly to the master; this wrapper conclusion is from source, not a separately simulated arbitration trial.

After acceptance the master enters `LL_WAIT_IDLE`. With filtered SCL/SDA high, its `idle_stable_count + 1 >= TICK_CYCLES` transition needs 1,251 cycles to enter `LL_START_A` (`nvp_i2c_fixed_master.sv` lines 256–264). The divider remained zero in `LL_WAIT_IDLE`; after another 1,251 cycles in `LL_START_A`, `state_tick` enters `LL_START_B`, whose output pulls SDA low while SCL stays high (lines 163–170, 291–299). That is the next initial resolved START.

```text
STOP → completed master transaction   1251 cycles
completion → next command acceptance     2 cycles
accepted command → stable-idle exit   1251 cycles
LL_START_A → resolved initial START   1251 cycles
                                    ───────────
STOP → next resolved initial START    3755 cycles
                                  = 60080 ns = 60.080 µs
```

The same scanner handshake applies after a successful verify read, after a clean entry read and after the successful restore write. The scanner changes state as relevant but exposes the next command through the same combinational ready/valid path. The equation assumes successful ACKs, no extra SCL stretch, no other client, no paused or reset scanner, and no analog line-rise delay. This is a digital prediction, not a physical board interval.

## Observed line-edge ledger

XSim 2025.2 SW build 6299465 ran one complete, unchanged-design SCAN1 scan at the real 62.5 MHz clock. The task-owned open-drain slave used immediate digital pullups and valid ACKs; it did not add stretch. The compiled sources were the frozen master/scanner/manifest. Every accepted command had one initial START and one STOP. Each of the 94 reads had one internal repeated START and the master's normal final read NACK was left intact by the slave model. The 105 commands produced 104 adjacent STOP→initial START gaps, **all exactly 3,755 cycles / 60,080 ns**. The required CSV contains all 10 group-select-write→verify-read boundaries, all 10 verify-read→first-entry-read boundaries, and one restore-write→verify-read context boundary; each also agrees exactly with 3,755 cycles.

Group 5 illustrates the edge and handshake counts. Successful select sequence 49 STOP occurred at `77,908,200.000 ns`; verify sequence 50 was accepted at `77,928,248.000 ns` (20,048 ns = 1,253 cycles after STOP), and its **initial** START occurred at `77,968,280.000 ns` (40,032 ns = 2,502 cycles after acceptance). The verify read's internal repeated START occurred later at `78,750,424.000 ns`; using it as the next transaction would be wrong. Its STOP was at `79,552,584.000 ns`, followed by the first entry read's initial START at `79,612,664.000 ns`, again 60,080 ns. Groups 1, 2 and 3 are same-bank reselections by scanner group context; group 0 also writes the saved bank value `00` but has no previous-group-valid flag. The terminal restore write sequence 104 (`00`→`00`) STOP at `166,143,560.000 ns` to verify initial START at `166,203,640.000 ns` is 60,080 ns.

All captured edges occur on the same FPGA rising-edge phase in this immediate-pullup model; printed timestamps have `.000 ns`, and each endpoint difference is divisible by 16 ns. No fractional-cycle value arose in this run. An asynchronous rise delay or differently phased input model could produce a fractional pin-edge interval; this result is not silently rounded to an integer cycle for such a model.

## Reference comparison and scope

For the **write→next read** group-select rows only, 60.080 µs is 139.920 µs below 200 µs and 239.920 µs below 300 µs. These are numerical comparisons to the inspected reference helper's post-write-call waits, not an assertion that the reference board has a measured 200 or 300 µs physical STOP→START interval. The helper's external transport completion and other bus clients are unobserved. The verify-read→first-entry-read rows are read→read and carry no 200/300 µs criterion. A post-write wait does not increase the master's intra-transaction SCL timeout.

**W1 conclusion:** the modeled unchanged scanner starts verification 60.080 µs after successful group-bank-write STOP, a quantified difference from the reference helpers' 200/300 µs post-write waits that supports a narrow added-delay experiment, without proving the physical NACK cause.
