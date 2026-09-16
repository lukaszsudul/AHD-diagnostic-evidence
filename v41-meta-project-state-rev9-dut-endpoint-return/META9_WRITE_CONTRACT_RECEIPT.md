# META-9-DUT-IP-RETURN write-contract and pre-publication validation receipt

Executing role: `META_UPDATE_AGENT`.

```text
SSOT WRITE AUTHORIZED
UPDATE_TYPE: INTERFACE_CHANGE
EXPECTED_PROJECT_STATE_REV: 8
PROJECT_STATE_REV_AT_START: 8
RESULTING_PROJECT_STATE_REV: 9
EVIDENCE_REPOSITORY: lukaszsudul/AHD-diagnostic-evidence
EVIDENCE_COMMIT: 1c0bad816d98c4ce077e7237bd759c0c1bfbdb2e
EVIDENCE_DIRECTORY: v41-owner-decisions/2026-09-16-dut-endpoint-return-cont1r3r1
```

Owner/Architect decision: accept the sole operational DUT SSH endpoint
`10.132.1.111:22`; supersede `192.168.1.57:22` for future DUT work; record
`OWNER_ATTESTED_UNCHANGED_EXCEPT_IP`. Preserve historical evidence, technical
qualifications, PRODUCT authority, requirements, resource limits and unresolved
NACK causality. No physical DUT requalification or technical baseline promotion
is authorized by this metadata transaction.

The complete concrete task was frozen before SSOT edits as
`META9_DUT_IP_RETURN_TASK.md`, SHA-256
`76C0A78F031CD2A8AAE3FB3C8ECFE064A5E4B3D32C122103E96B9B68BF20AB32`.
The decision file at the pinned evidence commit was read back independently:
5,138 bytes, SHA-256
`1B77291101B0CEBF6FA201C2AF92BC5C94D4B480487A310502964F759B2736F9`.

Preflight: revision match YES; authorization literal YES; explicit decision
YES; immutable evidence commit and directory YES; 18/18 previous manifest
entries verified. Minimal affected set was frozen before edits. No operational
DUT SSH row existed among the 19 compatibility-matrix rows, so that CSV is
unchanged.

Actual affected SSOT files (15): `ACTIVE_BASELINES.md`, `CHANGELOG.md`,
`CURRENT_ARCHITECTURE.md`, `CURRENT_INTERFACES.md`,
`CURRENT_REQUIREMENTS.md`, `CURRENT_RESOURCE_STATE.md`, `CURRENT_STATUS.md`,
`CURRENT_TRACKS.md`, `EVIDENCE_MAP.md`, `GOVERNANCE.md`,
`OPEN_DECISIONS.md`, `PROJECT_STATE.json`, `README.md`,
`SHA256_MANIFEST.txt`, `TRACK_STATUS.json`.

Pre-publication validation: both JSON files parse and report revision 9 with
governance version 1; current revision headers agree; lifecycle status values
are valid; endpoint and attestation match the decision; the compatibility
matrix hash remains
`4BE2FACBEC64760F1BFBF56F5D79E294F16ACD5C19C3376EFB6A99C9C8AC87F2`;
the 18-entry new SSOT manifest validates 18/18 and has SHA-256
`5F5BEE9FB84BE98AE5D1A24B98CD487C42C8C70DC785C2326F0AC634815DCCCC`.
Only one changelog entry was appended; all earlier entries remain unchanged.
No DUT, build or hardware operation occurred in META-9.

The publication commit and remote read-back are post-commit executor checks,
recorded separately after publication; this receipt makes no premature claim
that they have passed.
