# AHD v41 G2B-IMPL Focused Offline Test Report

## Result

**PASS — focused offline simulation and host qualification.**

This report covers deterministic RTL simulation, exhaustive MMIO routing simulation, ABI record checking, and host-parser/frame-fixture tests for the minimal one-channel C2H implementation. Every test described here was offline-only. No DUT was accessed, no FPGA was programmed, no PCIe operation was performed, no driver was changed, and no hardware DMA was run.

This focused-test PASS does not override the clean-build gate. The authoritative build completed synthesis and `opt_design`, then stopped at the post-opt resource gate with `21412/20800` LUTs (`102.942%`), reason `LUT_GT_90_PERCENT`. The engineering gate is therefore blocked by `BLOCKED — RESOURCE_HEADROOM_REQUIRES_ARCHITECT_REVIEW`, independently of the passing tests below.

## Authoritative test inputs

| Item | Identity |
|---|---|
| One-channel C2H RTL | SHA-256 `8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471` |
| Core testbench | SHA-256 `551D9E1766D5EDF571CCE5C06817572D4DD5DE5677D64FB9E78066A431176CD3` |
| MMIO router RTL | SHA-256 `2C4B4B037116447DAF12FF1C78D7C9096BD77D14F6E2CB59EF2ABC9CB806BE25` |
| Router testbench | SHA-256 `A4A1E770E55643B3D682C93D7822EEAE634610FED055107A42711AFD0751AF50` |
| Simulator | Vivado XSim 2025.2, software build 6299465 |
| Frozen ABI JSON | SHA-256 `AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6` |

## Focused test matrix

| Area | Coverage | Result |
|---|---|---|
| Valid active line and record commit | Complete deterministic active lines admitted, formatted, committed, scheduled, streamed, and released | PASS |
| Record geometry | 4096-byte records, 64-byte header, 3840-byte payload, 192-byte zero padding | PASS |
| AXI4-Stream | 64-bit data, 512 beats, full `TKEEP`, `TLAST` only on beat 511, release after final handshake | PASS |
| Backpressure | Always ready, single-cycle stalls, long stalls, random stalls, first-beat stall, mid-record stall, pre-`TLAST` stall, and `TLAST` stall | PASS |
| Four-slot ring | Four slots, full-ring drop before write, generation/ownership retirement, no committed overwrite, exact release count | PASS |
| Sequences | Attempt gaps for dropped/malformed inputs, global sequence on streamed records, source sequences, epoch restart behavior | PASS |
| Reset epoch | Stream reset, standalone reset coalescing, later AXI hard-reset episode, source-reset separation, overlap/collision cases | PASS |
| MMIO controls and counters | Enable, stream reset, statistics reset, snapshot request/ack and data settling, registered predicates | PASS |
| Fatal behavior | Formatter and ownership fatal injection, active-record integrity, gating, W1C/recovery ordering | PASS |
| MMIO decode isolation | Exhaustive address routing over the complete 17-bit request address space | PASS |
| ABI golden vectors | Eight deterministic RTL records compared byte-for-byte; all sixteen records structurally parsed | PASS |
| Host parser | Eleven unit tests, simulated-stream parse, deliberate negative controls, complete-frame reconstruction | PASS |

## Authoritative one-channel C2H XSim run

Artifact root:

`C:\FPGA\G2B_XSIM_AUTHORITATIVE_20260829_02`

The terminal marker was:

```text
G2B_ONECH_C2H_XSIM_PASS records=16 bytes=65536 releases=16 expected_queue=16
```

Observed totals were 16 records, 65,536 bytes, 16 final-beat slot releases, and 16 expected records drained. The captured stream is exactly 16 complete 4096-byte records.

Backpressure coverage exercised all required modes:

- always ready;
- isolated single-cycle stalls;
- long stalls;
- randomized stalls;
- stall on the first beat;
- stall in the middle of a record;
- stall immediately before `TLAST`;
- stall while `TLAST` was asserted.

Assertions checked that `TVALID`, `TDATA`, `TKEEP`, and `TLAST` remained stable under stall; the beat index advanced only on `TVALID && TREADY`; no beat was lost or duplicated; `TLAST` appeared only on beat 511; one record remained contiguous; and the slot release retired only after the final-beat handshake.

The same run passed focused ring, sequence, reset, MMIO, CDC-protocol, and fatal-path scenarios, including:

- complete ring-full drop before any record byte was written;
- malformed-attempt gap and discontinuity context;
- formatter-fatal and ownership-fatal injection with reset recovery;
- combined control ordering and reset/enable retry behavior;
- standalone reset coalescing and later AXI hard-reset epoch behavior;
- source reset versus transport-reset separation;
- source-reset/transport-request and `TLAST`/reset collision cases;
- release, commit, ownership-request, and generation retirement barriers;
- coherent snapshot acknowledgment/data settling and hard-clear baseline settling;
- fatal-before-beat-0 admission gating and in-flight record preservation;
- registered ring predicates exposed through MMIO.

Core run evidence identities:

| Artifact | SHA-256 |
|---|---|
| `g2b_records.bin` | `BF41EE32E9D1855C86DC2BCAEFD151AFCD83AEAC37900C4D5AD145B29EA2C948` |
| `G2B_XSIM_RECEIPT.txt` | `9609B4E9CFE643FE63A91C255484189BBAFA165DDF7DD3B34114308AAB1EA38E` |
| `xsim.console.log` | `FB04753C6BA9D4E9C7510657C5823C244A99F95FD4436C906C52C9987FEBE986` |
| `xvlog.console.log` | `D3BCE2C237B434B2E841ECCA01EFA6FBDFBDBF18ED0961B43996B02226B66121` |
| `xelab.console.log` | `379BF4EE45BC911D3C544BC72AE3F394D13A7F14A15CF821A804557E798F460D` |
| `COMMANDS.txt` | `BC2554E5F67ECFF1B5F02FF66211FBB64EB4021B7BC89E0A8C279BA850A1D683` |

## Exhaustive MMIO router XSim run

Artifact root:

`C:\FPGA\G2B_ROUTER_XSIM_AUTHORITATIVE_20260829_02`

The terminal marker was:

```text
G2B_MMIO_ROUTER_XSIM_PASS addresses=131072 boundaries=9
```

The test exhausted all 131,072 byte addresses in the 17-bit aperture. Exactly 1,024 addresses in `0x3800..0x3BFF` selected G2B; the remaining 130,048 addresses selected the legacy path, including `0x3C00..0x3FFF`. It also covered nine aligned/unaligned boundary cases and four response pass-through scenarios. The complete run comprised 131,081 request vectors and 655,394 checks. No alias or decode leakage was observed.

Router run evidence identities:

| Artifact | SHA-256 |
|---|---|
| `G2B_ROUTER_XSIM_RECEIPT.txt` | `EC9F1DBC71C7A532B0D8794657D0F3062D87A8B3A47D47500DE58DDB8D961623` |
| `router_xsim.console.log` | `8EE195C7FD867355AB7D4E2C4B2FE35ED980FDAE5793A99D9FF1BA85B1AA8B28` |
| `router_xsim.log` | `13CC36110D5545CCB9889592CD2A42D054E37306B5489C3CC3D73CA62050639E` |
| `RESULT.txt` | `3EDF82695A450C2618EECE9ED68F7110E45EF3D3980266AE1A6284E85228CA45` |

## Host and ABI qualification summary

The Python host-tool suite completed **11/11 tests PASS** in 9.636 seconds. It covered contract identity/drift rejection, exact record generation and comparison, fail-stop structural validation, flag/window/slot constraints, epoch/attempt/global/source discontinuities, G2B mapping checks, partial-frame discard, a complete 1080-line frame, and CLI operation with an explicit contract path.

The ABI checker compared the first eight deterministic RTL records against contract-derived expected bytes. Each comparison matched 4096/4096 bytes, had zero mismatches, and verified zero padding. It then structurally parsed all 16 RTL records with no structural failure.

The qualification frame fixture reconstructed one complete raw UYVY frame from 1,080 valid records: 1,080 unique line sequences `0..1079`, one epoch, no missing or duplicate lines, and consistent attempt/global/source ordering. The 4,147,200-byte expected and reconstructed raw files have the identical SHA-256 `759FFE7AC7A8B8F435FFF6B9ED76FA11A498165C3FCC026E24DBE9C3BCB2603E`.

## Superseded diagnostic run

`C:\FPGA\G2B_XSIM_AUTHORITATIVE_20260829_01` is **superseded** and is not qualification evidence. It reported three fixture-ordering failures because its stimulus allowed a standalone transport-reset request to finish before the host reset request began, so the RTL correctly created two distinct epochs. Run 02 forced actual overlap for the coalescing case; the unchanged RTL passed. The run-01 outcome is therefore retained only as a test-fixture diagnostic, not characterized as an RTL regression.

## Qualification boundary

All payloads and records in this report came from controlled simulation or offline host fixtures. They are not hardware DMA evidence, do not establish runtime PCIe Gen2 negotiation, and do not prove the required 288 MB/s application payload rate. Hardware qualification remains a later gate.
