# Publication Operation Ledger

Task: publish the qualified AHD v41 R1i–R2 PoC evidence to `lukaszsudul/AHD-diagnostic-evidence`.

| Operation | Result |
| --- | --- |
| Verified original qualification directory | PASS |
| Verified R1i bitstream SHA-256 | PASS: `F6A6905D…D3C6` |
| Verified original internal ZIP SHA-256 | PASS: `6341F934…519F` |
| Verified original ZIP readability and file hashes | PASS: 192/192 files |
| Audited original ZIP for public-safety | PASS_WITH_REDACTION: internal ZIP withheld |
| Verified exact R1h and Formal bit identities | PASS |
| Verified source-to-bitstream provenance | PASS |
| Generated exact R1h→R1i patch from Git objects | PASS |
| Fetched public evidence repository `origin/main` | PASS |
| Confirmed target directory absent before publication | PASS |
| Created isolated publication branch from current `origin/main` | PASS |
| Added only requested campaign-scoped LFS rules | PASS |
| Rebuilt firmware / ran Vivado / accessed hardware | NO |

The first long local checkout attempt encountered Windows path-length errors in pre-existing historical evidence paths. No repository content was changed by that attempt. A short local worktree with Git long-path support was then created from the same `origin/main` commit. This affected publication logistics only.

## Pre-publication seal

| Gate | Result |
| --- | --- |
| Public text scan for personal path, private DUT identity, credential material, tokens, and private-key markers | PASS |
| Binary ASCII scan for credential/private-key markers | PASS |
| Exact raw/statistical CSV preserved | PASS |
| Exact A1/B1 telemetry preserved except two logged path-only redactions | PASS |
| Requested Git LFS attributes for ZIP/bit/LTX/DCP | PASS |
| R1i/R1h/Formal `.bit` attribute resolves to LFS | PASS |
| Public ZIP attribute resolves to LFS | PASS |
| Independent post-publication provenance-path audit | PASS_WITH_CORRECTION: seven XDC labels corrected to their exact repository-relative `xdc/` paths; hashes and source content were unchanged |

The payload manifest and ZIP were resealed after the independent path-label correction. The ZIP SHA receipt is external to the ZIP to avoid recursive self-hashing. Git commits, pushes, LFS uploads, and remote read-back are recorded in the local publishing report and are independently observable from the published `main` history.
