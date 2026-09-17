# W1 minimal unchanged-design simulation receipt

## Source identity and compiled cone

Immutable authority: `lukaszsudul/FPGA_AHD@09cd7cbb426027acaefd0cf3989579b80a451f3a`, tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`. Six task-local design copies in `W1/inputs` were checked by Git blob against the named frozen commit. The three compiled files had identical SHA-256 before and after the run. The wrapper, ACQ executor and top were copied after the run for source inspection and verified against pinned blobs; they were not compiled in this bench.

| Frozen source path | Git blob | SHA-256 of task copy |
|---|---|---|
| `rtl/v41/nvp_i2c_fixed_master.sv` | `738a81ec621a4ff85efda48d14b45ba2b9a4803e` | `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF` |
| `rtl/g2b/g2b_nvp_camera_scan1.sv` | `16182fd9e5362c36ec85b1de974b6c235ec7513a` | `D0F54EDA1542E1A7D57004A90DD9B910956000711F125EF7774484E04D78793A` |
| `rtl/g2b/g2b_nvp_camera_scan1_manifest_pkg.sv` | `318c3979ac5b573baaef3afe6b4d15724a2abdd9` | `F21EE3718F84304DD40D29B0A5FE95BBBA15336D9B7BD642177B950CF7598DD6` |
| `rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv` | `0a9ee1fe4421abc3cc5d7d0a977a1a9ed5b66894` | `4ADD841745733723B6F19AA445E14AAA117E7D291CEE057AA37C115D3ED287BB` |
| `rtl/g2b/g2b_nvp_acq1_compat0_r2.sv` | `e69e1661fa3898bc1d46d5a46b9e94434a202594` | `79792717C8AAB7659692DC8ACD04F2B9C74B1D3FD522179F71CEEA307177E70C` |
| `rtl/top/ahd_capture_top_xdma.sv` | `cbbefea1a75a72fd2ae465649de709d55f740963` | `2467EFBEF793706688AEA1CA33FF23AE1F244AB213EB154E6F83A9FFC41B66A0` |

The three compiled design files were the unmodified master, scanner and manifest package. The full top and ACQ wrapper were inspected as frozen source but not elaborated in this minimal bench. The task-owned `tb_w1_clean_scan.sv` derives from the prior accepted pin-level slave harness and adds only edge/acceptance monitors plus a clean no-stretch mode. Its SHA-256 is `225FDFE4C72A52F30DB05B10174CD7282DE81DA7229C8B44E3BAFE9E13C5112A`. The task-owned checker `extract_w1_gaps.py` SHA-256 is `3BA70C2FBC7AB06C3B2BBC9D0F4F20E6586FD5CBB3CB52D08182DE0900C7620C`.

## Execution

One compile, one elaboration, one clean scan. Simulator: XSim 2025.2, SW build 6299465, 1 ps time resolution. Master runtime assertions verified `CLK_HZ=62,500,000`, `I2C_HZ=25,000`, `DIVIDER=1250`, `SCL_TIMEOUT_CYCLES=1250`, `BUS_IDLE_TIMEOUT_CYCLES=62500`. The task-owned slave used resolved open-drain `tri1` SCL/SDA, valid ACKs, no stretch and no other client. It decoded each wire byte, represented the normal final read NACK and produced no hardware access. The scan ended with `W1_CLEAN_PASS gen=1 valid=82 tx=105 accepted=105 stretch=0`; the entry bank was restored and verified as `00`, with no scanner first error. Elaboration and simulation completed without fatal/error messages. No implementation build was run.

The pin monitor recorded command acceptance and every resolved START/STOP at 1 ps simulation resolution. The checker required each of 105 commands to have exactly one initial START and one STOP and each of 94 reads to have exactly one *internal repeated* START. It compared every one of 104 adjacent STOP→next initial START gaps to the independently derived 3,755-cycle equation. All were exactly `60,080.000 ns = 60.080 µs`. The public CSV keeps the 10 select→verify, 10 verify→first-entry and 1 restore→verify boundaries. Same-bank group reselections were groups 1, 2 and 3. The group 0 write also selected bank `00` after a saved entry bank of `00`, but the scanner's prior-group-valid condition is false there.

The checker was challenged with two task-local trace corruptions, without rerunning the design. Moving the first select STOP by +16 ns was rejected for source/model gap disagreement. Substituting the verify read's internal repeated START as the next transaction was rejected because the edge is marked repeated. The exact proof text is `W1_CHECKER_PROOF.txt`.

## Scope and hashes of resulting evidence

| File | SHA-256 |
|---|---|
| `W1/simulation/xvlog.log` | `A0EF14BA6B867AAEBEA7170FE0F44628C52DFA2075710D553696E61EDE5B6298` |
| `W1/simulation/xelab.log` | `7093E366B422169183C4C9C7AE9144328FF55143041D4CAD18072A4743515F7E` |
| `W1/simulation/xsim.log` | `08D979680922183F075F94DCE70393CEF1BA98AE373FA14080E8B15BAE5A32A6` |
| `W1/reports/W1_TRANSACTION_GAPS.csv` | `9DB758A6F4FA264DEC93ECCDFBD5C5AC74202665003A0124337196FD6D642B14` |
| `W1/reports/W1_CHECKER_PROOF.txt` | `FE1B0674714B6517D912A1BA611AD4196F9206B2B8678F2569E53EFB05092A66` |
| `W1/reports/W1_PUBLIC_PROOF_LOG.txt` | `F0E26B29F7E4904202976C19A505007998D2ABBF9B481E938F6309864E27905B` |

Model limits: no analog rise time, metastability, electrical board behavior, actual slave stretch, concurrent ACQ client, or unrelated bus master. The wrapper's scanner ownership/grant is combinational in the frozen source; this direct master/scanner run models its no-contention outcome but does not simulate a competing client. No DUT contact, driver load, firmware action, RTL edit, table edit or new hardware scan occurred.
