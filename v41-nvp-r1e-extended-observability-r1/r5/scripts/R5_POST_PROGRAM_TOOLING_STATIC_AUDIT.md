# R5 post-program tooling static audit

The audit was performed offline only. No SSH, MMIO, JTAG, Vivado, reboot,
driver load, programming, or other hardware/network operation was executed.

## Frozen hash gate

All byte-identical dependencies match their R3/R4 evidence identities:

```text
Invoke-ContextualPlink.ps1=5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9
parse_pci_bars.py=5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922
read_nvp_r1e.py=0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037
read_jtag_identity_done_strong.tcl=CD4938C311D886F0DEAB5FC69B9F8CDFDB0B663F40C5D174164FB14B3D9839AD
verify_runtime_identity.py=84D143C674AB7CF40E3043178B5F8D926B182A89491B76307CD69E2117D1337C
analyze_r4_telemetry.py=A19A290FF57B588AA02868F8E46AA9386005EFB0FBC38072C4373DB32F6AB967
program_once_startup_high_done.tcl=7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653
ProgramObserverCommon.ps1=6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66
```

## R5-adapted file identities

```text
Invoke-R5IndependentDoneReadOnly.ps1
SHA256=A19292066BA1AFE202911498ECE2B61CDB3998D4441DA56F81D6416833781D73

Invoke-R5WarmRebootOnce.ps1
SHA256=EDB80B06651CE9B491B70CFC4967BFB4C6B266BA1DAF47AC765FC987D53F3AF7

Wait-R5HostCycle.ps1
SHA256=429835AC2D36E4DEAE40C7C979B1A42497E8B049CAEF7B8FBA32D688C579BA22

r5_post_reboot_preloader_readonly.sh
SHA256=576EA05247070AC6B17F3C3355AB691EA27D99A8437F77AD052FCB6B74495B64

Invoke-R5RemoteValidator.ps1
SHA256=58A3D39CF5CAB6300C0A4A3A7193DB337EF023267CE95193693FF6CC4DC24F6B

Invoke-R5ExactPinnedLoaderOnce.ps1
SHA256=8D452CF8EE3C40E86623A6B975BC9B40127497A48C4332AE5E4E3218814FFA45

r5_post_loader_readonly.sh
SHA256=AFBE124BC9E57E4290597E54BA4D4CAA752C86F002F6ED4506ECA8B762BD5263

Invoke-R5TelemetryReadOnly.ps1
SHA256=552E62771454288D04633487D0994466EC19007B89ED94BA61BB6B2FFE6CD1EA
```

## Static results

`Test-R5PostProgramToolingStatic.ps1` exited 0 with:

```text
POWERSHELL_PARSE_ERRORS=0_ALL_SIX_R5_WRAPPERS
NORMALIZED_R4_EQUALITY=PASS_ALL_FIVE_ADAPTED_R4_FILES
READ_ONLY_VALIDATOR_FORBIDDEN_MUTATION_MATCHES=0
EXACT_LOADER_REMOTE_EXEC_COUNT=1
WARM_REBOOT_REMOTE_COMMAND_COUNT=1
TELEMETRY_CONTEXTUAL_HELPER_COUNT=1
INDEPENDENT_DONE_PROGRAM_COMMAND_COUNT=0
INDEPENDENT_DONE_PROGRAM_FILE_ASSIGNMENT_COUNT=0
R4_PATH_OR_ROLE_RESIDUAL_COUNT=0
NETWORK_OR_HARDWARE_EXECUTION_DURING_STATIC_TEST=0
R5_POST_PROGRAM_TOOLING_STATIC_GATE=PASS
```

The five R4-derived files normalize byte-for-byte to their reviewed R4 sources
after reversing only the R5 task-root, phase-directory, label, and filename
substitutions. The Windows host has no Bash parser, so the two Bash payloads
received exact normalized-diff reconciliation and forbidden-command scanning;
they were not dynamically executed.

## Safety conclusion

The prepared flow separates every state-changing operation from its read-only
validation. The reboot wrapper contains one reboot command; the loader wrapper
contains one exact accepted-loader invocation; the independent-DONE Tcl has no
program operation; telemetry uses the frozen O_RDONLY decoder twice one second
apart. No retry path is present.
