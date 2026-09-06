# G2B-HW0-DRV1 ELF and Static Module Report

## Candidate identity

| Field | Value |
|---|---|
| Inspection mode | STATIC_OFFLINE_ONLY |
| Filename | xdma_ahd_pcie.ko |
| Internal module name | xdma_ahd_pcie |
| SHA-256 | E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77 |
| Size | 3296104 bytes |
| Architecture | x86_64 |
| Module version | 2025.2.0 |
| Srcversion | EE8B149D1883AE8C6B1EE31 |
| License | Dual BSD/GPL |
| Description | Xilinx XDMA Reference Driver (AHD exact PCI match) |
| Author | Xilinx, Inc. |
| Dependencies | none |
| Generated aliases | 1 |
| Build ID | 1471c3a284ec1cb26115fe9e9bd59890a034f83e |
| Signature | absent |
| Signature disposition | UNSIGNED_ACCEPTABLE_FOR_SEPARATELY_AUTHORIZED_TEST |

Exact vermagic:

    7.0.0-29-generic SMP preempt mod_unload modversions 

The trailing space above is part of the modinfo rendering. Its semantic tokens
exactly match the running kernel module contract.

## ELF header

| Field | Value |
|---|---|
| File classification | ELF 64-bit LSB relocatable, x86-64, with debug_info, not stripped |
| ELF class | ELF64 |
| Data encoding | 2's complement, little endian |
| ELF version | 1 (current) |
| OS/ABI | UNIX - System V |
| ABI version | 0 |
| Type | REL (Relocatable file) |
| Machine | Advanced Micro Devices X86-64 |
| Entry point | 0x0 |
| Program headers | 0 |
| Section-header offset | 3291752 bytes (0x323a68) |
| Section count | 68 |
| Section-header string-table index | 67 |

## Relevant sections

| Index | Section | Purpose observed in the candidate |
|---:|---|---|
| 9 | .text | executable module code |
| 11 | .bss | zero-initialized writable data |
| 12 | .data | initialized writable data |
| 14 | .rodata | read-only data |
| 19 | .debug_info | DWARF debug information |
| 40 | .modinfo | module metadata, vermagic, alias, parameters |
| 41 | __param | six module parameters |
| 58 | .note.gnu.build-id | SHA-1 build ID note |
| 59 | __version_ext_names | extended modversion names |
| 60 | __version_ext_crcs | extended modversion CRCs |
| 61 | __versions | kernel symbol-version records |
| 62 | .gnu.linkonce.this_module | generated module identity structure |
| 64 | .note.Linux | Linux module notes |
| 65 | .symtab | ELF symbol table |
| 66 | .strtab | ELF string table |

No .BTF section is present. This agrees with the build diagnostic that BTF
generation was skipped because the matching headers directory did not contain
vmlinux.

## GNU and Linux notes

- GNU build ID: 1471c3a284ec1cb26115fe9e9bd59890a034f83e.
- .note.Linux contains func and OPEN notes as recorded by readelf.

## Module metadata

Generated alias:

    pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*

Parameters:

| Parameter | Type | Upstream meaning |
|---|---|---|
| h2c_timeout | uint | H2C SGDMA timeout in seconds |
| c2h_timeout | uint | C2H SGDMA timeout in seconds |
| poll_mode | uint | polling versus interrupt mode |
| interrupt_mode | uint | auto, MSI, legacy, or MSI-X selection |
| enable_st_c2h_credit | uint | streaming C2H credit control |
| desc_blen_max | uint | maximum per-descriptor buffer length |

No module parameter was changed for DRV1.

## Symbol and modversion qualification

| Field | Value |
|---|---|
| CONFIG_MODVERSIONS | y |
| Module.symvers SHA-256 | 88EC24BC876CCE4C2D7947424F964E5B2A76011801288209BD96539647BEE4BA |
| Module.symvers size | 2382007 bytes |
| Module.symvers lines | 32698 |
| Undefined kernel-symbol references | 134 |
| Defined global ELF symbols | 89 |
| modpost result | PASS |
| Out-of-tree dependency | none identified |

The 134 undefined ELF symbols are normal kernel imports in a relocatable module;
modpost completed without an unresolved-symbol error against the exact running
kernel Module.symvers. The module contains __versions and the extended
name/CRC sections required by this kernel's modversion scheme.

## Compatibility classification

The ELF machine, module name, exact vermagic, modversion sections, modpost
result, and dependency inventory pass. The compiler executable-name diagnostic,
pahole-version diagnostic, and skipped BTF generation remain inventoried.

KERNEL_OFFLINE_COMPATIBILITY = PASS_WITH_NONBLOCKING_WARNING

This is not runtime-load or DMA proof.

