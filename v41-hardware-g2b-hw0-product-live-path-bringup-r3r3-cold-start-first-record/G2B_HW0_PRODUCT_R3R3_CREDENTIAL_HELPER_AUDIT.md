# Credential-helper audit

Result: PASS.

- Helper: C:\FPGA\G2B_HW0_PRODUCT_R3R3_20260906T200624Z\scripts\Invoke-R3R3DutConnection.ps1
- SHA-256: EA6DEBB816C029726D00D9227A2DE5FB352C1692849A7A4BB96583CC164804D1
- Authenticated helper invocations: 53
- Every DUT connection used this exact R3R3-local helper: YES
- Credential in process arguments: NO
- Pinned host key, -pwfile, agent disabled, sharing disabled: PASS
- Temporary credential deletion after every invocation: PASS
- Final protected-private remnants: 0
- Helper transport nonzero exits: 2 (one pre-create permission failure and the intentionally stopped T3 command; neither authorized a second hardware attempt)

The credential value equals the governed public login. The conservative literal scan was therefore non-discriminating; the final source audit proved occurrences were login/path identity only, not an embedded secret. No credential file or secret-bearing receipt is published.
