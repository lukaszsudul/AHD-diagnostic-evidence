# Simulation and static-gate matrix

| Gate | Result |
|---|---|
| Protected blob/static source gate | PASS |
| Legacy 17-word NACK map read/write-invariance | PASS |
| R1e measurement page decode/read-only behavior | PASS |
| Existing control/status regression | PASS; 3,047 reads |
| Existing AXI-Lite host bridge regression | PASS |
| Exact R1 lifecycle monitor | PASS |
| Exact R1 lifecycle register page | PASS |
| Probe adversarial pattern | PASS; 12 probes, ACK 8, NACK 4, first 2, last 9, max run 3 |
| Probe pre-init inactivity | PASS |
| Probe bus-idle timeout | PASS |
| Probe released-SCL timeout | PASS |
| Probe 10,000 all-ACK stream | PASS; count 10,000, no timeout |
| Address-only decoded transaction shape | PASS; every byte `0x60`, zero register/data/read bytes |
| Reference/candidate pre-`init_done` cycle equality | PASS; 1,814,611 compared cycles |
| Autoinit transaction stream byte equality | PASS |
| Probe active/bus drive before `init_done` | 0 / 0 |
| Exact 25-kHz lifecycle model | PASS; 132,584,734 |
| Existing 25-kHz NVP regression | PASS, including ACK/NACK/stuck-bus/filter/reset cases |
| Existing NVP power/reset/start timing | PASS |
| Existing D2b sequence | PASS |
| Host decoder/statistics fixtures | PASS |

PRE_INIT_DONE_CYCLE_EQUIVALENCE=PASS

AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=YES

PROBE_TO_AUTOINIT_FUNCTIONAL_FANOUT=0_BY_SOURCE_BOUNDARY

MEASUREMENT_TO_AUTOINIT_FUNCTIONAL_FANOUT=0_BY_SOURCE_BOUNDARY
