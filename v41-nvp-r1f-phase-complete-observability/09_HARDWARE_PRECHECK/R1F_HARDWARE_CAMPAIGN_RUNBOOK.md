# R1f hardware precheck and frozen campaign runbook

## Scope and current status

This is a static, fail-closed orchestration contract. Creating and auditing it
performed no SSH, JTAG, FPGA programming, reboot, driver load, MMIO or DMA
operation. It does not authorize a second build or any source correction.

The only live sequence encoded here is:

```text
optional exact-formal Bootstrap -> A1 -> B1 -> A2 -> B2 -> A3 -> B3
```

The bootstrap is omitted only when fresh evidence proves the existing exact
formal Phase-2 state. Every phase has one immutable local evidence directory
and one unique remote loader-evidence directory. A program-attempt reservation
is written before Vivado starts and is never deleted, so a consumed or
interrupted attempt cannot be silently retried.

## Mandatory frozen binding

`08_HOST_TOOLS/R1F_HARDWARE_BINDINGS.template.json` is intentionally not a
live binding. It already binds the fixture-passed R1f reader:

```text
scripts/v41/read_nvp_r1f.py
bytes=46868
sha256=5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C
```

After the single clean build passes, create
`08_HOST_TOOLS/R1F_HARDWARE_BINDINGS.json` from the template and replace only
the unresolved R1f bit/source/tree/wait fields plus the exact selected full
target path. Set `status` to `FROZEN_FOR_HARDWARE`. The R1f Arm-A wait is:

```text
max(10.0, MODELED_R1F_PROBE_COMPLETE_SECONDS_FROM_CONFIGURATION + 2.0)
```

The binding loader rehashes the formal bit, R1f bit and reader on every live
entry. It rejects placeholders, a wait below 10 seconds, a wrong part/IDCODE,
or a selected path without the exact `Xilinx/80802026a98b01` canonical suffix.

Before live precheck, require:

```powershell
& 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\09_HARDWARE_PRECHECK\Test-R1fCampaignToolingStatic.ps1' `
  -BindingPath 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\08_HOST_TOOLS\R1F_HARDWARE_BINDINGS.json' `
  -RequireFrozenHardwareBindings
```

Required terminal line:

```text
STATIC_AUDIT_GATE=PASS_READY_FOR_SEPARATE_LIVE_PRECHECK
```

## Fresh formal start-state gate

Initialize the seven unique local evidence leaves once:

```powershell
& 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\08_HOST_TOOLS\Initialize-R1fCampaignEvidenceDirectories.ps1'
```

Then execute the fresh read-only precheck in this exact order:

```powershell
$binding = 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\08_HOST_TOOLS\R1F_HARDWARE_BINDINGS.json'
$precheck = 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\09_HARDWARE_PRECHECK'

& "$precheck\Invoke-R1fHostBaselineReadOnly.ps1"
& "$precheck\Invoke-R1fPrecheckJtagDoneReadOnly.ps1" -BindingPath $binding
& "$precheck\Invoke-R1fStartSafetyReadOnly.ps1" -BindingPath $binding
```

The JTAG gate uses the exact R7 five-sample reconfirmation leaf and accepts a
readable stable DONE of zero or one. It performs zero programs and no frequency
change. Stable DONE=1 is still not treated as runtime identity.

If `R1F_START_SAFETY_GATE=PASS_EXISTING_FORMAL_INFRA_CANDIDATE`, run:

```powershell
& "$precheck\Invoke-R1fExistingFormalTelemetryReadOnly.ps1" -BindingPath $binding
& "$precheck\Finalize-R1fFreshFormalStartGate.ps1" -BindingPath $binding
```

Require `FORMAL_START_GATE=PASS_EXISTING_EXACT_FORMAL`, then create the A1
receipt with the exact gate and operation-ledger hashes:

```powershell
& "$precheck\New-R1fExistingFormalStartReceipt.ps1" `
  -BindingPath $binding `
  -FreshStartGatePath "$precheck\R1F_FRESH_FORMAL_START_GATE.txt" `
  -FreshStartGateSha256 '<EXACT_SHA256>' `
  -OperationLedgerSha256 '<EXACT_SHA256>'
```

This route consumes zero programs, zero reboots and zero driver loads.

If the safety gate is `PASS_SAFE_BOOTSTRAP_REQUIRED`, finalize it to
`FORMAL_START_GATE=BOOTSTRAP_REQUIRED_SAFE` and run the single Bootstrap phase
below. Any unsafe result hard-stops before programming.

## One phase transaction

For each phase token, all output paths must be fresh. Bind each predecessor
receipt by exact SHA-256. The phase transaction is:

1. program once through the exact R7 mode-aware observer;
2. independent read-only selected-target DONE=1;
3. monotonic minimum wait from the later accepted same-session marker;
4. exactly one warm reboot;
5. observe host down then up;
6. exact inherited read-only preloader/BAR/kernel safety validator;
7. exactly one explicit-path pinned loader with a unique remote directory;
8. two complete read-only R1f-reader snapshots using explicit `r1f` or
   `formal` expectation;
9. independent final DONE=1;
10. hash and issue the configured-image receipt.

Command skeleton:

```powershell
$tools = 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\08_HOST_TOOLS'
$binding = "$tools\R1F_HARDWARE_BINDINGS.json"
$phase = '<Bootstrap|A1|B1|A2|B2|A3|B3>'

& "$tools\Invoke-R1fProgramOnce.ps1" `
  -PhaseToken $phase -BindingPath $binding `
  -ConfiguredImageReceiptPath '<NOT_USED_FOR_BOOTSTRAP>' `
  -ExpectedConfiguredImageReceiptSha256 '<NOT_USED_FOR_BOOTSTRAP>'

& "$tools\Invoke-R1fIndependentDoneReadOnly.ps1" `
  -PhaseToken $phase -Stage Immediate -BindingPath $binding

& "$tools\Wait-R1fProgramMinimum.ps1" `
  -PhaseToken $phase -BindingPath $binding `
  -ProgramTimingSha256 '<EXACT_SHA256>' `
  -IndependentDoneSha256 '<EXACT_SHA256>'

& "$tools\Invoke-R1fHostStep.ps1" -PhaseToken $phase -Step WarmReboot -BindingPath $binding
& "$tools\Invoke-R1fHostStep.ps1" -PhaseToken $phase -Step WaitHostCycle -BindingPath $binding
& "$tools\Invoke-R1fHostStep.ps1" -PhaseToken $phase -Step PreLoaderValidate -BindingPath $binding -PreviousBootId '<PREVIOUS_BOOT_ID>'
& "$tools\Invoke-R1fHostStep.ps1" -PhaseToken $phase -Step ExactDriverLoad -BindingPath $binding
& "$tools\Invoke-R1fTelemetryReadOnly.ps1" -PhaseToken $phase -BindingPath $binding
& "$tools\Invoke-R1fIndependentDoneReadOnly.ps1" -PhaseToken $phase -Stage Final -BindingPath $binding
```

For Bootstrap and every B phase, issue `FormalReady`; for each valid A phase,
issue `ValidArmA`:

```powershell
& "$tools\New-R1fConfiguredImageReceipt.ps1" `
  -PhaseToken $phase -ReceiptKind '<FormalReady|ValidArmA>' `
  -BindingPath $binding -OperationLedgerSha256 '<EXACT_SHA256>'
```

The Bootstrap receipt is deliberately published at
`09_HARDWARE_PRECHECK/FORMAL_START_READY_RECEIPT.txt`, the same A1 entry path
used by the mutually exclusive existing-formal route. That collision is
intentional: both start-state routes cannot be asserted at once.

## Frozen receipt chain

```text
A1 <- 09_HARDWARE_PRECHECK/FORMAL_START_READY_RECEIPT.txt
B1 <- 11_PAIR_1/A1_R1F/VALID_ARM_A_RECEIPT.txt
A2 <- 11_PAIR_1/B1_FORMAL/FORMAL_READY_RECEIPT.txt
B2 <- 12_PAIR_2/A2_R1F/VALID_ARM_A_RECEIPT.txt
A3 <- 12_PAIR_2/B2_FORMAL/FORMAL_READY_RECEIPT.txt
B3 <- 13_PAIR_3/A3_R1F/VALID_ARM_A_RECEIPT.txt
```

The program wrapper rejects any receipt path outside this chain. An immediate
post-program A DONE=1 can instead issue
`ARM_A_TERMINAL_SAFE_DONE1_RECEIPT.txt`; it authorizes only the paired B
control/restoration, after which the campaign hard-stops.

## Absolute accounting

| Route | Programs | Warm reboots | Driver loads |
|---|---:|---:|---:|
| existing formal start | 6 | 6 | 6 |
| one formal bootstrap | 7 | 7 | 7 |

Each phase maximum is one program, one reboot and one load. Program retries
are zero. No fourth pair, second bootstrap, cold start, physical action, JTAG
frequency change, PCI remove/rescan, AXI-Lite write or DMA path exists in the
wrappers.

## Failure handling

A valid scientific PASS or FAIL continues to its B and then the next pair.
An infrastructure-invalid A with a valid immediate DONE1 receipt runs only its
paired B when safe, then hard-stops. An infrastructure-invalid B hard-stops
before the next A. No failed arm is repeated.

## Inherited-tool collision notices

The R7 high-level orchestration scripts hardcode the R7 task root and the
single `ArmA`/`ArmB` evidence directories. Direct reuse would overwrite or
misattribute evidence, so R1f never invokes those wrappers. It reuses the
exact hash-bound selected-target selector, mode-aware Tcl, post-program
parser, read-only JTAG Tcl, BAR parser and contextual Plink credential/host-key
procedure.

The two accepted R7 shell validators also hardcode stale R7 remote evidence
directories. Their exact base bytes are hash-gated, then an in-memory adapter
changes only those directory literals: the pre-start safety list changes from
three R7 paths to all seven R1f paths, and each phase preloader changes its one
R7 path to that phase's unique R1f path. Base/adapted hashes and literal counts
are recorded in `R1F_REMOTE_DIRECTORY_ADAPTER_AUDIT.csv` and in each live
adapter receipt. No kernel, endpoint, BAR, module, node-owner, DMA or AER gate
is changed.

The inherited mode-aware Tcl retains the internal role token `ARM_A_R1E` and
emits inherited `R7_*` target keys. Those strings are observer ABI, not image
identity. The outer R1f wrapper binds the exact R1f bit SHA/source/tree and
records `PHASE_TOKEN=A1|A2|A3` plus `R1F_FULL_JTAG_TARGET_PATH`.

The R7 telemetry wrapper is not reused because it hardcodes the R1e reader.
The R7 post-loader wrapper is not reused for R1f because it hardcodes R1e
runtime provenance. R1f uses the fixture-passed, hash-bound read-only R1f
reader with explicit image expectation.
