# AHD v41 R15R1 — firmware-only LUT correction

Result: **BLOCKED_POST_OPT_LUT_CAPACITY**.

One local FEQ1 terminal-context representation correction was implemented from the exact R15 source. Full reference EQ coverage and FEQ1 semantics are source-preserved and functionally untested. Coverage remains 28 rows, zero required elements missing. Frozen ABI and host/reference files are byte-identical.

Post-opt Slice LUT: **21,377 → 21301**, reduction **76**. Strict maximum: **20,799**. Full stage, resource and timing results are in RESULT.json. Engineering acceptance and publication are separate.

Linux reader work is **DEFERRED_BY_OWNER**, with no discovery, installation, compilation or execution. It is not the FPGA blocker. The complete ten-frame experiment package is **not ready**. Tests/DUT: **0/0**. No camera, EQ execution or product qualification is claimed.

Source commit: `e32dae86af20fa5c385026397b7042d8b1dafcd4`; tree `2f5293036bc91175f9615756923127e8ae3ed8ce`. Detailed source, ABI, checkpoints, firmware and logs remain private. Historical R15 is unchanged.
