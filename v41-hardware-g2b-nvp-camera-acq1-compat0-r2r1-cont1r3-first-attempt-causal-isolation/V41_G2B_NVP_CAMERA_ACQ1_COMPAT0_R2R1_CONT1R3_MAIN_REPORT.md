# AHD v41 CONT1R3 — first-attempt NACK telemetry and causal-isolation attempt

**Engineering gate: FAIL.** The fresh diagnostic candidate stopped at the post-opt LUT headroom gate: **21,446/20,800 LUT (103.106%)**, above both device capacity and the inherited ≤20,384 diagnostic hard limit. The recorded first failure is `LUT_USED_GT_20384`. No place, route, signed-off DCP, bitstream, DUT contact or 1,000-scan campaign occurred. This is an instrumentation resource failure, not a measured NACK-causality result.

## Authority and completed work

- Same SCAN0/SCAN1/ACQ1 Codex window; project state revision 8 remains Owner-attested, not independently reverified.
- Frozen parent `dae2aff60141ecdbc0afac08fc0df9a3166f66c6` / tree `21e33d481ef637667756caa8015e7fa1b1dd8ebf`.
- Isolated diagnostic branch `diag/v41-g2b-nvp-camera-cont1r3-first-attempt-20260916T064015Z`; new source commit `dc73d486bf0d68e52dc394dd731031e8598212f5` / tree `f86fcbc15f9a279ae81e689b49c5a7e9ade87602`, published privately without PRODUCT merge.
- Preregistration frozen first, SHA-256 `18CDD7FBC67ABDB799475CE509BC686C3A2CD0E7153BC4E44910ABC809B5DF8C`. Audited ten actual execution groups and the 82-entry, 105-clean-transaction scanner.
- Existing master, manifest, ACQ executor, XDC and immutable projection were unchanged. Versioned read-only sideband retains first raw/decoded failure cause, retry result, all-entry exposure timestamps and group context. Event capacity: 82 per scan.
- Inherited SCAN1 24/24, ACQ integration 20/20, new observability 32/32, directed RTL 6/6. Parent/candidate co-simulation matched 2,862 cycles and 547 accepted I2C commands. This proves simulated logical behavior for the exercised stimuli, not routed electrical equivalence.
- Fresh Vivado 2025.2 synthesis passed with zero errors and zero critical warnings. Exact post-synthesis profile was SCAN1=1, wrapper=1, executor=1, prohibited paths=0. Post-opt optimization passed but resource qualification failed.

## Resource decision

The accepted R2R1 post-opt baseline was 19,574 LUT; this candidate is +1,872. The SCAN1 leaf grew from 687 to 2,017 LUT (+1,330), including LUTRAM 96→1,104 (+1,008). The synthesized AXI-Lite bridge hierarchy grew by 497 LUT without a source edit, reflecting mapping consequences of the new read-only address/telemetry cone. FF 20,884/41,600, BRAM 27/50 and DSP 0/90 remained within bounds. These sub-hierarchy numbers are attribution of the actual optimized netlist, not license to shrink the required exposure coverage or relax the hard gate.

The build stopped after one `synth_design` and one `opt_design`: place=0, phys_opt=0, route=0, bitstream writes=0. Neither the historical R2R1 bitstream nor the unsignable new post-opt DCP was deployed. Source branch publication is for a failed diagnostic experiment only.

## Hardware and scientific non-claims

The only allowed DUT endpoint would have been `192.168.1.57:22`; it was not contacted. No controller/DUT hardware locks, driver, PCIe/MMIO access, programming, autoinit, reboot, scanner run, camera operation, generic I2C, functional NVP write, EQ, MODE1 or capture occurred. Control scans 0/1; campaign scans 0/1000. Existing DUT state was not independently surveyed or altered by this task. Cleanup is not applicable to hardware because there was no hardware access.

The preregistered early/late, temporal, group-position and error-phase analyses are `NOT_ASSESSED_CAMPAIGN_INCOMPLETE`. No CONT1R3 recovered-event counts, exposure denominators or physical root-cause conclusion exist. CONT1R2's ten historical events remain an inherited observation, not a substitute for this run. The separate 10,000-scan zero-error gate remains unrun and unsatisfied.

## Next step

A separately authorized resource-efficient instrumentation design would have to retain complete 82-entry event/exposure coverage, first-cause fidelity and non-telemetry equivalence while meeting the device and sign-off gates in a **new** governed build. Do not program this failed candidate or treat any causal hypothesis as confirmed.
