# G2B-G15-17-EQ-R1 Worktree Inventory

Inventory command: `git worktree list --porcelain`, run read-only from `C:\FPGA\FPGA_AHD` on 2026-09-04.

| Absolute path | Branch | HEAD | Tree | Parent | Lock | Prunable | Tracked status | Index status | Untracked count |
|---|---|---|---|---|---|---|---|---|---:|
| `C:\FPGA\FPGA_AHD` | `main` | `be94f88ee8d179f12928ab791bdae27c22cd1762` | `e128ff47a5e21e8131971f5e5caa7657e2eccc7f` | none (root commit) | UNLOCKED | NO | CLEAN | CLEAN | 47 |
| `C:\FPGA\R1I_RCA` | `research/v41-r1i-causal-isolation` | `20c3323d79d3896edc586d6db1df7deee60f9e41` | `70d801fd7a879080da399bfa9ee95fd6eb008e16` | `94fa9e77ae58b791ebd884f767a26063fcf38e0a` | UNLOCKED | NO | CLEAN | CLEAN | 0 |
| `C:\FPGA\R1I_RCA_A_SRC` | `research/v41-r1i-a` | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` | `a0fcbdbfb2b01049b357a8f8bf68bd448d6394f7` | `20c3323d79d3896edc586d6db1df7deee60f9e41` | UNLOCKED | NO | CLEAN | CLEAN | 0 |
| `C:\FPGA\R1I_RCA_B_SRC` | `research/v41-r1i-b` | `e4d10bb8e85e3797d078144fd0965e9625ee727c` | `2658cf45e36c3dab81005117056b1f8e6cf3ddc1` | `20c3323d79d3896edc586d6db1df7deee60f9e41` | UNLOCKED | NO | CLEAN | CLEAN | 0 |
| `C:\FPGA\V41_G2A` | `integration/v41-r1i-gen2-g2a` | `224d194e5f82c85bcb29297561c5d5e76d28063b` | `283f98c02e6f9c61716875415cf000682f8ab856` | `20c3323d79d3896edc586d6db1df7deee60f9e41` | UNLOCKED | NO | CLEAN | CLEAN | 0 |
| `C:\FPGA\V41_G2B` | `integration/v41-g2b-onech-c2h` | `bdae16e06fb5b8564763941f530e4ce9e28896c7` | `e18833d46f7672f851c3cb8239f2f29091378294` | `64feb60de5d07f400e6b92527bfe54838b3372ee` | UNLOCKED | NO | CLEAN | CLEAN | 0 |

Exactly one record matches the required branch, HEAD, and tree. Therefore:

`AUTHORITATIVE_SOURCE_WORKTREE = C:\FPGA\V41_G2B`

The protected primary worktree matched its required `main` identity and was not modified. Its 47 pre-existing untracked files were preserved.
