# AHD v41 R0 → R1 Implementation Contract

## 1. Authority and hard boundary

R1 may implement exactly two candidates and nothing else:

- Candidate A: **R1i-a / C1**
- Candidate B: **R1i-b / C2**

R1 may review, edit the allowlisted source, run contracted offline tests, and build both candidates. R1 may not execute hardware unless a later instruction explicitly authorizes it. R1 may not modify or replace the qualified C3 commit/bitstream, C0 control, primary FPGA_AHD worktree, NVP table, or approved safe baseline.

Both candidates are sibling derivatives whose direct source base is:

`20c3323d79d3896edc586d6db1df7deee60f9e41`

Qualified tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`.

Candidate A must not contain Candidate B changes. Candidate B must not contain Candidate A changes. Their source-diff merge bases and parents must be proven.

## 2. Git isolation

R1 creates the research isolation; R0 did not.

- Orchestration branch: `research/v41-r1i-causal-isolation`
- Worktree: `C:\FPGA\R1I_RCA`
- Candidate refs: separate sibling refs from the qualified base, recommended `research/v41-r1i-a` and `research/v41-r1i-b`

Do not modify `C:\FPGA\FPGA_AHD`. Verify the resolved worktree path and base object before any edit. No force push, history rewrite, submodule update, or merge from unrelated branches is authorized.

## 3. File allowlist

The only synthesizable tracked file allowed to differ from the qualified base is:

`rtl/nvp/nvp6134c_i2c_bringup.vhd`

No other RTL, table, top, XDC, XCI, IP, build-setting, or generated-source change is allowed. New non-synthesized focused tests may be added only under an isolated R1 research-test directory and must not enter any synthesis file set. Existing files outside the single RTL allowlist must remain byte-identical. If a tool or build script requires a tracked change, stop and request a contract amendment.

No state may be inserted, removed, reordered, or renamed. Inherited state/debug encodings must remain identical.

## 4. Candidate A — exact authorized change

### Functional definition

Candidate A retains the complete qualified-R1i physical-HIGH gating, timeout, waveform, and recovery shell. It changes only which filtered SDA value supplies each slave-ACK decision.

Allowed states/helpers to edit:

- `ACK_W_LOW`, `ACK_W_HIGH`
- `ACK_REG_LOW`, `ACK_REG_HIGH`
- `ACK_DATA_LOW`, `ACK_DATA_HIGH`
- `ACK_R_LOW`, `ACK_R_HIGH`
- the ACK observation helper/procedure needed to pass the selected held value
- reset/clear assignments solely for the two new local ACK-latch signals

Allowed new local signals:

- one selected ACK value latch;
- one selected ACK valid latch.

Equivalent names are allowed, but no additional functional state, counter, MMIO bit, or output is allowed.

Required behavior:

1. `ACK_*_LOW` continues holding SCL LOW, releasing SDA, preserving existing `capture_early_ack`, and arming/clearing the selected latch.
2. Entry to `ACK_*_HIGH` releases SCL through the unchanged combinational decoder.
3. On the first controller rising edge that observes `scl_filtered_r='1'`, latch `sda_filtered_r` and valid.
4. If filtered SCL returns LOW before the existing qualified dwell finishes, invalidate the latch and re-sample the first observed-HIGH edge of the next interval.
5. Keep the existing tick reset/stall and full `DIVIDER+1` consecutive-HIGH dwell exactly unchanged.
6. At the terminal tick, use the held sample for last-ACK, phase/raw NACK counters, first-NACK abort decision, and related records. Do not use live or raw SDA for the selected decision.
7. If no valid HIGH interval completes, use the exact existing timeout/recovery path.
8. If selected-sample valid is unexpectedly absent at a scheduled ACK decision, treat it as a qualification failure; never fall back to live or raw SDA.

Signals/logic that must remain textually and functionally unchanged include `requires_scl_high`, `tick_cnt` gating, SCL timeout constants/process, open-drain output decoder, SDA/SCL synchronizers/filters, read-data sample path, START/repeated-START, STOP/abort/BUS_FREE/retry/backoff bodies, bank-safety code, telemetry packing/ABI, and all table/reset/start/settle logic.

### Expected telemetry

- Telemetry addresses, magic, version, policy flags, lane order, and record format are unchanged.
- Existing end-of-LOW early counters retain their meaning.
- Qualified/raw NACK fields report Candidate A’s held first-filtered-HIGH selected value.
- Early-false fields compare the legacy end-of-LOW observation with the Candidate A selected result.
- SCL wait/timeout and recovery counters retain exact C3 semantics.
- Runtime source identity must identify the Candidate A commit; the inherited policy flags are not the candidate identifier.

## 5. Candidate B — exact authorized change

### Functional definition

Candidate B retains the nominal late ACK state/tick and complete R1i safety/recovery shell, but ordinary protocol-HIGH scheduling does not wait for filtered physical SCL.

Authorized ordinary protocol-HIGH set:

`START_W_A`, `START_W_B`, `SEND_W_HIGH`, `ACK_W_HIGH`, `SEND_REG_HIGH`, `ACK_REG_HIGH`, `SEND_DATA_HIGH`, `ACK_DATA_HIGH`, `REP_HIGH`, `REP_START_A`, `SEND_R_HIGH`, `ACK_R_HIGH`, `READ_HIGH`, `MASTER_NACK_HIGH`.

Allowed logic to edit:

- a pure predicate/helper distinguishing progress-gated states from the ordinary protocol-HIGH set;
- the divider reset/stall expression and main high-state dispatch, only to remove filtered-SCL waiting for that exact set;
- terminal dispatch for the exact set when `scl_filtered_r='0'`;
- the four existing ACK-high bodies only to enforce the endpoint-high guard before live filtered-SDA sampling;
- reset/clear assignment only if an existing timeout pulse needs one local, non-MMIO one-shot to prevent double counting.

Required behavior:

1. The internal divider runs from entry to each authorized ordinary protocol-HIGH state without reset/stall from `scl_filtered_r`.
2. At its terminal tick, normal progress occurs only if filtered SCL is HIGH. ACK states then sample live `sda_filtered_r` at that existing endpoint.
3. If filtered SCL is LOW at an ordinary protocol-HIGH endpoint, do not consume SDA/read data, do not count an ACK opportunity, and do not enter a later phase. Record exactly one SCL-unavailable/deadline error and dispatch into the existing C3 abort-high/STOP/BUS_FREE/retry path.
4. The existing 20 µs watchdog remains active; its cleanup target and all cleanup bodies are unchanged.
5. START/repeated-START state bodies and output-drive equations remain exact C3, but their scheduler is part of the authorized divider-only set. `STOP_B`, `STOP_C`, abort cleanup, and BUS_FREE retain exact physical qualification.
6. At the frozen source parameters, `DIVIDER=1250`, the scheduled dwell is 1251 base-clock edges, and `C_SCL_TIMEOUT_CYCLES=1250`; endpoint-low dispatch reuses the coincident existing timeout policy and must not create a shorter timeout constant.

Signals/logic that must remain unchanged include the selected late ACK state/tick, raw/synchronized/filtered input paths, output decoder, timing constants (`CLK_HZ`, `I2C_HZ`, `DIVIDER`), first-NACK abort, START/repeated-START state bodies/output equations, STOP/abort/BUS_FREE/retry/backoff bodies, bank safety, telemetry ABI/packing, table/reset/start/settle, and read/ACK values when the endpoint is physically HIGH.

### Expected telemetry

- Telemetry ABI/magic/version/addresses/lane order remain unchanged.
- ACK opportunities and selected/qualified NACKs increment only when filtered SCL is HIGH at the endpoint and SDA is actually selected.
- End-of-LOW early counters remain passive and unchanged.
- An endpoint-low guard increments the existing SCL-unavailable/timeout indication exactly once and produces the inherited error-code/recovery record. Any such event makes the hardware run causally `INCONCLUSIVE`.
- Retry/recovered/exhausted behavior after dispatch is exact C3.
- Runtime source identity identifies the Candidate B commit.

No implementation is permitted to sample SDA while filtered SCL is known LOW or to continue to the next protocol phase in that condition.

## 6. Frozen signals and structures for both candidates

Must remain unchanged:

- entity/generic/port list and instantiation hierarchy;
- state type membership/order/debug encoding;
- NVP address/data/table inputs and operation sequencing;
- `scl_meta_r`, `scl_sync_r`, SCL filter history/output and corresponding SDA path;
- `scl_oen_r`/`sda_oen_r` combinational decode;
- I²C frequency and divider constants;
- reset, POR, start latch and final settle;
- STOP, BUS_FREE, retry count/backoff targets, recovered/terminal distinction;
- physical-bank validity/invalidation and invariant telemetry;
- all MMIO/top/XDC/XDMA/IP/configuration files and interfaces;
- post-init probe behavior and telemetry clear semantics.

No new functional fanout from telemetry into the controller is allowed.

## 7. Required source-diff review

For each candidate independently, R1 must seal:

1. base commit/tree and candidate commit/tree;
2. clean `git status` and exact direct-base ancestry;
3. `git diff --name-only` showing only the single RTL allowlist plus any explicitly allowed add-only non-synth test directory;
4. `git diff --stat`, full unified diff, and `git diff --check`;
5. SHA-256 comparison proving every frozen tracked file byte-identical to base;
6. state enumeration/encoding comparison;
7. signal-fanout review for all new/changed signals;
8. line-by-line mapping of every functional hunk to one numbered contract clause;
9. independent review that Candidate A has no Candidate B predicate/guard change and Candidate B has no Candidate A sample latch;
10. explicit review that STOP/ABORT/BUS_FREE/retry/bank-safety bodies are byte-identical to C3.

Any unmatched hunk fails R1 and must be removed or separately authorized before build.

## 8. Offline test requirements

Without hardware, each candidate must pass:

- compile/elaboration and all inherited qualified-R1i focused tests;
- all four ACK phases with ACK, NACK, and phase opportunity reconciliation;
- synchronized/filtered late-ACK stimulus;
- SCL-low/stretch and 20 µs timeout stimulus;
- first-NACK abort and no-later-phase proof;
- legal STOP, BUS_FREE, exact retry ladder, recovery terminality;
- bank invalidation/invariant tests;
- MMIO ABI/backpressure/legacy-address compatibility;
- state-encoding/debug comparison;
- Candidate A assertion that selected valid comes from the completing HIGH interval and decision remains at the original tick;
- Candidate B assertion that the ordinary protocol-HIGH divider is SCL-independent, endpoint-low never samples/advances, and STOP/BUS_FREE remain qualified.

New tests must be non-synthesized and kept outside production file sets.

## 9. Build requirements

Build A and B separately from clean sibling refs using the same canonical flow as qualified R1i:

- Vivado 2025.2 build 6299465;
- part `xc7a35tcsg325-2`;
- top `ahd_capture_top_xdma`;
- identical XDC, XDMA XCI/configuration, synthesis/implementation strategy and seed;
- no incremental checkpoint or cross-candidate reuse;
- clean DRC and required timing closure;
- clock, I/O timing, utilization, and route comparison against C3;
- embedded runtime source commit verified in build outputs;
- bitstream, reports, source diff, logs, and manifests independently SHA-256 sealed.

A build is evidence, not hardware authorization. R1 ends after both offline candidate packages and review receipts are complete.

## 10. Hardware prohibition and later lock

R1 must not program, reset, power-cycle, enumerate, poll, or otherwise access the DUT unless a later instruction explicitly authorizes hardware execution. If later authorized, every action requires `FPGA_AHD_HW_LOCK`, sequential execution with G-track exclusion, and safe-baseline restoration.

## 11. R1 acceptance

R1 passes only if exactly two compliant sibling candidates exist, their diffs match this contract, offline tests/builds pass, source/bitstream identities are sealed, FPGA_AHD primary and qualified C3 remain unchanged, and no unauthorized hardware action occurred. Any need to change a frozen file/state/recovery behavior stops R1 for contract amendment.
