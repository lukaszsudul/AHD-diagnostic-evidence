# C3-PNR1 input provenance and recipe delta

- Task: `CONT1R3R4R6-W3A-C3-PNR1`; execution root: `C:\FPGA\W3A_C3_PNR1_20260917T221245Z`.
- Source: detached clean worktree at `input/source`, commit `70266f0b90c6fc6a853495eba1d526b285fd7286`, tree `5f2bd8377985406b45433418b20be8993399bcb6`; no source edits or new source revision.
- Frozen C3 manifest: `authority/W3A_CANDIDATE3_SOURCE_BUILD_MANIFEST.json`, 40/40 build inputs verified by exact byte length and SHA-256; manifest SHA-256 `2CA4660A9AE81099E230E573D6A40EC28BE411A9F867A00A87B04F1F7677D4F8`.
- C3 host contract: `input/source/host/w3a/resources/W3A_CONTRACT.json`, 2930 bytes, SHA-256 `7F2A9647EF60D360B9884E57F6FAE16BCAFC4DD8F60D592CE0A44D728FA67D39`.
- Historical recipe: `authority/w3a_candidate3_full_implementation.original.tcl`, 8693 bytes, SHA-256 `2CAD285DD5D0F69F29B96FA9157C9A6CD0E4E4FC168AB3D12E7BDC699A736167`.
- Frozen task-local wrapper: `build/c3_pnr1_implementation.tcl`, 9261 bytes, SHA-256 `7A3B5F0799CC1228A0ADDA31DAF8F35E07D15021CA0CF0DE5E2B02C964C90A01`.
- Tool/target: Vivado 2025.2 SW Build 6299465, `xc7a35tcsg325-2`, top `ahd_capture_top_xdma`; generics and XDC file order unchanged from the C3 recipe.
- Current-state at entry: project revision 9, `project-current-state` last-change commit `f8429a81e22a2f887afd06b334889c30aed7a293`; 18/18 SSOT manifest hashes verified. No SSOT write is authorized.
- Historical C1/C2/C3/C4 ledger: FAIL at synth width / post-opt 23774 / post-opt 20456 / post-opt 20540, respectively. C3-PNR1 not present locally or on evidence `main` at `a046cec8ded4dac4c523df93db5f716c2f2affdf`; no active Vivado worker at entry.

## Task-local recipe delta, frozen before tool invocation

1. Redirect `source_root` to the detached C3 worktree and `run_root` to the new task directory. Replace the historical branch-name check with exact commit/tree/clean checks appropriate to detached HEAD.
2. Add unqualified stage checkpoints after synth, opt, place, phys-opt, and route, plus post-phys-opt and routed resource reports. These preserve results without changing netlist inputs or tool strategy.
3. Replace the historical `POST_OPT_LUT_GATE_FAILED` for 20,385–20,456 with `OWNER_EXCEPTION_C3_POST_OPT`; retain hard stop above 20,456 and the original final routed 20,384 hard limit.
4. No `synth_design`, `opt_design`, `place_design`, `phys_opt_design`, `route_design` directives, generics, XDC files/order, IP configuration, RTL, or tool version changed. No simulation or hardware actions are in the wrapper.

Starting checkpoint: `NONE`; no full post-opt or post-synth C3 DCP exists in the historical build tree. Thus exactly one conditional recreation of the same C3 synth/opt is permitted before the one place/route attempt. Historical reports are not substituted for fresh results.
