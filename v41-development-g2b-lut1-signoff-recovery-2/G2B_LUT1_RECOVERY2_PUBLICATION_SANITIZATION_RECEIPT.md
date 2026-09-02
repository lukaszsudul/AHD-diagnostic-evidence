# G2B-LUT1 Recovery 2 Publication Sanitization Receipt

## Scope

- Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`
- Evidence branch: `main`
- Publication directory: `v41-development-g2b-lut1-signoff-recovery-2`
- Scan boundary: this recovery-2 directory only
- Source repository, SSOT, routed DCP, and private runtime roots were not
  rewritten or copied by this receipt.

## Publication boundary

The package contains governed Markdown/JSON/CSV/text evidence, four textual
XDC contexts, raw textual Vivado/supervisor outputs, and Tcl/PowerShell
reproducibility tools. The XDC contexts and tool scripts are retained because
the immediate blocked-signoff predecessor uses this reproducibility policy and
because they establish the exact sign-off method and watchdog behavior.

| Retained raw XDC context | SHA-256 |
|---|---|
| `raw/group13_fresh/G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc` | `2326D6AAEBC40084F295318B30649E370CFB1026AADBDB2C9C85B1BD1B2BB188` |
| `raw/groups14_17/group_14_RELEASE_SLOT_0_AXI_TO_SOURCE/14_RELEASE_SLOT_0_AXI_TO_SOURCE_ISOLATED_CONTEXT.xdc` | `AE98382E8CD9D102C76FD9C3A3DC94F2B4AEBD33B8695591829C9B11E0B5362F` |
| `raw/groups14_17/group_14_RELEASE_SLOT_0_AXI_TO_SOURCE/FULL_PROMOTED_CONTEXT.xdc` | `90920C13870856AC415B8FC2627E71021145D84709AA3D6CAA2FF52B6D75D3D7` |
| `raw/groups14_17/group_14_RELEASE_SLOT_0_AXI_TO_SOURCE/QUERY_BASE_WITHOUT_BUS_SKEW.xdc` | `5B285774E2CBCAD66D6C1A777761EE066D57811C648E8C2A909F8AC4DF29FF3B` |

No product candidate exists, so no `.bit` or `.ltx` is present. The routed
DCP remains external and is represented only by its path, size, device, and
SHA-256 identity; no DCP is published. No RTL/HDL, XCI/IP payload, Vivado
project, simulator database, archive, or generated implementation binary is
included. The execution-created `.Xil` cache tree is excluded before the
package manifest and evidence commit; it is not a published artifact.

## Deterministic checks

| Check | Result |
|---|---:|
| DCP files | 0 |
| Bitstream files | 0 |
| LTX files | 0 |
| XCI files | 0 |
| RTL/HDL source files | 0 |
| Vivado project/database files | 0 |
| Retained textual XDC contexts | 4, hash-bound above |
| Generated `.Xil` cache trees in final publication set | 0 |
| Archives | 0 |
| Reparse points/symlinks | 0 |
| Common credential/token signatures | 0 matches |
| Email-address signatures | 0 matches |
| Private-IP signatures | 0 matches |

The deterministic content scans excluded this receipt itself so its check
descriptions could not create self-matches. `gitleaks` and `trufflehog` were
not installed or invoked, so no claim is made that either tool ran.

## Path provenance

Raw tool outputs intentionally retain machine-local Windows paths and a
Vivado warning that displays the local user-profile strategy path. These
strings are execution provenance, not credentials, tokens, source payloads,
or hardware data. They were not rewritten because doing so would alter direct
tool output and break the package's hash-bound reproduction trail.

## Result

`PUBLICATION_SANITIZATION_GATE = PASS`

The package is eligible for textual evidence publication. Proprietary
implementation binaries remain excluded, and the no-bitstream/no-LTX outcome
is preserved exactly.
