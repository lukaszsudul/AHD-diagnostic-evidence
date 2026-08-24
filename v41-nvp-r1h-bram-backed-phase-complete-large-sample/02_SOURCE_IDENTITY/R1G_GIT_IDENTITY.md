# Exact R1g Git identity and compatibility-delta proof

Verification was read-only against:

```text
SOURCE_REPOSITORY=C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY
SOURCE_REMOTE=https://github.com/lukaszsudul/FPGA_AHD
CHECKED_OUT_BRANCH=diag/v41-nvp-r1g-vhdl-compatibility
```

## Exact topology

```text
R1G_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1G_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
R1G_DIRECT_PARENT=225544084dbfcaadb8592fcecc947aa1cec4970e

R1F_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1F_TREE=cfde8769af95cf20586391c411fab3ddfa2c87b6
R1F_DIRECT_PARENT=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1E_COMMIT=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
R1E_TREE=db8b5581a237e19905fd01c6d453793047bc3ba7

R1G_HEAD_MATCH=PASS
R1G_DIRECT_CHILD_OF_R1F=PASS
R1F_DIRECT_CHILD_OF_R1E=PASS
WORKTREE_STATUS_PORCELAIN_ENTRIES=0
WORKTREE_CLEAN=YES
```

## R1f to R1g delta

`git diff --name-status` reports exactly one modified path:
`rtl/nvp/nvp6134c_i2c_bringup.vhd`. `git diff --numstat` reports `5` added and
`1` deleted line. The sole behavioral text replacement is:

```vhdl
-- R1f
r1f_tx_wdata_r <= write_data when is_read_op = '0' else x"00";

-- R1g
if is_read_op = '0' then
  r1f_tx_wdata_r <= write_data;
else
  r1f_tx_wdata_r <= x"00";
end if;
```

No process, condition, target, width, branch value or assignment timing changed.

## Existing compatibility/equivalence/elaboration gates

| Evidence | SHA-256 | Exact result |
|---|---|---|
| production-mode compiler iteration receipt | `D8D759885CB4694C3198987A9A8CC560AC24EF57579B9E81EED2C0DD07544602` | `PASS_ALL_FILES`; unresolved VHDL-2008 constructs `0` |
| cross-standard equivalence gate | `AD1B793125EAD205CB9681828452736154DADBBEA26166C7ECFF245EB87991D5` | reference PASS, candidate PASS, cycle equality PASS, semantic differences `0` |
| cross-standard result table | `F1E24B07A904522B7156A939FBB9F44EAC16AC75F9ED0EEC417205B2D3AC5BE5` | every recorded comparison PASS |
| final RTL-elaboration result | `CB8A6C9DE7CC8841038EFE73109B08BBC00057C9C8D0ECA7FA444B9504F61DED` | PASS; `SYNTH_8_2757_COUNT=0`; exit `0` |

These are existing R1g results; no compiler, simulation, elaboration or Vivado
run was launched during this R1h P0 verification.

```text
P0_SOURCE_IDENTITY_GATE=PASS
SOURCE_MUTATIONS=0
COMMITS=0
```
