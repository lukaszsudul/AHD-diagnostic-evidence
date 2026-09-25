# AHD v41 R15R2 — one post-opt placement continuation

Engineering result: **BLOCKED_FINAL_TIMING**.

Input: exact R15R1 post-opt ExploreArea, 54,497,108 bytes, SHA-256 7764B7A2AF61A6C7F3968CCC5D6CFB31946FFCFE42DA1F8ADDC786CB0FDAC5EE.
Original and independently copied input unchanged before/after: True.
Source commit e32dae86af20fa5c385026397b7042d8b1dafcd4; tree 2f5293036bc91175f9615756923127e8ae3ed8ce. Code, ABI, host and constraints unchanged.

The Owner allowed input 21,301 Slice LUT into one ordinary placement with native checks enabled. Strict post-placement and later limit remains less than 20,800.
Actual command counts: {"bitgen": 0, "checkpoint_open": 1, "constraint_changes": 0, "dut_contact": 0, "functional_tests": 0, "opt": 0, "place": 1, "post_route_physopt_explore": 1, "reader_work": 0, "route": 1, "severity_changes": 0, "source_changes": 0, "synth": 0, "toolchain_work": 0}.
First blocker: {"RESULT": "BLOCKED_FINAL_TIMING", "STAGE": "FINAL_CHECKS", "DETAIL": "WNS=-3.788 WHS=0.016 WPWS=0.000 failing=128/0/0"}.
Measurements and actual stage times: RESULT.json and RESOURCE_STAGES.csv.
Bitstream: NOT_CREATED; actual output hashes are listed in HASHES.json.

Full reference EQ source coverage remains 28 rows, zero missing; hybrid host/FPGA unchanged. No functional/equivalence qualification or camera result.
Linux reader work deferred by Owner, no compilation or toolchain work. Ten-frame hardware package ready: NO.
DUT contact and functional tests: 0/0. Historical R15/R15R1 blocked outcomes remain unchanged.
Native log/checkpoints/firmware/product code/ABI/environment details remain private.
