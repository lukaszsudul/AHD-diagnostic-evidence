# SCAN1-R1 verification plan

## Static/elaboration

Prove PRODUCT has no scanner/executor instances or MMIO interception; scanner write ROM contains only register 0xFF; manifest ROM matches the published SHA; 25-kHz constant and fixed timeout constants are compile-time; no autonomous timer, double buffer, runtime timeout or recovery logic exists.

## Deterministic simulation

Nominal all groups; clock stretching at every SCL-high state; WADDR, REGADDR and RADDR NACK; SCL timeout; bus-idle timeout; each bank readback mismatch; entry-bank read failure and degraded Bank0 fallback; restore failure; autoinit pending between groups and inside a group; reset during every active state; A8_PRE/A8_POST change; START while BUSY; START before ACK; ACK protocol; ABORT; host backpressure; generation stability; all MMIO write responses; reserved reads zero; manifest/entry corruption rejection.

## Hardware gates under later authority

MAGIC/version/capabilities exact; 10,000 ONESHOT scans with stable ID/revision and no unexplained error growth; every select read back; every entry bank restored; reset/preempted scans never valid; camera connect/disconnect repeatability or honest bounded no-signal result; scanner-on versus scanner-off byte-exact test-pattern video equivalence. First failed gate stops; no retry broadening.
