[CmdletBinding()]
param()

# Static/offline only. This file parses and hashes tooling; it does not invoke
# any campaign wrapper, Vivado, plink/SSH, JTAG, host, MMIO, program, reboot,
# driver, or DMA operation.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$TaskRoot = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$ToolRoot = Join-Path $TaskRoot '09_HOST_TOOLS'
$PrecheckRoot = Join-Path $TaskRoot '10_HARDWARE_PRECHECK'
$LogPath = Join-Path $PrecheckRoot 'R1H_OFFLINE_CAMPAIGN_STATIC_FIXTURE.log'
. (Join-Path $ToolRoot 'R1hCampaignCommon.ps1')

$Results = [Collections.Generic.List[object]]::new()
function Add-Gate([string]$Name,[bool]$Pass,[string]$Detail) {
    $Results.Add([pscustomobject]@{Gate=$Name;Result=if($Pass){'PASS'}else{'FAIL'};Detail=$Detail})
}
function Exact([string]$Path,[long]$Bytes,[string]$Sha256) {
    try {[void](Assert-R1hExactFile -Path $Path -Bytes $Bytes -Sha256 $Sha256);return $true} catch {return $false}
}

try { Assert-R1hAcceptedToolSet; Add-Gate ACCEPTED_R7_R6_LEAF_HASHES $true 'all inherited leaf paths, byte counts and SHA-256 values exact' }
catch { Add-Gate ACCEPTED_R7_R6_LEAF_HASHES $false $_.Exception.Message }

$Wrappers = @(
    'Initialize-R1hCampaignEvidenceDirectories.ps1','Invoke-R1hHostStep.ps1',
    'Invoke-R1hIndependentDoneReadOnly.ps1','Invoke-R1hProgramOnce.ps1',
    'Invoke-R1hTelemetryReadOnly.ps1','New-R1hConfiguredImageReceipt.ps1',
    'R1hCampaignCommon.ps1','Wait-R1hProgramMinimum.ps1'
)
$Prechecks = @(
    'Finalize-R1hFreshFormalStartGate.ps1','Invoke-R1hExistingFormalTelemetryReadOnly.ps1',
    'Invoke-R1hHostBaselineReadOnly.ps1','Invoke-R1hPrecheckJtagDoneReadOnly.ps1',
    'Invoke-R1hStartSafetyReadOnly.ps1','New-R1hExistingFormalStartReceipt.ps1',
    'New-R1hCampaignToolingOffline.ps1','Test-R1hCampaignToolingOffline.ps1'
)
foreach ($name in $Wrappers) {
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $ToolRoot $name),[ref]$tokens,[ref]$errors)
    Add-Gate ("POWERSHELL_PARSE_$($name.ToUpperInvariant())") ($errors.Count -eq 0) (($errors|ForEach-Object Message)-join' | ')
}
foreach ($name in $Prechecks) {
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $PrecheckRoot $name),[ref]$tokens,[ref]$errors)
    Add-Gate ("POWERSHELL_PARSE_$($name.ToUpperInvariant())") ($errors.Count -eq 0) (($errors|ForEach-Object Message)-join' | ')
}

$Frozen = [ordered]@{
    'read_nvp_r1f.py'=@(46868,'5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C')
    'r1f_statistics.py'=@(38404,'C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD')
    'test_nvp_r1f_tools.py'=@(17276,'7AD2E8FA36D685CFC916B007A65BE9B807398A71CB6730E067C31CD9673C52B1')
    'fixtures\r1f_valid_scenario.json'=@(899,'8D6C63878488F79B1299F1AD2576EF830C52741F2938A9715EC597FBF4FAB1A8')
    'read_nvp_r1e.py'=@(8385,'0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037')
}
foreach($entry in $Frozen.GetEnumerator()) {
    $path=Join-Path (Join-Path $ToolRoot 'frozen_r1f_host_tools') $entry.Key
    Add-Gate ("FROZEN_$($entry.Key.ToUpperInvariant().Replace('\','_').Replace('.','_'))") (Exact $path $entry.Value[0] $entry.Value[1]) $entry.Value[1]
}

$ReaderPath='C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\scripts\v41\read_nvp_r1f.py'
$ReaderExact=Exact $ReaderPath 46868 '5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C'
Add-Gate R1H_READER_BYTE_IDENTICAL_TO_R1F_R1G $ReaderExact 'SHA256=5BDE0B94...; source binding remains pending commit/build'
$Reader=[IO.File]::ReadAllText($ReaderPath)
$VariableLatency=($Reader.Contains('os_module.pread(fd, 4, offset)',[StringComparison]::Ordinal) -and
    $Reader.Contains('os.O_RDONLY | os.O_CLOEXEC',[StringComparison]::Ordinal) -and
    -not [regex]::IsMatch($Reader,'\bos\.(?:pwrite|write)\s*\(') -and
    -not $Reader.Contains('O_NONBLOCK',[StringComparison]::Ordinal) -and
    -not $Reader.Contains('mmap',[StringComparison]::OrdinalIgnoreCase))
Add-Gate VARIABLE_LATENCY_BLOCKING_PREAD_READER $VariableLatency 'one blocking 4-byte pread per address; no zero-cycle assumption, mmap, nonblocking mode, MMIO write, or DMA API'
Add-Gate FORMAL_COMPLETE_R1H_RANGE_ZERO_READER ($Reader.Contains('R1F_FIRST = 0x20A0',[StringComparison]::Ordinal) -and $Reader.Contains('R1F_END_EXCLUSIVE = 0x3600',[StringComparison]::Ordinal) -and $Reader.Contains('formal image did not return deterministic zero across 0x20A0..0x35FF',[StringComparison]::Ordinal)) 'all aligned words 0x20A0..0x35FC'

$ProgramTcl=[IO.File]::ReadAllText($script:R1hAcceptedTools.ModeAwareObserverTcl.Path)
$Observer=[IO.File]::ReadAllText($script:R1hAcceptedTools.ProgramObserverParser.Path)
$Reconfirm=[IO.File]::ReadAllText($script:R1hAcceptedTools.JtagReconfirmationTcl.Path)
Add-Gate PROGRAM_HW_DEVICES_EXACTLY_ONE ([regex]::Matches($ProgramTcl,'(?m)^\s*program_hw_devices\b').Count -eq 1) 'exact R7 mode-aware Tcl leaf'
Add-Gate VENDOR_STARTUP_HIGH_GATE ($Observer.Contains('Labtools 27-3164',[StringComparison]::Ordinal) -and $Observer.Contains('End of startup status:\s*HIGH',[StringComparison]::Ordinal)) 'exact accepted observer parser'
Add-Gate SAME_SESSION_DONE_BIT5_GATE ([regex]::Matches($ProgramTcl,'get_property\s+\$bit5_property').Count -ge 1) 'REGISTER.IR.BIT5_DONE'
Add-Gate BIT4_EOS_NOT_QUERIED ([regex]::Matches($ProgramTcl,'get_property\s+\$bit4_property').Count -eq 0) 'BIT4 not used'
Add-Gate JTAG_FREQUENCY_UNCHANGED ([regex]::Matches($ProgramTcl,'(?im)^\s*set_property\s+[^\r\n]*(?:FREQUENCY|JTAG_FREQUENCY)').Count -eq 0) 'no frequency-changing set_property'
Add-Gate START_JTAG_READ_ONLY (-not [regex]::IsMatch($Reconfirm,'(?m)^\s*(?:program_hw_devices|set_property)\b')) 'fresh start JTAG leaf cannot program or set properties'
Add-Gate START_JTAG_FIVE_STABLE_SAMPLES $Reconfirm.Contains('set sample_count 5',[StringComparison]::Ordinal) 'five read-only samples'

$ProgramWrapper=[IO.File]::ReadAllText((Join-Path $ToolRoot 'Invoke-R1hProgramOnce.ps1'))
Add-Gate WRAPPER_DIRECT_PROGRAM_ABSENT (-not $ProgramWrapper.Contains('program_hw_devices',[StringComparison]::Ordinal)) 'only accepted Tcl leaf programs'
Add-Gate PROGRAM_RESERVATION_BEFORE_LAUNCH ($ProgramWrapper.Contains('PROGRAM_ATTEMPT_RESERVATION.txt',[StringComparison]::Ordinal) -and $ProgramWrapper.Contains('PROGRAM_RETRY_AUTHORIZED=NO',[StringComparison]::Ordinal)) 'immutable reservation and no retry'
Add-Gate ONE_PROGRAM_PROCESS_START ([regex]::Matches($ProgramWrapper,'\$process\.Start\(\)').Count -eq 1) 'one supervisor start, no restart loop'
Add-Gate CONDITIONAL_BOOTSTRAP_MAX_ONE ($ProgramWrapper.Contains('FORMAL_START_GATE=BOOTSTRAP_REQUIRED_SAFE',[StringComparison]::Ordinal) -and $ProgramWrapper.Contains('conditional bootstrap is forbidden after an exact formal-start receipt already exists',[StringComparison]::Ordinal)) 'bootstrap mutually exclusive with existing-formal receipt'

$Tokens=@('A1','B1','A2','B2','A3','B3')
$Specs=@($Tokens|ForEach-Object{Get-R1hPhaseSpec $_})
Add-Gate FROZEN_SEQUENCE (($Specs.Token -join ',') -ceq 'A1,B1,A2,B2,A3,B3') ($Specs.Token -join ' -> ')
Add-Gate ARM_A_WAIT_EXACT (@($Specs | Where-Object { $_.Kind -eq 'ARM_A' } | Where-Object { [Math]::Abs($_.RequiredWaitFloorSeconds - 33.536673744) -gt 0.000000000001 }).Count -eq 0) 'A1/A2/A3=33.536673744'
Add-Gate FORMAL_WAIT_FLOOR (@($Specs | Where-Object { $_.Kind -eq 'ARM_B' } | Where-Object { $_.RequiredWaitFloorSeconds -ne 5.0 }).Count -eq 0) 'B1/B2/B3=5.0'
$All=@((Get-R1hPhaseSpec Bootstrap))+$Specs
Add-Gate UNIQUE_EVIDENCE_LEAVES (@($All.Directory | Select-Object -Unique).Count -eq 7) ($All.Directory -join '; ')
Add-Gate UNIQUE_REMOTE_DRIVER_LEAVES (@($All.RemoteDriverAbsolutePath | Select-Object -Unique).Count -eq 7) ($All.RemoteDriverAbsolutePath -join '; ')
Add-Gate MAXIMA_SEVEN ($script:R1hMaximumPrograms -eq 7 -and $script:R1hMaximumWarmReboots -eq 7 -and $script:R1hMaximumDriverLoads -eq 7) 'optional bootstrap plus six arms'

$Sequence=Import-Csv -LiteralPath (Join-Path $PrecheckRoot 'R1H_FROZEN_CAMPAIGN_SEQUENCE.csv')
Add-Gate SEQUENCE_CSV_EXACT (($Sequence.phase_token -join ',') -ceq 'Bootstrap,A1,B1,A2,B2,A3,B3') ($Sequence.phase_token -join ' -> ')
Add-Gate ZERO_RETRY_ALL_PHASES (@($Sequence | Where-Object { $_.retry_max -ne '0' }).Count -eq 0) 'retry_max=0 for bootstrap and all six arms'
Add-Gate ONE_ACTION_PER_PHASE (@($Sequence | Where-Object { $_.program_max -ne '1' -or $_.reboot_max -ne '1' -or $_.driver_load_max -ne '1' }).Count -eq 0) 'per-phase maxima all one'

$Common=[IO.File]::ReadAllText((Join-Path $ToolRoot 'R1hCampaignCommon.ps1'))
Add-Gate EXACT_JTAG_BINDING ($Common.Contains('Xilinx/80802026a98b01',[StringComparison]::Ordinal) -and $Common.Contains('xc7a35t',[StringComparison]::Ordinal) -and $Common.Contains('0362D093',[StringComparison]::Ordinal)) 'canonical target/part/IDCODE'
Add-Gate EXACT_FORMAL_BINDING ($Common.Contains('7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2',[StringComparison]::Ordinal) -and $Common.Contains('c89e88bcdf389614c884fb129e8b2d42a585bccb',[StringComparison]::Ordinal) -and $Common.Contains('417820c69c134161fcafae0947dc5976919814d1',[StringComparison]::Ordinal)) 'formal bit/commit/tree exact'
Add-Gate EXACT_HOST_DRIVER_BINDING ($Common.Contains('10.132.1.111',[StringComparison]::Ordinal) -and $Common.Contains('7.0.0-29-generic',[StringComparison]::Ordinal) -and $Common.Contains('1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A',[StringComparison]::Ordinal) -and $Common.Contains('7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F',[StringComparison]::Ordinal)) 'host/kernel/module/loader exact'
Add-Gate RECEIPT_CHAIN_FROZEN ($Common.Contains("'A1' { return Join-Path `$script:R1hPrecheckRoot 'FORMAL_START_READY_RECEIPT.txt' }",[StringComparison]::Ordinal) -and $Common.Contains("'B3' { return Join-Path (Get-R1hPhaseSpec A3).Directory 'VALID_ARM_A_RECEIPT.txt' }",[StringComparison]::Ordinal)) 'formal -> A1 -> B1 -> A2 -> B2 -> A3 -> B3'
Add-Gate BUILD_RELEASE_FAIL_CLOSED ($Common.Contains('POST_SYNTH_RESOURCE_MARGIN_GATE=PASS',[StringComparison]::Ordinal) -and $Common.Contains('SOURCE_COMMIT_TO_BIT_PROVENANCE=PASS',[StringComparison]::Ordinal) -and $Common.Contains('BITSTREAM=PASS',[StringComparison]::Ordinal)) 'active binding requires exact hashed full-build release receipt'
Add-Gate MODELED_WAIT_FAIL_CLOSED ($Common.Contains('modeled R1h probe completion plus two seconds exceeds the frozen Arm-A wait',[StringComparison]::Ordinal) -and $Common.Contains('33.536673744',[StringComparison]::Ordinal)) 'model+2 must fit exact frozen wait'

$Telemetry=[IO.File]::ReadAllText((Join-Path $ToolRoot 'Invoke-R1hTelemetryReadOnly.ps1'))
Add-Gate TWO_COHERENT_SNAPSHOTS ($Telemetry.Contains('--twice --delay 1.0',[StringComparison]::Ordinal) -and $Telemetry.Contains('STATIC_SNAPSHOTS_MATCH=YES',[StringComparison]::Ordinal)) 'T0/T1 complete reader snapshots'
Add-Gate INHERITED_R1F_READER_ABI $Telemetry.Contains("`$expect=if(`$phase.Image-ceq'R1H'){'r1f'}else{'formal'}",[StringComparison]::Ordinal) 'R1h data/map remains exact R1f ABI'
Add-Gate RUNTIME_SOURCE_COMMIT_GATE ($Telemetry.Contains('$binding.r1hSourceCommit',[StringComparison]::Ordinal) -and $Telemetry.Contains('RUNTIME_PROVENANCE_GATE=PASS',[StringComparison]::Ordinal)) 'runtime Git SHA and BUILD_FLAGS before full telemetry'

$RuntimePath=Join-Path $ToolRoot 'r1h_runtime_provenance_readonly.sh'
$Runtime=[IO.File]::ReadAllText($RuntimePath)
Add-Gate RUNTIME_LEAF_READ_ONLY ($Runtime.Contains('os.O_RDONLY | os.O_CLOEXEC',[StringComparison]::Ordinal) -and $Runtime.Contains('os.pread',[StringComparison]::Ordinal) -and -not [regex]::IsMatch($Runtime,'\bos\.(?:pwrite|write)\s*\(')) 'O_RDONLY/pread only'
Add-Gate RUNTIME_BUILD_FLAGS_AND_FORMAL_ZERO ($Runtime.Contains('build_flags != 0x00000002',[StringComparison]::Ordinal) -and $Runtime.Contains('range(0x20A0, 0x3600, 4)',[StringComparison]::Ordinal)) 'R1h BUILD_FLAGS=2; formal complete range zero'

$AdapterRows=Import-Csv -LiteralPath (Join-Path $PrecheckRoot 'R1H_REMOTE_DIRECTORY_ADAPTER_AUDIT.csv')
Add-Gate DIRECTORY_ADAPTER_MATRIX ($AdapterRows.Count -eq 8 -and @($AdapterRows | Where-Object { $_.semantic_change -notlike 'NONE_OUTSIDE_*' }).Count -eq 0) 'one start block plus seven phase-specific directory-only adapters'
$HostStep=[IO.File]::ReadAllText((Join-Path $ToolRoot 'Invoke-R1hHostStep.ps1'))
$StartSafety=[IO.File]::ReadAllText((Join-Path $PrecheckRoot 'Invoke-R1hStartSafetyReadOnly.ps1'))
$HashesBound=$true
foreach($row in $AdapterRows){if($row.phase_token -ceq 'START'){$HashesBound=$HashesBound -and $StartSafety.Contains($row.adapted_sha256,[StringComparison]::Ordinal)}else{$HashesBound=$HashesBound -and $HostStep.Contains($row.adapted_sha256,[StringComparison]::Ordinal)}}
Add-Gate DIRECTORY_ADAPTER_HASHES_BOUND $HashesBound 'every adapted payload SHA embedded in wrapper'

$TemplatePath=Join-Path $ToolRoot 'R1H_HARDWARE_BINDINGS.template.json'
$Template=Get-Content -Raw -LiteralPath $TemplatePath|ConvertFrom-Json -Depth 20
$Pending=($Template.status -ceq 'PENDING_R1H_BUILD' -and $Template.selectedFullJtagTargetPath -ceq 'PENDING_FRESH_DISCOVERY' -and $Template.r1hBit.bytes -eq 0 -and $Template.r1hBit.sha256 -ceq 'PENDING_ONE_CLEAN_BUILD' -and $Template.r1hSourceCommit -ceq 'PENDING_ONE_R1H_SOURCE_COMMIT' -and $Template.r1hBuildRelease.bytes -eq 0 -and [double]$Template.r1hBit.requiredWaitSeconds -eq 33.536673744)
Add-Gate TEMPLATE_FAILS_CLOSED $Pending 'source/tree/bit/build-release/full-target unresolved; wait frozen'
$Active=Join-Path $ToolRoot 'R1H_HARDWARE_BINDINGS.json'
Add-Gate ACTIVE_BINDING_ABSENT (-not (Test-Path -LiteralPath $Active)) 'active binding forbidden before one R1h commit and one clean build PASS'

$Failed=@($Results | Where-Object { $_.Result -ne 'PASS' })
$Gate=if($Failed.Count){'FAIL'}else{'PASS_OFFLINE_BINDING_PENDING'}
$Lines=[Collections.Generic.List[string]]::new()
foreach($result in $Results){$Lines.Add("GATE=$($result.Gate) RESULT=$($result.Result) DETAIL=$($result.Detail)")}
$Lines.Add("STATIC_AUDIT_GATE=$Gate")
$Lines.Add('HARDWARE_BINDING_STATUS=PENDING_R1H_BUILD')
$Lines.Add('LIVE_PRECHECK_EXECUTED=NO')
$Lines.Add('LIVE_SSH_JTAG_VIVADO_MMIO_PROGRAM_REBOOT_DRIVER_ACTIONS=0')
$Lines.Add('FPGA_PROGRAMS=0')
$Lines.Add('HOST_REBOOTS=0')
$Lines.Add('DRIVER_LOADS=0')
$Lines.Add('MMIO_READS=0')
$Lines.Add('MMIO_WRITES=0')
$Lines.Add('DMA_TRANSFERS=0')
[IO.File]::WriteAllLines($LogPath,$Lines,[Text.UTF8Encoding]::new($false))
$Lines
if($Failed.Count){exit 1}
