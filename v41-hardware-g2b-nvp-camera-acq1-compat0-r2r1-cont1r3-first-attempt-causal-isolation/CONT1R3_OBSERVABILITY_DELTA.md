# Narrow scanner observability delta

The existing low-level master already exposes raw completion causes (WADDR/REGADDR/RADDR NACK and timeouts) and has bounded SCL qualification; the SCAN1 retry path previously lost the first cause when its retry succeeded. The new scanner sideband stores the raw and decoded first cause, second-attempt outcome, final read byte, exact manifest entry and actual group context. It also stores a first-acceptance timestamp and preceding successful group-verify timestamp for every clean or failed entry, plus transaction sequence/counter. The legacy frozen snapshot and control commands remain unchanged.

The scanner collects at most 82 first-attempt events in its 82-entry complete scan. Overflow, incomplete population, stale generation and any hard error cannot produce a measurement PASS. Telemetry remains frozen with the legacy snapshot until ACK. The added FPGA state has no fanout to command selection, retry eligibility, timeout thresholds, I2C frequency, SCL/SDA generation or bank restore.

Pass-through additions are an existing master sequence input into the diagnostic scanner and read-only sideband selection in the diagnostic wrapper/top. Source hashes for the master, manifest and executor match the parent; all functional NVP writes remain prohibited in this campaign.
