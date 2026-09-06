# G2B-HW0-PRODUCT-R3 DUT lock and exclusivity receipt

## Lock chronology

- controller lock acquired: `2026-09-06T14:02:30.4469117Z`;
- Linux lock acquired: `2026-09-06T14:09:30.152963Z`;
- Linux lock path:
  `/tmp/ahd-g2b-hw0-product-r3-20260906T140148Z.lock`;
- Linux lock released after final state capture: YES;
- controller lock released last: `2026-09-06T15:19:11.0240810Z`.

Held controller receipt SHA-256:
`7C86CAF7891347B9CE9C3DDBF404359DB20EE7B53AC7BEA0EDB43F926D769739`.

Remote-reported Linux release-receipt SHA-256:
`129D1978B153BDDF10F80A5194BF40842A229CB3C26DD7F7EC92A7CF91AB1010`.
That remote receipt was not copied locally for independent rehash.

## Exclusivity

- relevant DUT process count before lock: 0;
- relevant hardware/JTAG process count after JTAG: 0;
- PCI-control open descriptors: 0;
- other active hardware tasks and relevant locks: 0;
- one transient unrelated controller `ssh.exe` caused a preserved V4 fail-closed
  result; V5 target correlation proved zero DUT-directed background connection;
- both XDMA modules and all XDMA nodes/classes absent;
- endpoint unbound;
- controlling exclusivity result: PASS.

## Credential hygiene and exact failure

The target/host key was pinned, no password appeared in process arguments,
temporary password files were ACL-restricted and deleted, and outputs passed
redaction checks. The initial helper nevertheless created its transient file
under the prior R1 artifact tree:

`C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\secret`

No credential remains and no evidence was overwritten, but that immutable
location crossing is:

`FAIL — PRIOR_IMMUTABLE_ARTIFACT_BOUNDARY_VIOLATION`

Later R3-local correction does not erase the violation.

