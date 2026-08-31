# AHD v41 G2B-BS1 Serialized Single-Sink BUS_SKEW Probe

## Outcome

The procedural engineering gate is **PASS** with execution result **`INITIALIZATION_TIMEOUT`**. Exactly one Vivado 2025.2 worker was launched, under a 300-second external wall-clock timeout, with no pre-existing or overlapping Vivado worker. The worker timed out while `open_checkpoint` was still loading the sealed routed design. It never emitted `DCP_OPENED`, `OBJECTS_RESOLVED`, `COMMAND_STARTED`, or `COMMAND_COMPLETED`.

Accordingly, no conclusion about `report_bus_skew` is permitted. The bounded single-sink pathology is **INCONCLUSIVE**, not reproduced and not cleared. No retry, bisect, second sink, or control query was run.

## Authority and protected state

- `PROJECT_STATE_REV_AT_START = 3`
- `PROJECT_STATE_REV_AT_END = 3`
- Accepted recovery evidence commit: `6707d6f2ca39c76295ce565b0e04878dff16110a`
- Recovery classification used: `PARTIALLY_RECOVERABLE_RESUME_FROM_CHECKPOINT`
- G2B-LUT1 remains `HOLD` for this diagnostic task.
- G2B-HW remains `BLOCKED`.
- The project-current-state SSOT was not modified.

The FPGA source checkout remained on `main` at `be94f88ee8d179f12928ab791bdae27c22cd1762`. Tracked and staged changes remained zero. Its complete 46-line pre-existing untracked-status serialization was unchanged at SHA-256 `22B27671E8E44357A1F37917813317282F68A50F57A4CC5FC8F288B6CE9E8E60` before and after BS1.

## Verified immutable inputs

| Input | Identity |
|---|---|
| Sealed Gen12 routed DCP | `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp` |
| DCP SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` — exact match |
| Recovered 58-source/19-sink inventory SHA-256 | `CE4E8A35CB82CCD0A85AEBF340B997D74FEF9250C86BA76C61769E332079F4DB` — exact match |
| `S_FULL` | 58 objects; SHA-256 `F69E9199EBB6212346DA11AC7EB66D832D2E50CCF8F43C5401806780E15247EE` |
| `K_OWNERSHIP_RESULT` | 1 object; SHA-256 `D0E81393EF7750003EE14C3BE0A789CD35FDF132AF3D2B23CE0C3272EB8065BE` |
| Skew-free base XDC | SHA-256 `A05AF5431E521BBC8812DAAE5574CC31D4E7E3BE89DCA0E41974462383BE3071`; zero `set_bus_skew` commands |
| Frozen worker | SHA-256 `FFC42D3F285AC2267F1E48780D7D43298D4FE89BA6090B7C4B899B103B2D54B1` |

The recovered singleton object is `G2B_ONECH_C2H/own_ok_hold_source_reg`, object type `CELL`, primitive `FDRE`. Its semantic role is the registered ownership success/failure decision returned with the acknowledgement and directly derived from complete slot/generation/epoch qualification. The intended BUS_SKEW requirement remained exactly `3.000 ns`.

## Worker construction and serialization

The frozen worker contains one `set_bus_skew` statement and one executable `report_bus_skew` statement. It has no `for`, `foreach`, or `while` loop, no experiment enumeration, no retry, no bitstream command, and no hardware command. Its intended sole report payload was:

```tcl
report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 -warn_on_violation -file [file join $output_dir G2B_BS1_REPORT_BUS_SKEW.rpt]
```

The external wrapper found zero pre-existing Vivado processes, wrote an immutable launch marker, launched one worker, and armed a 300-second process-tree timeout. It started no second Vivado process. On timeout it stopped only the launched worker tree. The final Vivado process count was zero.

## Timeline

| Boundary | UTC timestamp | Status |
|---|---|---|
| External launch start | `2026-08-31T22:07:13.622Z` | Reached |
| `WORKER_STARTED` | `2026-08-31T22:09:30.594Z` | Reached |
| `DCP_OPENED` | N/A | Not reached |
| `OBJECTS_RESOLVED` | N/A | Not reached |
| `COMMAND_STARTED` | N/A | Not reached |
| `COMMAND_COMPLETED` | N/A | Not reached |
| External stop complete | `2026-08-31T22:12:14.697Z` | Reached |

- Vivado initialization elapsed: `300.949 s` wall clock before stop completion.
- BUS_SKEW command elapsed: N/A.
- Total elapsed: `300.949 s`.
- External timeout limit: `300 s`.
- Timeout phase: `INITIALIZATION`.

## Dynamic result

Vivado printed its 2025.2 banner (`SW Build 6299465`), entered the frozen Tcl source, emitted `WORKER_STARTED`, invoked `open_checkpoint`, and reported device-part loading. `open_checkpoint` did not return before the external deadline. The route-status verification, timing-base load, exact object resolution, BUS_SKEW application, and BUS_SKEW report command were therefore not reached.

Result: **`INITIALIZATION_TIMEOUT`**.

`G2B_BS1_REPORT_BUS_SKEW.rpt` is intentionally absent because `COMMAND_STARTED` is absent. Actual skew, slack, source path, destination path, and path count are all N/A. The optional exact-scope `report_timing` control was not run.

The console contains one non-TIMING warning, `[Runs 36-547]`, about a duplicate user strategy definition. No TIMING-related message was produced because timing initialization and the report command were not reached.

## Applied-constraint evidence status

The worker did not reach `read_xdc`, `set_bus_skew`, or `write_xdc`. Therefore no constraint was dynamically applied. `G2B_BS1_APPLIED_CONSTRAINT.xdc` is an explicit non-executable evidence sentinel recording `NOT_APPLIED_INITIALIZATION_TIMEOUT`; it must not be construed as Vivado-applied XDC. The exact intended skew-free base is preserved separately as `G2B_BS1_CONSTRAINT_BASE.xdc`, and the exact intended 3.000 ns command remains visible in the hashed worker.

## Interpretation and implication

Allowed conclusion **D — `VIVADO_INITIALIZATION_TIMES_OUT`** applies. No inference about single-sink `report_bus_skew` completion, violation, performance, or pathology is allowed. The provisional constraint implication is therefore: **no conclusion; initialization timed out before command start**.

## Source and safety protections

- FPGA source modified: `NO`
- Active XDC modified: `NO`
- Source branch moved: `NO`
- Source commit created: `NO`
- Bitstream produced: `NO`
- DUT/hardware accessed: `NO`
- SSOT modified: `NO`
- Stack traces, minidumps, ETW, process internals, or debugger dumps collected: `NO`

This is the hard stop after the one G2B-BS1 single-sink experiment.
