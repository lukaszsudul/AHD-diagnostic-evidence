# AHD v41 G2B-HW0 PRODUCT R3R4R6R2R2 main report

## Result

- Engineering gate: **FAIL**
- Evidence publication: **PASS**
- Overall result: **FAIL**
- First blocker: `R3R4R6R2R2_4K_PRIMARY_WINDOW_INCOMPLETE:PRIMARY_WINDOW_COMPLETE_NOT_RECEIVED_WITHIN_30_SECONDS`
- Underlying controller event: `R3R4R6R2R2_NATIVE_EVENT_TIMEOUT`

The exact 4-KiB prequeue itself passed: all 2500 distinct 4096-byte IOCBs were accepted in one `io_submit` call before stream enable. The finite receive window did not complete within the authorized 30-second interval, so `PRIMARY_WINDOW_COMPLETE` was never emitted. No second capture was attempted.

## Governed starting point

The Owner-attested cold-reset state was accepted without re-auditing the previous network outage or re-hashing existing bitstream, driver, ABI, SSOT, and predecessor artifacts. A fresh controller root and DUT-local root were used. The PRODUCT bitstream was programmed once to SRAM, DONE asserted, and the required warm reboot completed. The exact XDMA module was inserted once and the expected user and C2H nodes appeared.

## Offline 4-KiB tool gate

The final focused gate passed 9/9. The native source compiled on the DUT with `/usr/bin/gcc gcc (Ubuntu 15.2.0-16ubuntu1) 15.2.0` into an x86-64 Linux executable; its SHA-256 is `872D990397786C86A7C5F6AC89582DE7E46C6EB8F9EEAB233E9057BF6580749C`. The no-device smoke test returned 64. The source contains no active-DMA signal interruption, `O_TRUNC`, or `eop_flush`; it creates exactly 2500 indexed 4096-byte IOCBs, requires all submissions before `PREQUEUE_READY`, assembles by request index, and preserves positive completed buffers on its implemented failure-persistence path.

An initial auxiliary source-inspection run reported 8/9 because the inspector selected an earlier allocation-cleanup `free(primary)` rather than the final persistence boundary. The inspector was corrected to select the final occurrence and rerun; the native helper source and SHA-256 did not change. Both receipts are retained under `support/`.

## Session measurements

- Source readiness: PASS; NACK count 0; INIT_ERROR 0; fixed input 0; source ready and locked.
- S0: epoch 0, ERROR_STATUS `0x00000000`, LAST_ERROR_CAUSE `0x00000000`.
- One RESET_STREAM_STATE write advanced the epoch 0 to 1.
- S1: epoch 1, ERROR_STATUS `0x00000000`, LAST_ERROR_CAUSE `0x00000000`.
- Session-normalization W1C: none required.
- S2: epoch 1, ERROR_STATUS `0x00000000`, LAST_ERROR_CAUSE `0x00000000`.
- Prequeue: 2500/2500 IOCBs, 4096 bytes each, 10,240,000 bytes total, all accepted before enable.
- PREQUEUE_READY-to-enable latency: 146.171 microseconds.
- MMIO writes: reset 1, enable 1, normal disable 0, safety disable 1, normalization W1C 0, snapshot 2, unauthorized 0.

## Primary-window failure

No `PRIMARY_WINDOW_COMPLETE` event arrived within 30 seconds. The helper had not emitted or persisted its per-IOCB completion table, primary file, or helper-result receipt before terminal cleanup. Therefore exact host AIO completions, shorts, failures, pending count, received bytes, and received records are **NOT PROVEN**. The coherent FPGA failure snapshot later reported 2048 streamed records and last global sequence 2047; these FPGA counters are not substituted for host AIO completion callbacks.

The coherent failure snapshot, taken before terminal reboot and not called S3, recorded: epoch 1, CONTROL `0x00000000`, STATUS `0x000004FA`, ERROR_STATUS `0x00000007`, LAST_ERROR_CAUSE `0x00000001`, attempted 810022, committed 2052, streamed 2048, dropped 807970, overflow 807968, discontinuity 2, beats 1048576, last global 2047, last attempt 2049, and abandoned 0.

## Validation boundary

Because no durable primary file was produced, the first-record, 2500-record structural-integrity, continuity, BT.656, and complete-frame gates were not reached. No magic scanning, inferred parsing, or counter-to-AIO substitution was used. No raw record, UYVY frame, or camera PNG is published.

## Cleanup

The post-timeout safety disable completed. The parent observed 100 consecutive failure-path samples over the full 10-second window; all remained nonquiescent with CONTROL `0x00000000` and STATUS `0x000004FA`. The helper remained active, the module reference count was 1, and normal unload was unsafe. The exact pending-IOCB count was not durably reported; a local arithmetic estimate was not promoted to evidence.

The single authorized terminal graceful reboot was requested and accepted. No capture retry, forced process termination, forced unload, JTAG recovery, Flash access, or power cycle occurred. SSH did not return during six bounded publication-reconnect attempts, so driver unload, node removal, and Linux-lock release were not post-reboot verified. The controller lock was released last and credential remnants were zero.

## Decisions and nonclaims

- 4-KiB packet-granular prequeue: PASS.
- Primary finite capture: FAIL.
- Record-path integrity, stream continuity, BT.656 qualification, and frame reconstruction: NOT REACHED.
- Hardware subqualification: NOT PROVEN.
- Working causal model: `HOST_PREQUEUE_CONFIRMED_4K_AIO_REQUIRES_CORRECTION`.
- 60-second continuous performance: NOT RUN.
- Hardware throughput >=288 MB/s: NOT PROVEN.

The evidence commit identifier is reported out of band because a Git commit cannot contain its own final SHA. Commit-pinned remote byte/hash read-back was performed after publication.
