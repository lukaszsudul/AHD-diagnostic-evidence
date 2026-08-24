# Exact local R1e base identity

## Gate result

`EXACT_LOCAL_R1E_SOURCE=PASS_AVAILABLE_AND_CLEAN`

| Item | Verified value |
|---|---|
| Repository | `lukaszsudul/FPGA_AHD` |
| Exact local worktree | `C:\FPGA\WORKTREES\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1` |
| Branch | `diag/v41-nvp-i2c-25khz-r1e-observability` |
| `HEAD` / required base commit | `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd` |
| Commit tree / required base tree | `db8b5581a237e19905fd01c6d453793047bc3ba7` |
| Parent | `f007dc172d43d30b02729755e60382f8ce3dbff4` |
| Commit subject | `v41 diag: add R1e NVP observability` |
| Worktree status | clean; zero staged, unstaged, or untracked porcelain records |

No checkout, branch creation, source edit, commit, fetch, or other repository mutation was performed by this audit.

## Audited source objects

| Exact path | Git blob | Bytes | SHA-256 |
|---|---|---:|---|
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `cfe33464d8e75c514462786593b278d90b4059a4` | 54013 | `027D0D2258E5FF80A2675198EA9CD7085E2FD360B0EBCE9C423D631656DF9080` |
| `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` | `7ddd60fc86da49cda1adcd7af7b772b337c95df6` | 36196 | `36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156` |
| `rtl/nvp/nvp6134c_autoinit.vhd` | `5dc0230cd569f03d68452055db6b10c5fcade751` | 9964 | `74EFDC0147ADEA9A13265C061ECD3BA0B8042A2357B0A0E10673112F9986C17F` |

Byte-preserved copies are under `02_CURRENT_SEMANTICS_AUDIT/raw_r1e_source/`. Their hashes match the clean exact-base worktree.

```text
BASE_COMMIT=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
BASE_TREE=db8b5581a237e19905fd01c6d453793047bc3ba7
BASE_IDENTITY_GATE=PASS
SOURCE_MUTATIONS_BY_THIS_AUDIT=0
```

