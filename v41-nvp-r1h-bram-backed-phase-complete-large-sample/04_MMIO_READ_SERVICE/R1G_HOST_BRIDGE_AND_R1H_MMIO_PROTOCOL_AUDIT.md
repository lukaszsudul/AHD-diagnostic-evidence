# R1g host-bridge audit and exact R1h MMIO protocol contract

## Scope and identity

Classification labels used below are `FACT`, `SOURCE-DERIVED FACT`, `INFERENCE`, and `RECOMMENDATION`.

`FACT` — this was a read-only audit. No source, repository, synthesis, implementation, or hardware action was performed.

`SOURCE_GIT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada`

`SOURCE_GIT_TREE=3a59ebec130103055d24a3a32ecda00dedde5534`

`SOURCE_WORKTREE=C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY`

The worktree was clean when audited. Important exact blobs and SHA-256 values:

| File | Git blob | SHA-256 |
|---|---|---|
| `rtl/v41/axi_lite_host_bridge.sv` | `fde2499259d98da8c28ed26548032ebffb648007` | `D94BE3FC0AE7D9DDEC87DF4289277BDE5F3AEE2597F02AC2CE19EF9C4EDB890E` |
| `rtl/v41/control_status_regs.sv` | `370fa721e2b269e3ea9d2bb8ee64f5e56d3f1f` | `BE70C2707EDAFE075008F9592E474AF1E1658D75A75D5053A1F2FFBD072E44B5` |
| `rtl/v41/r1f_measurement_regs.sv` | `062fb70062a7eac536961f98f7190cdcce60d9d3` | `BB77188A3A28F34DB3BBC195129A58620D11ECFE4F617528D68002DC1F1FDBFF` |
| `rtl/v41/r1f_failed_txn_logger.sv` | `98dc3cae842d8caa1a94374b0f814fdec66123ff` | `EFAF862E4267A8AE9A042FFB6B5F074B217CD8D0AD2DD3E4E783BA6F6B7B6C71` |
| `rtl/v41/nvp_i2c_tri_phase_probe.sv` | `13b55e9c5efab150f7e19fc383c38598233bfd8a` | `4AA823B5896D9C11DB9837D1F30E4E077557FE367942B032B404ACBA92E03552E` |
| `rtl/top/ahd_capture_top_xdma.sv` | `e9ff9e3eafa5bcc933e9a6552c48834b4c2e8498` | `CD8E2BB50D89273857168722EDA06F83AE08FA059FCA266522E6D2E3CD2CB77F` |

## Existing authoritative request/response protocol

### AXI-Lite bridge

`SOURCE-DERIVED FACT` — the existing bridge already permits only one host transaction at a time:

- `axi_lite_host_bridge.sv:42-49` defines `IDLE`, `READ_REQUEST`, `READ_WAIT`, and `READ_RESPONSE`, in addition to the write states.
- `:61-64` accepts a new AXI read address only in `IDLE` and gives an offered write priority.
- `:71-78` presents exactly one host request and asserts `host_rsp_ready` only in `READ_WAIT`.
- `:129-143` holds the bridge in `READ_WAIT` for an arbitrarily delayed host response, copies the data once, and then holds the AXI R response in `READ_RESPONSE` until `s_axi_rready`.
- `:66-69` fixes both AXI response codes to `OKAY`. The internal host response has no error/status signal.

Therefore the new diagnostic service does not need a request queue, tag, reorder buffer, or response identifier.

### Local versus forwarded requests

`SOURCE-DERIVED FACT` — `control_status_regs.sv:90-97` classifies only reads in `0x02000..0x0209f` and `0x020a0..0x035ff` as measurement/diagnostic local requests. The `!host_req_write` qualifiers are semantically important.

`SOURCE-DERIVED FACT` — writes to the R1e or R1f/R1g ranges are therefore forwarded unchanged to the preserved application target by `:183-187`; this behavior is explicitly tested for the measurement page at `tb/v41/tb_control_status_regs.sv:204-221`. R1h must not accidentally consume such writes.

`SOURCE-DERIVED FACT` — current local read handling is one-outstanding and backpressure-safe at the local response register:

- `control_status_regs.sv:188` blocks another local request while `local_rsp_valid` is set.
- `:190-192` prioritizes the local response and prevents the application response from being consumed while it is pending.
- `:194-215` latches local read data and retains `local_rsp_valid/rdata` until `host_rsp_ready`.

### Current response and invalid-address semantics

`SOURCE-DERIVED FACT` — no error response exists in this plane. `axi_lite_host_bridge.sv:66-69` always returns AXI `OKAY`.

`SOURCE-DERIVED FACT` — misaligned local and diagnostic reads return zero:

- `control_status_regs.sv:208-211` masks any address with `addr[1:0] != 0` to zero.
- `r1f_measurement_regs.sv:151-153` independently does the same.

`SOURCE-DERIVED FACT` — holes and unsupported words return zero through the initialized/default branches at `r1f_measurement_regs.sv:139-149`, `:153-219`, and `:245-246`.

`RECOMMENDATION` — R1h must retain `zero data + AXI OKAY`. It must not invent `SLVERR`, `DECERR`, or a new internal status port.

## Exact clock and reset facts

`SOURCE-DERIVED FACT` — `ahd_capture_top_xdma.sv:39` defines `autonomous_clk = axi_aclk`. The NVP observer, failed-record logger, probe stores, MMIO bridge, and control plane therefore use the same physical clock. A dual-clock CDC or Gray-pointer architecture is neither required nor appropriate for these stores.

`SOURCE-DERIVED FACT` — reset domains are nevertheless different:

- `ahd_capture_top_xdma.sv:47-56` states that NVP POR is independent of link-up and `axi_aresetn`.
- `:79-86` shows that `nvp_por_reset` is an initial, monotonic 320-cycle POR in this image.
- the probe and failed-record logger use `nvp_por_reset` at `:227` and `:368`;
- the bridge/control plane use `~axi_aresetn` at `:877` and `:901`.

`INFERENCE` — an AXI reset can clear a pending read response while the scientific payload and its append metadata legitimately persist. Consequently, payload RAM must have no reset; the AXI-side request/response state and BRAM output pipeline must use `~axi_aresetn`; write pointer/count/overflow/valid metadata must remain governed by `nvp_por_reset` exactly as before.

## Source of the current large combinational path

`SOURCE-DERIVED FACT` — the live host address directly drives the whole diagnostic decoder at `ahd_capture_top_xdma.sv:772-833`.

`SOURCE-DERIVED FACT` — the decoder creates direct random-read addresses:

- record index/word from `(offset-0x2400)/6` and `%6` at `r1f_measurement_regs.sv:224-229`;
- packed-index phase/word at `:230-244`.

`SOURCE-DERIVED FACT` — the failed-record logger performs an asynchronous 64-entry payload read and six-word selection at `r1f_failed_txn_logger.sv:58-70`.

`SOURCE-DERIVED FACT` — the probe performs two asynchronous random reads of a selected 512-entry index array and packs them at `nvp_i2c_tri_phase_probe.sv:1176-1191`.

`SOURCE-DERIVED FACT` — the resulting value passes through `r1f_measurement_regs.sv:229/234/239/244`, `ahd_capture_top_xdma.sv:833`, and finally the control response mux at `control_status_regs.sv:208-212` before being registered.

This is the exact path that the R1h request/response service must cut. Merely registering `r1f_read_data` after the existing asynchronous arrays would not remove the 64x192 and 512-entry read cones.

## Recommended minimal R1h service boundary

Replace the combinational `r1f_read_data` input of `v41_control_status_regs` with one request/response channel:

```systemverilog
output logic        r1h_req_valid;
input  logic        r1h_req_ready;
output logic [13:0] r1h_req_offset;

input  logic        r1h_rsp_valid;
output logic        r1h_rsp_ready;
input  logic [31:0] r1h_rsp_rdata;
```

No write, byte-enable, ID, or response-status signal is needed:

- the service is selected only for `!host_req_write` in the frozen address range;
- the upstream bridge already serializes requests;
- all read responses are `OKAY`;
- the offset is latched on the request handshake.

Recommended control-plane equations, expressed as a behavioral contract rather than implementation code:

```text
r1h_req_valid = host_req_valid && r1f_read_select
r1h_req_offset = host_req_addr[13:0]
host_req_ready = r1f_read_select ? r1h_req_ready
               : ordinary_local_select ? !local_rsp_valid
               : app_req_ready

host_rsp_valid = local_rsp_valid || r1h_rsp_valid || app_rsp_valid
host_rsp_rdata = local_rsp_valid ? local_rsp_rdata
               : r1h_rsp_valid ? r1h_rsp_rdata
               : app_rsp_rdata
r1h_rsp_ready = host_rsp_ready && !local_rsp_valid
app_rsp_ready = host_rsp_ready && !local_rsp_valid && !r1h_rsp_valid
```

`RECOMMENDATION` — add assertions that these three response sources are mutually exclusive in every legal transaction. The upstream bridge guarantees this for integrated operation, but the assertion catches an accidental local-service acceptance bug.

An alternative one-word local response buffer is functionally valid, but it adds an unnecessary cycle and hides service-level response backpressure. Direct response arbitration as above is the narrower change and lets the service itself prove stable `valid/data` until acceptance.

## Exact one-outstanding state machine

Recommended service states:

| State | Action | Exit |
|---|---|---|
| `IDLE` | `req_ready=1`; latch offset and a snapshot of all validity/count values on handshake; classify request | scalar/zero -> `RESP`; record -> `RECORD_WAIT`; index -> `INDEX_LOW_WAIT` |
| `RECORD_WAIT` | capture the selected 32-bit BRAM bank output after its one-cycle synchronous read; apply the latched record-valid predicate | `RESP` |
| `INDEX_LOW_WAIT` | capture entry `2w`; issue entry `2w+1` to the same selected phase RAM | `INDEX_HIGH_WAIT` |
| `INDEX_HIGH_WAIT` | capture upper entry; apply both predicates against the count latched at request acceptance; assemble `{upper,lower}` | `RESP` |
| `RESP` | `rsp_valid=1`, hold data bit-exact and refuse requests | `IDLE` only on `rsp_valid && rsp_ready` |

The fixed latency measured from the service request handshake is therefore:

- scalar, hole, or misaligned read: response asserted in the next cycle;
- failed-record word: response asserted after the synchronous RAM result can be captured (normally two service cycles including request acceptance);
- packed index word: response asserted after two sequential 16-bit reads (normally three service cycles including request acceptance).

No response-latency bound applies while `rsp_ready=0`; data and valid must remain stable indefinitely. No new request may handshake in `RECORD_WAIT`, either index state, or `RESP`.

## Storage-facing read contracts

All memories use the common `axi_aclk`; only their resets differ by function.

### Failed record

Minimal internal read request:

```text
record_rd_en
record_rd_index[5:0]
record_rd_word[2:0]
record_rd_data[31:0]       -- synchronous, one-cycle RAM output
```

The six 64x32 banks share a row address and simultaneous append write enable. A read needs to enable only the selected word bank. On request acceptance, latch `record_index < stored_count`; if false, do not enable payload RAM and return zero. This preserves the contiguous append-only equivalence of R1g `entry_valid` without resetting payload.

The count/valid decision must be latched on the request edge. This makes a request concurrent with a new append deterministic: the just-appended row is not exposed until the subsequent request, while any already-valid different row remains readable. It also prevents a same-row read/write collision from being interpreted as valid data.

### Probe indices

Minimal internal read request:

```text
index_rd_en[2:0]           -- one-hot phase select
index_rd_addr[8:0]         -- single 16-bit entry address
index_rd_data[2:0][15:0]   -- synchronous per-phase outputs
```

Latch the selected phase and its 0..512 stored count on the MMIO request edge. Read `{word,1'b0}` followed by `{word,1'b0}+1`. Mask each half independently with the latched count; this is essential for an odd stored count, where the upper half must remain zero.

### Probe details and block counters

Scalar/detail values must be sampled into the response register on request acceptance. The 30 block counters may retain a small single-read LUTRAM/registered-read implementation. They must not be exported as a flattened 30-word bus to a top-level response mux.

## Reset and visibility contract

1. Payload arrays have no reset and no initialization-based validity claim.
2. `nvp_por_reset` resets only the scientific write pointer/count/overflow/valid metadata, exactly preserving R1g event semantics.
3. `~axi_aresetn` resets the read-service state, response valid/data, half-word buffer, selected bank/phase, and BRAM read-output pipeline only.
4. `req_ready` must be low while `nvp_por_reset=1`. In exact R1g this reset only deasserts once; therefore no accepted request can be stranded by a later NVP-POR assertion.
5. After AXI reset, persisted payload remains invisible or visible solely according to the persisted NVP-domain count metadata. There must be no physical payload clear.
6. After NVP POR/reset of metadata, all record/index reads return logical zero even though old RAM bits may remain physically present.

## Required assertions

- At most one service request is outstanding.
- `req_ready==0` outside `IDLE`.
- A response is produced exactly once for every accepted request unless AXI reset cancels the whole bridge transaction.
- `rsp_valid && !rsp_ready |=> rsp_valid && $stable(rsp_rdata)`.
- No memory request is issued for a misaligned address, a hole, an invalid record, or an invalid index half.
- Record word-bank enables are one-hot-or-zero.
- Index phase enables are one-hot-or-zero.
- A record append asserts all six bank write enables with one identical row address in one clock.
- `stored_count<=64`; each index count `<=512`.
- Diagnostic writes never assert `r1h_req_valid` and retain the existing forwarded path.
- Legal operation never asserts more than one of `local_rsp_valid`, `r1h_rsp_valid`, and `app_rsp_valid`.
- Service outputs have zero fanout to NVP/probe functional control.

## Risks and fail-closed treatments

| Risk | Evidence | Required treatment |
|---|---|---|
| Accidental consumption of diagnostic writes | selectors are qualified by `!host_req_write` at `control_status_regs.sv:90-95` | preserve the qualifier and add write-forwarding tests at each diagnostic subrange |
| Sampling live address after request | top currently drives decoder directly at `ahd_capture_top_xdma.sv:776` | latch offset only on `req_valid && req_ready`; all later addressing uses the latch |
| Returning a newly written row before payload is stable | count and RAM update on the same edge | latch pre-edge validity/count at acceptance; do not issue RAM read when invalid |
| Odd index count leaks uninitialized upper half | packed async logic currently has separate bounds at probe `:1181-1191` | retain two independent half-valid predicates using a latched count |
| AXI reset erases scientific data | storage reset is NVP POR, control reset is AXI | reset only the read pipeline with AXI reset; never connect AXI reset to payload or append metadata |
| Response changes under backpressure | required by host protocol and already tested in the bridge | service owns a registered response and holds `RESP` until ready |
| New request while pending | bridge already prevents it, but a standalone control TB can violate assumptions | service `req_ready` only in `IDLE`; integrated assertion on outstanding count |
| Same-address read/write BRAM collision | independent-port collision mode may be primitive-specific | validity gating prevents a not-yet-valid appended row from being read; test different-row concurrent read/write and fail closed on any same-row exposure |
| Addition of a new AXI error meaning | bridge has fixed `OKAY` | no service error port; invalid/misaligned/hole remains zero+OKAY |

## Audit conclusion

`MMIO_EXISTING_UPSTREAM_OUTSTANDING_LIMIT=ONE`

`MMIO_EXISTING_RESPONSE_BACKPRESSURE=PASS`

`AUTONOMOUS_CLOCK_EQUALS_AXI_ACLK=YES`

`NEW_CDC_REQUIRED=NO`

`RESET_DOMAINS_IDENTICAL=NO`

`R1H_MMIO_READ_SERVICE=SYNC_ONE_OUTSTANDING`

`R1H_REQUIRED_RESPONSE_STATUS=AXI_OKAY_ONLY`

`R1H_INVALID_OR_MISALIGNED_READ_VALUE=ZERO`

`R1H_DIAGNOSTIC_WRITE_BEHAVIOR=FORWARD_UNCHANGED`

`COMBINATIONAL_512_TO_1_INDEX_MUX=REMOVE`

`COMBINATIONAL_64_X_192_RECORD_MUX=REMOVE`

`SOURCE_MUTATIONS=0`

`SYNTHESIS_RUNS=0`

`IMPLEMENTATION_RUNS=0`

`HARDWARE_ACTIONS=0`
