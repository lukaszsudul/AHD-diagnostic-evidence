# R3R1 credential-helper source review

Task: `G2B-HW0-PRODUCT-R3R1`

Helper: `C:\FPGA\G2B_HW0_PRODUCT_R3R1_20260906T172600Z\scripts\Invoke-R3R1DutConnection.ps1`

SHA-256: `50C1736A178B8807C1AEC752041C266BF58CE7015765EDCCC0D7C4A688F2F42E`

Bytes: `16471`

Allowed private root: `C:\FPGA\G2B_HW0_PRODUCT_R3R1_20260906T172600Z\private`

## Review

- The helper is implemented as one fresh R3R1-local source file and neither invokes nor imports another helper.
- Exact DUT IP, Linux account, PuTTY binary hash, and accepted host-key fingerprint are pinned internally.
- The credential source is pinned as a read-only input. The password is parsed only in memory and is never passed as a process argument.
- Every temporary credential filename is a new GUID under the exact private root. Canonical descendant validation and a predecessor-root pattern reject boundary escape.
- The temporary file is created exclusively, receives a protected ACL for the current controller SID only, and the ACL is read back and validated.
- The process argument audit rejects `-pw`, permits the credential-equivalent text only in its authorized login-name role if that contextual equality happens to exist, and requires the unique `-pwfile` path.
- Inherited environment entries containing the credential are removed and rechecked before process start.
- Command stdout and stderr are captured separately. Download payload bytes are never written to the connection receipt. Any credential occurrence in output is redacted before receipt creation.
- Controller receipt and transfer-destination paths are canonicalized and constrained to the fresh R3R1 allowlist. Upload sources must be non-private files below the fresh run root. Remote transfer paths must remain below the fresh Linux R3R1 root.
- The temporary credential file is deleted in `finally`; deletion status is checked and forces a distinct nonzero exit on failure.
- A bounded timeout kills the process tree and returns exit `124`. Otherwise the exact Plink/remote exit code is retained.
- Static PowerShell parsing found zero syntax errors.

The helper was not executed because the independent frozen-ABI/write-authority conflict was discovered before the first authenticated connection.

`R3R1_CREDENTIAL_HELPER_SOURCE_REVIEW = PASS_STATIC`
