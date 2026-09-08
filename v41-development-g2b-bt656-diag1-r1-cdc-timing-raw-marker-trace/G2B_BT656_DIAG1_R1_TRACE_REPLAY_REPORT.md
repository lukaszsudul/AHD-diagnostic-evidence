# Trace replay report

Classification: `FUNCTIONALLY_EQUIVALENT_SYMPTOM_REPRODUCED`.

The current uncorrected PRODUCT parser was given a canonical clean prehistory through line 1078, then the captured raw marker bytes, source-ready=1, and exact marker-to-marker source-clock intervals from the line-1079 SAV through the 300000-clock trace-freeze boundary. Streaming was enabled to expose the functional admission consequence that the hardware trace (captured with enable_applied=0) could only observe passively.

Replay result: 115 captured markers; 21 malformed increments, all reason 2; one source drop, reason 2; one lock loss; one lock reacquisition; line-0 SAV present and parsed but no attempt/commit; line-1 committed; composed line-1 flags `0x00000034` (VALID + DISCONTINUITY + MALFORMED_PRECEDING).

The final partially captured line 11 is excluded exactly at the hardware freeze boundary; a later simulator-only missing-EAV timeout is not part of the trace window.

After correction, the same physical marker pattern produces zero boundary malformed/drop events, line 0 commits with SOF/VALID `0x00000021`, and line 1 commits with VALID `0x00000020`.
