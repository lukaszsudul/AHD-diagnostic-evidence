# C4 source and warning scope

The C3-to-C4 diff contains exactly six approved paths: `rtl/g2b/g2b_nvp_camera_scan1.sv`, `rtl/g2b/g2b_nvp_camera_w3_telemetry.sv`, `host/w3a/contract.py`, `host/w3a/controller.py`, `host/w3a/decoder.py`, and `host/w3a/resources/W3A_CONTRACT.json`. `git diff --check` passed before commit; the pinned source worktree is clean. No capture, ACQ, master, vendor table, driver, IP, XDC, SSOT or PRODUCT file was edited.

Vivado 2025.2 SW build 6299465 reported synthesis complete with zero errors and zero critical warnings. The changed scanner file showed the same four `Synth 8-6014` removed-register warnings as C3. No warning was emitted from the changed W3a module, and the log showed no new port-width, implicit-net, truncation or multiple-driver warning in these two changed RTL files. Generated XDMA and inherited user modules account for the broader warning stream; the raw log remains private and byte-hashed in the failure manifest.

Python AST parsing, imports and the exact contract check passed without opening a device. The 17-bit page arithmetic and 16-word register offsets passed the targeted static check. The copied seven-file host bundle passed its offline self-test with `device_opened=false`. None of these checks is a dynamic RTL equivalence proof.
