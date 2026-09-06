# Unexecuted T1 draft safety review

The offline T1 draft and its publisher/runner were never copied to or executed
on the DUT. Their source bodies are intentionally excluded from public evidence
because the shell draft is not an accepted or safe procedure.

Original controller source SHA-256:

- `t1_exact_module_load_probe.sh`:
  `13455087AFA5289CA2E7AD47782E795A93E1DBC7B4D0B0ABC8EB70882F1A9C6C`
- `publish_t1_tool_to_dut.ps1`:
  `E1F863346869C152C983A3C58885E3F8D4C2F2D62BF68098BF4F39B30D7958D4`
- `run_t1_exact_module_load_probe.ps1`:
  `F7FF4D85A14384A7A04C92F1BEE695A072B3136E0BA721FFA9A184FA86ADDAB2`

Safety findings:

- `fuser` inspection failure can be collapsed to zero holders;
- no mandatory MMIO quiescence proof precedes unload;
- no post-load `EXIT`/`INT`/`TERM` rollback trap exists;
- timeout or interruption can strand a loaded module;
- the nominal 20-second loop can exceed the bound;
- same-index checks do not provide two independent node-to-BDF paths.

Disposition: `UNEXECUTED_EXCLUDED_UNSAFE_DRAFT`. No load-attempt marker or T1
runtime evidence exists; the sealed final receipts record zero module-load and
zero module-unload attempts.
