# R2R10R14R5R1 — sanitized result

## Result

- Analysis execution: `PASS`.
- Timing result: `SETUP_VIOLATION_LOCALIZED`.
- Negative endpoint coverage: `COMPLETE` (17/17 setup endpoints in the current timing model).
- Native WNS/TNS/WHS/THS: -0.150/-1.381/+0.036/0.000 ns.
- Fresh WNS/TNS/WHS/THS: -0.149/-1.362/+0.036/0.000 ns.
- All 17 failures are same-clock paths in the 148.5 MHz video/C2H source domain. They form two functional families: 16 lifetime-drop accounting enable endpoints and one descriptor-epoch capture enable endpoint.
- Representative paths contain eight logic levels. Routed-net delay dominates at 72.3-74.0%; clock skew is small by comparison.
- No valid timing exception applies to any exact failing start/end pair. No timing constraint was modified.
- The failing endpoints are outside the I2C loader and retry telemetry. This is localization, not proof that the new retry change caused or did not cause physical implementation movement.
- DCP identity: `B1AE995CD19BEFA562C7427F9A8DA183CAA0014FBAF1397F218D127519552AF8`; source `c05f62d204853f36263b5fd486596abd517f5e92`, tree `9d35c25b09718057bb100314309006baae8409c5`.
- DCP open / successful timing summary: 1/1. Product changes, build commands and DUT contact: 0/0/0.

## Decision

The R14R5 bitstream retains a setup violation and is not newly admitted to hardware by this analysis. The single proposed next action is a source-level refactor of the demonstrated video/C2H commit-validation enable cone, followed by a separately authorized full rebuild. No correction was implemented.

Full netlist paths, source mapping, DCP, bitstream and detailed logs remain private.
