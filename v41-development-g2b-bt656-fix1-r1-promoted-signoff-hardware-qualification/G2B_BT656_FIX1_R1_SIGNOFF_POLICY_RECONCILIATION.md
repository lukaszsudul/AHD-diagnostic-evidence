# Sign-off policy reconciliation

The prior harness stopped on `EXPECTED_17_FOUND_11`. That was task-local governance drift, not a constraint or design failure. Current promoted authority contains 11 active `set_bus_skew` relations (Groups 1-8 and 10-12) and six retired relations governed by settling-plus-structural-CDC methods (Groups 9 and 13-17). Exactly 11 active relations were exported and restored; zero retired relations reappeared. No constraint was added, weakened, waived or suppressed.
