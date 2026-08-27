# Sanitized Qualification Evidence Index

Original file SHA-256: `73A82AC7D0B479701FE3A6AF26302291378B033AEDAAA8700C35E450D7F5880B`  
Publication status: regenerated public index; private paths and operational access details omitted.

## Authoritative internal inputs

| Evidence | Original SHA-256 | Publication disposition |
| --- | --- | --- |
| Qualification report | `2F5D3DBE79E67A49D5DD5EA6816C4DAA39604F781C0A40D9F17C333475069307` | Sanitized narrative copy under `final/` |
| State JSON | `333C9EA53E1F37509DFDD8146F5B84654B0F447F0624AEE53DD1303E0F9BF85E` | Sanitized machine-readable copy under `final/` |
| Raw campaign CSV | `EFEFAE9BFC480B533E4244A121D59D0B0C6472ED9D2C08E3FFF1DACD7ECEC578` | Byte-for-byte under `raw/` |
| Statistical CSV | `4BE0CAB408E093B3B33F65F03285738AB8C9A4AEDD7F874B7504CCC7A2D33AAE` | Byte-for-byte under `raw/` |
| Hardware transcript | `0BF3851C89D1853728C2FCE0EFE4D61F13786CFB0DDAC55878BB31FBAC343279` | Curated public transcript under `hardware/` |
| Internal evidence index | `73A82AC7D0B479701FE3A6AF26302291378B033AEDAAA8700C35E450D7F5880B` | Replaced by this public index and the detailed index |
| Internal SHA manifest | `4A892793A520C3966B8C99C1D35D6E1A07E46C99591DAFD5E375EF584288A4C7` | Curated provenance receipt plus new public manifest |
| Original internal ZIP | `6341F934D17F790E113C1C3013D9DD78E7387C6AA22469ABA7EB88D10C90519F` | Not published; public sanitized ZIP generated separately |

## Public evidence groups

- `final/`: conclusions, protocol, measurements, source provenance/delta, limits, redaction record, and sanitized qualification documents.
- `raw/`: byte-for-byte raw/statistical CSV plus A1/B1 decoded and raw MMIO telemetry JSON that passed the public-safety scan.
- `hardware/`: curated programming, independent-DONE, runtime/sample, and restoration receipts without private access details.
- `implementation/`: exact R1i, R1h, and Formal bitstreams in Git LFS, plus the build and identity reports. No LTX existed or was required.
- `scripts/`: offline public-manifest verifier only; no access, credential, JTAG, or hardware-control scripts are published.

Every public file's size and SHA-256 is in the root `SHA256_MANIFEST.txt`.
