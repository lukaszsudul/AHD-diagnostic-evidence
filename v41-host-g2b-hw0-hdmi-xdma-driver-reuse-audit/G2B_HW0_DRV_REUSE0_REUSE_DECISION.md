# G2B-HW0-DRV-REUSE0 Reuse Decision

## Exact decision

`HDMI_DRIVER_REUSE_DECISION = NOT_REUSABLE_PCI_ALIAS_MISMATCH`

## Decision basis

The governed HDMI identity is unambiguous and historically hash-bound to SHA-256 `B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2`. Its sole PCI table entry is:

`PCI_DEVICE_SUB(0x10ee, 0x7021, 0x10ee, 0xf0a1)`

That produces the sole alias:

`pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*`

The fresh AHD endpoint modalias is:

`pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00`

Both the device (`7021` versus `7011`) and subsystem device (`f0a1` versus `0007`) differ. The exact binary cannot correctly discover the AHD endpoint through its built match table. A forced bind or `driver_override` write would not satisfy the acceptance criterion and was not authorized or attempted.

The source audit also establishes that the payload path is `GENERIC_TRANSPORT_ONLY`; all functional transport code remains upstream. The incompatibility is the deliberate HDMI-specific PCI match customization, not an HDMI frame parser in the kernel. Core XDMA transport characteristics are broadly aligned, with documented BAR/policy and incomplete MSI-setting constraints, but that cannot override the built alias.

## Gate separation

- Engineering gate: `BLOCKED`.
- Evidence publication: `PASS`, completed by external commit-pinned byte verification after push.
- Overall result: `BLOCKED`.
- First blocker: `BLOCKED — HDMI_DRIVER_DUT_ARTIFACT_NOT_FOUND`.

Artifact absence prevents the fresh SHA-256/SHA-512, stat, ELF, signature, dependency, and actual built-alias inspection required for Engineering PASS. It does not erase the independently conclusive, hash-linked historical alias mismatch, so the most specific reuse enum remains `NOT_REUSABLE_PCI_ALIAS_MISMATCH`, not an incomplete-provenance enum.

## Recommendation

Obtain separate owner authorization for a new AHD-compatible XDMA driver build task targeting kernel `7.0.0-29-generic` and the AHD `10ee:7011 / 10ee:0007` PCI policy. Do not execute that fallback under REUSE0.

No driver was built, installed, loaded, bound, or altered in this audit.
