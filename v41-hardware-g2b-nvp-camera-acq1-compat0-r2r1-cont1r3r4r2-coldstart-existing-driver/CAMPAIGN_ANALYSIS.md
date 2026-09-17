# Incomplete-campaign analysis

Control scan: `1/1 PASS`, generation 1, 82 entries, 10 groups, 105
transactions, no retry. Campaign: **25/1000** complete scans (generations
2–26). Fifteen campaign scans had exactly 105 transactions; ten scans had
retries, with 11 recovered entry events overall. All 11 are first-attempt
`REGADDR_NACK` with successful retry. No incomplete scan is included in
these denominators.

The 25 complete campaign scans retained 2,050 entry exposures and 250 group
records; including control, 2,132 exposures and 260 group records. Every
complete scan retained the full 870-word telemetry payload and 82-entry
legacy snapshot privately before ACK, with zero mutation, overflow,
projection, A8-bookend or bank-restoration failures. For each complete scan,
observed transactions equal `105 + retried_entry_count`. The failing next
scan is a separate incomplete hardware receipt.

Frozen preregistration SHA-256:
`18CDD7FBC67ABDB799475CE509BC686C3A2CD0E7153BC4E44910ABC809B5DF8C`.
The Owner-attested cold start and deployment warm reboot changed the starting
condition relative to CONT1R2. No thresholds or analysis bins were changed.
Because the campaign stopped at 25/1000, the only governed causal
interpretation is `NOT_ASSESSED_CAMPAIGN_INCOMPLETE`. The partial event
distribution must not be turned into a 1,000-scan error rate, a bank-local
causal claim, a 10,000-scan qualification or evidence of a real camera frame.
