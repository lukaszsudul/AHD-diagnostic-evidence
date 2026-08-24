# R1f Safe Idempotent Data-Probe Target Gate

## Decision

```text
SAFE_DATA_PROBE_TARGET=PASS
R1F_PROBE_BANK=0x00
R1F_PROBE_REGISTER=0x85
R1F_PROBE_DATA=0x00
DATA_PROBE_SIDE_EFFECT_CLASS=IDEMPOTENT_SAME_VALUE_WRITE_WITH_PRE_POST_READBACK
TARGET_REGISTER_NAME=SPL_MD_CH1
TARGET_PROFILE=AHD_1080_25
```

The accepted target is Bank 0 register `0x85`, data `0x00`.  It is the
documented channel-1 `SPL_MD` input-format field, not a bank selector, reset,
power, clock/PLL, video-output enable/mux, clear/pulse, W1C/W1S, interrupt,
calibration, reserved, or undocumented register.

Acceptance is conditional on the exact setup/readback/restore contract in
`PROBE_SETUP_AND_RESTORE_CONTRACT.md`.  A pre-read other than `0x00`, any
transport error, a post-read other than `0x00`, or failure to restore and verify
the entry bank aborts the active probe and invalidates every probe-rate
inference.

## Authoritative input identities

| Input | Exact identity |
|---|---|
| Exact R1e source | commit `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd`; tree `db8b5581a237e19905fd01c6d453793047bc3ba7` |
| `rtl/nvp/nvp6134c_autoinit.vhd` | SHA-256 `74EFDC0147ADEA9A13265C061ECD3BA0B8042A2357B0A0E10673112F9986C17F` |
| `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` | SHA-256 `36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156` |
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | SHA-256 `027D0D2258E5FF80A2675198EA9CD7085E2FD360B0EBCE9C423D631656DF9080` |
| Accepted Z0 datasheet audit | SHA-256 `944AC392E1F7BBB30F8C8029D3BFC63EF4CA674F0B7CDC97FB0D515E15845ABC` |
| NVP6134C Rev 1.0 datasheet | 93 pages; SHA-256 `301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46` |
| Programmer-audit package containing the authoritative datasheet | SHA-256 `AEA396735E97AB43F7AD284BDE8A7F294B9E3F5826223E0C9BD89D358E750FC4` |

The preserved task-local datasheet copy is
`AUTHORITATIVE_REFERENCES/NVP6134C_Rev1_0.pdf` and hashes exactly as above.
Rendered visual checks of the two controlling pages are preserved as
`AUTHORITATIVE_REFERENCES/NVP6134C_PAGE_12.png` and
`AUTHORITATIVE_REFERENCES/NVP6134C_PAGE_41.png`.

The detailed p.41 address table jumps from `0x84` to `0x8E`; this audit does
not silently fill that gap.  Documentation for `0x85` comes directly from
p.12 Table 2.1, which explicitly identifies the Bank-0 `0x85~0x89[3:0]`
`SPL_MD` register setting, plus the exact R1e source's named `SP_MD CH1`
write.  The target is therefore documented even though it is omitted from the
later summary table.

## Criterion-by-criterion proof

| Required criterion | Evidence | Result |
|---|---|---|
| Normal volatile read/write configuration register | Datasheet p.12, Table 2.1 calls `SPL_MD` at Bank 0 `0x85~0x89[3:0]` a video-format **Register Setting Value**.  Configuration tables use fixed reset/mode values, while status-only locations are separately marked `R` (for example p.42).  Generic register write/read protocol is specified on p.36. | PASS |
| Not bank select `0xFF` | Address is `0x85`; exact R1e defines bank select separately as `0xFF` (`nvp6134c_diagnostics_pkg.vhd:51`). | PASS |
| Not reset, power, clock/PLL, output enable/mux, clear/pulse, W1C/W1S, interrupt clear, calibration, reserved, or undocumented | Datasheet p.12 identifies this field only as input-format `SPL_MD`.  The prohibited output-enable and clock controls are separately documented at Bank 1 `0xCA` and `0xCD/0xCE` (pp.16-17).  It is not labeled reserved. | PASS |
| Exact intended post-autoinit value known | Exact R1e fixes profile `AHD 1080p25`, `auto_enable='0'`, and stage 2 in `nvp6134c_autoinit.vhd:183-189`. Datasheet p.12 gives `SPL_MD=0x0` for AHD 1080p25. | PASS |
| Source-proven same-value idempotence | Exact R1e stage-2 table deliberately emits `x"008500"` at Marek slot 96 (`nvp6134c_diagnostics_pkg.vhd:329`) and again at overlay slot 15 / absolute slot 163 (`:408`).  `c_v38ek_init_op_for_slot` executes the Marek table for slots below 148 and then the overlay (`:491-511`); both slots are in the frozen sequence. `ENABLE_MAREK_INIT_TABLE` is `1` at the exact top (`rtl/top/ahd_capture_top_xdma.sv:16`), and the provenance build does not override it (`scripts/v41/r1e_build.tcl:76-83`). Thus the accepted implementation itself repeats the exact Bank/Reg/Data triplet without a change or pulse-release counterpart. | PASS |
| Pre-probe readback can verify expected value | Datasheet p.36 defines the I2C register-read protocol.  Exact R1e already implements arbitrary register read transactions and verified bank-selection readback in `nvp6134c_i2c_bringup.vhd`.  The R1f contract requires Bank 0 verification followed by an exact `0x85==0x00` pre-read. | PASS |
| Post-probe readback can verify no value change | Same read path is required immediately after the last data probe; any value other than `0x00` aborts and invalidates the sample. | PASS |
| Original bank can be restored and verified | Exact R1e already preserves/restores the entry bank and verifies bank selections.  R1f independently preserves the post-autoinit entry bank, restores it after the probe, reads `0xFF`, and requires equality before declaring probe completion. | PASS |

## Why the repeated write is not a pulse sequence

The two exact R1e writes are identical (`00/85/00`) and have no complementary
assert/release values.  This differs from the explicitly commented clean-pulse
sequence at Bank 3 register `0x3A`, where the source writes `0x01`, waits, then
writes `0x00` (`nvp6134c_diagnostics_pkg.vhd:236-238` and `:367-369`).  The
accepted target therefore has static mode-setting semantics in both the
datasheet and exact source.

## Conservative limits

- The target proves electrical and state safety only under the pre/post
  readback and bank-restoration gates.  It does not make the whole tri-phase
  probe passive.
- The data probe remains an active same-value configuration write.
- Register-address probing may set the device's register pointer; the data
  probe may execute only after the safe Bank-0 context is verified.
- No result may be accepted if the target value is not already `0x00` before
  probing.
