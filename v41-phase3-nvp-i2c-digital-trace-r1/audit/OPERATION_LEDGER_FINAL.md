# Operation Ledger

Initial state before source export:

```text
FORMAL_GIT_COMMITS=0
FORMAL_GIT_PUSHES=0
FORMAL_TAGS_CREATED=0
FORMAL_BRANCHES_CREATED=0
FORMAL_TRACKED_FILE_CHANGES=0
DIAGNOSTIC_LOCAL_BUILD_CYCLES=2
DIAGNOSTIC_SRAM_PROGRAM_ATTEMPTS=1
DIAGNOSTIC_SRAM_PROGRAM_SUCCESSES=1
FORMAL_RESTORE_PROGRAM_ATTEMPTS=1
FORMAL_RESTORE_PROGRAM_SUCCESSES=1
COLD_STARTS=0
UBUNTU_WARM_REBOOTS=2
AXIL_WRITES=0
PHASE3_STRESS_READS=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHASE3_RESUMED=NO
PHASE4_STARTED=NO
```

Build cycle 1 stopped during RTL elaboration before implementation or
bitstream generation because two observer-only VHDL-2008 constructs were not
accepted by the preserved project VHDL mode. The smallest observer-only syntax
correction was applied in the non-Git diagnostic export and the complete exact
sealed-R2 simulation gate passed before authorizing cycle 2.

Build cycle 2 completed synthesis, placement, full route, bitstream generation,
and all mandatory offline gates. No third build cycle was used.

The sealed diagnostic image was then programmed on its single authorized SRAM
attempt with EOS HIGH and DONE 1. The first required warm reboot completed,
the pinned XDMA driver was hash-gated and loaded, and the complete frozen trace
was retrieved once through 8,227 read-only diagnostic AXI-Lite transactions.
Two additional successful 46-word formal-map snapshots supplied bounded
post-trace NVP/video telemetry. No Phase-3 stress campaign occurred.

After the measurement ZIP and its internal manifest were verified, the exact
accepted Phase-2 image was programmed once with EOS HIGH and DONE 1. The second
required warm reboot completed. Formal identity, endpoint, BAR layout, pinned
driver, Gen1 x1 link, and JTAG DONE all passed; a safe read of formal address
`0x2000` returned zero, proving diagnostic magic absent.

The formal branch, HEAD, complete branch/tag ref sets, staged state, tracked
state, and untracked state match their before-state evidence. No Git write or
functional project mutation occurred.

```text
DIAGNOSTIC_BIT_ACTIVE=NO
FORMAL_BASELINE_RESTORED=YES
FORMAL_REPOSITORY_MUTATION=0
FLASH_OPERATIONS=0
CFGMEM_OPERATIONS=0
PROGRAM_B_OPERATIONS=0
MANUAL_I2C_WRITES=0
FUNCTIONAL_I2C_CHANGES=0
TEMP_DIAGNOSTIC_WORKSPACE_DELETED=YES
DIAGNOSTIC_EVIDENCE_RETAINED_OUTSIDE_REPO=YES
```
