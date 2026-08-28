# G2A Public Evidence Sanitization Receipt

## Scope

- Private evidence source: `<PRIVATE_EVIDENCE_ROOT>`
- Isolated publication clone: `<PUBLICATION_CLONE>`
- Publication directory: `v41-development-g2a-r1i-gen2-offline-build`
- Sanitization was applied only to the isolated public copy. Private build and evidence originals were not rewritten.

## Fail-closed whitelist

The public candidate contains only required root evidence, curated textual build reports/logs, curated offline-test logs/receipts, four reproducibility files, and the verified bitstream. It excludes DCPs, generated IP/HDL, the full product source, project/cache/run directories, simulator databases, waveform databases, archives, and all superseded/NOT_RUN test trees.

The initial curated copy contained 117 files and 104,192,332 bytes before the evidence index, manifest, and publication receipts were added. Of 115 non-bitstream/non-patch text files, 77 required the first host/path sanitization pass and four required a case-insensitive root normalization pass.

## Sanitization

The public copy replaces:

- build host with `<BUILD_HOST>`;
- user-profile paths with `<USER_PROFILE>`;
- source/build/evidence/temp/launch roots with named placeholders;
- remaining private FPGA workspace roots with `<FPGA_WORKSPACE>`.

Commit/tree identities, tool version, part, configuration values, timing/resource results, PCIe identifiers, CDC hierarchy, and artifact hashes were retained. `G2A_SOURCE_DIFF.patch` and the bitstream were not rewritten.

## Verification

| Check | Result |
|---|---:|
| Host/user/private-root matches outside the sealed patch and bitstream | 0 files |
| Secret-token pattern matches | 0 files |
| Email-address matches | 0 files |
| Private-IP matches | 0 files |
| Bitstream host/path/token binary matches | 0 |
| Reparse points/symlinks | 0 |
| DCP files | 0 |
| XCI files | 0 |
| XDC files | 0 |
| VHDL files | 0 |
| Vivado project or simulator-database files | 0 |

`gitleaks` and `trufflehog` were not installed, so no claim is made that either tool ran. The gate used deterministic regex scans, extension/path allowlists, binary-safe searches, and manual category review.

## Sealed identities

- Private/public source patch SHA-256: `BD2796E63CDBBA0AE974691F5F0A6511CBE9B23DE9CA369C9AA24A4837E449A2` — MATCH
- Private/public bitstream SHA-256: `4F74CC4AC8619B7509D46D74ED919FA81C5C9CC69D7BBDF6F34ED46D363E341E` — MATCH
- LTX: not produced; `write_debug_probes` was attempted and recorded `LTX_ERROR=NONE`.

## LFS policy

Path-scoped Git LFS rules cover the G2A `.bit`, potential `.ltx`, and the 76,996,215-byte `TIMING_SUMMARY.rpt`. DCP publication remains prohibited.

Result: `PUBLICATION_SANITIZATION_GATE=PASS`.
