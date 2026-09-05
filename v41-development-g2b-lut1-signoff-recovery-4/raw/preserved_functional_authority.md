# AHD v41 G2B-LUT1 Functional Protection

## Result and source identity

- `FUNCTIONAL_PROTECTION_GATE = PASS`
- Basis: `FRESH_STATIC_PLUS_EXACT_HASH_BOUND_PRIOR_REGRESSIONS`
- Source branch: `integration/v41-g2b-onech-c2h`
- Source commit: `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49`
- Source tree: `1e67e3f1fe06669839fe9ff8573e4d1e0114a889`
- Worktree/index after checks: clean
- `HARDWARE_ACCESSED = NO`

The checks protect the accepted G2B one-channel C2H implementation, four-slot ring, record formatting, backpressure behavior, sequence semantics, reset epoch, host parser, transport ABI, MMIO window, PRODUCT profile, and qualified R1i behavior. No R-track diagnostic behavior was reopened and no PCIe generation/link setting was changed.

## Frozen interface protection

| Item | Governed value | Result |
|---|---|---|
| Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1` | unchanged |
| ABI version | `1` | unchanged |
| MMIO range | `0x3800..0x3BFF` | unchanged |
| ABI golden reconstruction | 8/8 records; 32,768/32,768 bytes; zero mismatches | PASS |
| Stream structure | 16/16 records; zero padding failures | PASS |
| Reconstructed stream SHA-256 | `BF41EE32E9D1855C86DC2BCAEFD151AFCD83AEAC37900C4D5AD145B29EA2C948` | recorded |
| MMIO exhaustive regression | 131,072 addresses | PASS, hash-bound |

The MMIO result is bound to the exact source/test identities recorded by `C:\FPGA\G2B_LUT1_MMIO_ROUTER_XSIM_20260831_13\G2B_ROUTER_XSIM_RECEIPT.txt`, SHA-256 `EC9F1DBC71C7A532B0D8794657D0F3062D87A8B3A47D47500DE58DDB8D961623`.

## Host parser and R1i regression provenance

The sealed Python regression receipt reports 27/27 tests PASS: 11 G2B host ABI/parser tests and 16 R1i tool tests.

- Receipt: `C:\FPGA\G2B_LUT1_PYTHON_20260831_13\G2B_PYTHON_REGRESSION_RECEIPT.txt`
- Receipt SHA-256: `E964C39C036071E10EAF7A57330F1CF74A5D302948C69F19B67D5C3BD6640CD3`
- Unit-test log SHA-256: `47DDA642C6DA4D5115BE880E2FA9EFF7C5EA68BC391A52030214EC016E6FA474`

The six current Python inputs exactly match the sealed receipt:

| Repository-relative file | SHA-256 |
|---|---|
| `host/tools/g2b/__init__.py` | `0701AEAF6A8E0A5FF3EF9D954B7EAE81A423957EDED88428F97AB81EA1AC5135` |
| `host/tools/g2b/abi_v1.py` | `2939FC522A2D9679BB720F287AC022FC48FF042CE06E20877F8E686F35909F1E` |
| `host/tools/g2b/g2b_offline.py` | `C35E5616F61724D342C451220829742A4B7F6D4D7E5C438A3F1C8767E5E9B04C` |
| `scripts/v41/read_nvp_r1i.py` | `9EF4035BBE161D6D523F54951E5630D00B4550CD00332A47EE5F0C1BE45C2172` |
| `tests/python/test_g2b_host_tools.py` | `5479DB87055C8B91A05401A7BC56E62EFED57333F070FB54AEAA7E8F984F67A0` |
| `tests/python/test_nvp_r1i_tools.py` | `4F921D40441420B171583FD4E9506DCFEB78437801A6B043729C41A6E647B2AA` |

### Fresh Python limitation

A fresh Python invocation returned Windows exit code `9009` because no Python interpreter is installed in this environment. Consequently, the 27 Python tests were not freshly re-executed in this recovery run. This is an explicit, nonblocking, exact-hash-bound limitation: all six current source/test files exactly match the sealed PASS receipt, and a fresh independent in-memory ABI/stream audit reconstructed 8/8 records exactly, matched all 32,768 bytes, and passed all 16/16 structural records with zero padding failures. The result is not represented as a fresh Python run.

## R1i protection

The focused candidate/reference traces are byte-identical, preserving the qualified R1i behavior, required NVP initialization behavior, and required production observability:

- Candidate: `C:\FPGA\G2B_LUT1_R1I_20260831_13\wire_focused\r1i_candidate_allack.trace`
- Reference: `C:\FPGA\G2B_LUT1_R1I_20260831_13\wire_focused\r1h_reference_allack.trace`
- Size: `5,346 bytes` each
- SHA-256 of each: `7C5D7F767B2E9CAEB1B587D3F258C295AD0F454141B2A8C84240B966133A4B49`
- Byte mismatches: `0`
- `R1I_PROTECTED_BEHAVIOR = PASS`

## PRODUCT profile and XDMA configuration

- PRODUCT compatibility receipt: `C:\FPGA\G2B_LUT1_PRODUCT_PROFILE_XSIM_20260831_13\G2B_PRODUCT_PROFILE_XSIM_RECEIPT.txt`
- Receipt SHA-256: `62318E4DB49DE3F47060D9B1B4594B64894586BFC08C5D3D0FAD0CB4E46713B3`
- `PRODUCT_PROFILE_GATE = PASS_HASH_BOUND`
- XDMA XCI SHA-256: `9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F`
- XDMA configuration: Gen2 `5.0 GT/s`, x1, 64-bit AXI Stream, configured `62.5 MHz`, one C2H; mandatory H2C permanently backpressured
- `XDMA_CONFIG_PRESERVED = PASS`
- `XDMA_XCI_UNCHANGED = YES`

The build-input comparison found 34/35 inputs exact, zero missing, and zero unexpected mismatches. The sole changed input is the authorized Group-9 constraint promotion:

| File | Sealed SHA-256 | Current SHA-256 | Disposition |
|---|---|---|---|
| `xdc/common/g2b_cdc.xdc` | `2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF` | `6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227` | authorized META-4 Group-9-only change |

## Final disposition

`ABI_MMIO_UNCHANGED = YES`, `R1I_PROTECTED_BEHAVIOR = PASS`, `PRODUCT_PROFILE = PASS`, and `XDMA_CONFIG_PRESERVED = PASS`. Offline throughput is separately `PASS` at a `468.750 MB/s` ideal useful ceiling versus `288 MB/s` required, while `HARDWARE_THROUGHPUT_PROVEN = NO`.

No hardware was accessed and no hardware qualification is claimed.
