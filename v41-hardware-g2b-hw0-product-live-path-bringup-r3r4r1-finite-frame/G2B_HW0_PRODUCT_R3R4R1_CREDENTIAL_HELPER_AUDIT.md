# R3R4R1 credential-helper audit

Ordered credential-helper hard gate: `FAIL (NOT REACHED)`.

- Fresh helper: `Invoke-R3R4R1DutConnection.ps1`
- SHA-256: `74A4342D7B14DF0837ACD3D3C808FE4FA3AF17C6A3D518E1A11A7C38F2B9E659`
- Delta from published R3R4 helper: `IDENTITY_ONLY / PASS`
- Exact IP and pinned host key preserved: `YES`
- Plain credential process argument introduced: `NO`
- ACL-restricted temporary file and finally deletion preserved: `YES`
- Helper invocations: `0`
- Credential remnants: `0`

The separate ordered syntax/static hard gate was not advanced after the earlier
self-test failure. No DUT connection occurred.
