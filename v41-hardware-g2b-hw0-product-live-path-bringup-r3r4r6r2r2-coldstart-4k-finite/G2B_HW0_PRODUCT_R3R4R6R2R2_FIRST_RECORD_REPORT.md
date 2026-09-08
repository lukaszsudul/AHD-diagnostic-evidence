# First-record report

Result: **NOT_REACHED**

The helper did not finish and fsync the primary file before terminal cleanup. No host primary record bytes were available for authoritative fixed-offset parsing. FPGA counter values were not treated as raw record bytes. First-record integrity, continuity, flags, and hashes are therefore not claimed.
