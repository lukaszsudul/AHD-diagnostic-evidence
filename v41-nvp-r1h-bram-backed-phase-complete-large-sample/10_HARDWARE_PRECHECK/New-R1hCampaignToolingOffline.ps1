[CmdletBinding()]
param()

# Offline-only deterministic adapter.  It reads and hash-gates the accepted
# R1g/R7/R6 tooling, then writes task-local R1h wrappers and frozen contracts.
# It never launches Vivado, SSH/plink, JTAG, a host command, MMIO, programming,
# a reboot, a driver loader, or DMA.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$TaskRoot = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$ToolRoot = Join-Path $TaskRoot '09_HOST_TOOLS'
$PrecheckRoot = Join-Path $TaskRoot '10_HARDWARE_PRECHECK'
$R1gTaskRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY'
$R1hWorktree = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$R7TaskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$FrozenRoot = Join-Path $ToolRoot 'frozen_r1f_host_tools'

function Assert-ExactFile {
    param([string]$Path,[long]$Bytes,[string]$Sha256)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "missing exact input: $Path" }
    $item = Get-Item -LiteralPath $Path
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    if ($item.Length -ne $Bytes -or $actual -cne $Sha256) {
        throw "exact-input gate failed: $Path bytes=$($item.Length)/$Bytes sha=$actual/$Sha256"
    }
}

function Write-NewUtf8 {
    param([string]$Path,[string]$Text)
    if (Test-Path -LiteralPath $Path) { throw "refusing to overwrite generated R1h tooling: $Path" }
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    [IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false))
}

function Adapt-R1gText {
    param([string]$Text)
    return $Text.Replace('C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY',$TaskRoot).
        Replace('C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY',$R1hWorktree).
        Replace('/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/','/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/').
        Replace('R1g','R1h').Replace('R1G','R1H').Replace('r1g','r1h')
}

$WrapperInputs = [ordered]@{
    '09_HOST_TOOLS\Initialize-R1gCampaignEvidenceDirectories.ps1' = @('96BFACF5A9397EE166A16FDB3D98A07C618AB5805903BBECD5DA414158D3416D',1087,'09_HOST_TOOLS\Initialize-R1hCampaignEvidenceDirectories.ps1')
    '09_HOST_TOOLS\Invoke-R1gHostStep.ps1' = @('734BD5D967F125B09EE89AFAC781240750F20568DA58783C9D5F069A8A75E81E',11053,'09_HOST_TOOLS\Invoke-R1hHostStep.ps1')
    '09_HOST_TOOLS\Invoke-R1gIndependentDoneReadOnly.ps1' = @('472E0E97820C51D1FA0593C6C2F230DFAA795B2C3865242C6C1F4724A7AEEE9F',7553,'09_HOST_TOOLS\Invoke-R1hIndependentDoneReadOnly.ps1')
    '09_HOST_TOOLS\Invoke-R1gProgramOnce.ps1' = @('A6CFFDBC3C8A6A652F9BD7AC17DFD0F3649FAA3BF76989CADDC98AB13A903DF2',15677,'09_HOST_TOOLS\Invoke-R1hProgramOnce.ps1')
    '09_HOST_TOOLS\Invoke-R1gTelemetryReadOnly.ps1' = @('E1D7BFB1B408829881E0EB9320F181C5DF6476AE7661F4563E54C92C1CFA94DD',4486,'09_HOST_TOOLS\Invoke-R1hTelemetryReadOnly.ps1')
    '09_HOST_TOOLS\New-R1gConfiguredImageReceipt.ps1' = @('7090DD0454EA8E5B7B9AEF94AF874D39DF5B3EED7375D666999BBFBD11CF8DEA',6406,'09_HOST_TOOLS\New-R1hConfiguredImageReceipt.ps1')
    '09_HOST_TOOLS\R1gCampaignCommon.ps1' = @('461A304EFD6650F8918C5E58B719616D01A1893024A074F73536EA9FC5403C68',15093,'09_HOST_TOOLS\R1hCampaignCommon.ps1')
    '09_HOST_TOOLS\Wait-R1gProgramMinimum.ps1' = @('4C4A70ED609F0668BEAC6E81E515E9C0BE7C1F1939174A77AD3AE687EDDCFF6F',4763,'09_HOST_TOOLS\Wait-R1hProgramMinimum.ps1')
    '10_HARDWARE_PRECHECK\Finalize-R1gFreshFormalStartGate.ps1' = @('56BA8F5AFCC770B761587C19CAFDDF0EDC92C20A64FD5E03F0139EF4F3D379FC',3209,'10_HARDWARE_PRECHECK\Finalize-R1hFreshFormalStartGate.ps1')
    '10_HARDWARE_PRECHECK\Invoke-R1gExistingFormalTelemetryReadOnly.ps1' = @('165D3BEDF4FF70DA6457788FA4C4E629F32A89B8C8CF733D506F228AE90C648F',2465,'10_HARDWARE_PRECHECK\Invoke-R1hExistingFormalTelemetryReadOnly.ps1')
    '10_HARDWARE_PRECHECK\Invoke-R1gHostBaselineReadOnly.ps1' = @('D806A91DB58C33BBE38636CAE9E19A183B7BDD9F475AB259D3B3A22BB160C555',5388,'10_HARDWARE_PRECHECK\Invoke-R1hHostBaselineReadOnly.ps1')
    '10_HARDWARE_PRECHECK\Invoke-R1gPrecheckJtagDoneReadOnly.ps1' = @('C2D03460C7F2806A4B1038E44A474EF5DC52A173F76367F5DBAC4E4896EEB633',5667,'10_HARDWARE_PRECHECK\Invoke-R1hPrecheckJtagDoneReadOnly.ps1')
    '10_HARDWARE_PRECHECK\Invoke-R1gStartSafetyReadOnly.ps1' = @('24BC76E6EDB98812D2F14BC81371003467194844632A4AE4B7DB40CAB715E6CA',6969,'10_HARDWARE_PRECHECK\Invoke-R1hStartSafetyReadOnly.ps1')
    '10_HARDWARE_PRECHECK\New-R1gExistingFormalStartReceipt.ps1' = @('602AFFCF4F69001D8AC24D97222DF6302BDD4657DB82D61626E05A2D950EA8EA',3028,'10_HARDWARE_PRECHECK\New-R1hExistingFormalStartReceipt.ps1')
}

$Adapted = [ordered]@{}
foreach ($entry in $WrapperInputs.GetEnumerator()) {
    $input = Join-Path $R1gTaskRoot $entry.Key
    Assert-ExactFile $input $entry.Value[1] $entry.Value[0]
    $Adapted[$entry.Value[2]] = Adapt-R1gText ([IO.File]::ReadAllText($input,[Text.UTF8Encoding]::new($false,$true)))
}

# Runtime provenance remains read-only, but its role and evidence labels become
# R1h.  Keep it in the task-local host-tool directory so no source-repository
# file is created or changed by this offline preparation.
$RuntimeInput = Join-Path $R1gTaskRoot 'scripts\r1g_runtime_provenance_readonly.sh'
Assert-ExactFile $RuntimeInput 3247 '8F8C0D31691BB5866BD86369DB28A9B9B12EDA498D2AFCB0C539D6E826F1A4F5'
$RuntimeText = Adapt-R1gText ([IO.File]::ReadAllText($RuntimeInput,[Text.UTF8Encoding]::new($false,$true)))
$RuntimeText = $RuntimeText.Replace('It has no MMIO, PCIe, driver,','It has no MMIO-write, PCIe-state-change, driver,')
$RuntimeBytes = [Text.UTF8Encoding]::new($false).GetBytes($RuntimeText)
$RuntimeSha = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($RuntimeBytes))
$RuntimeOutput = Join-Path $ToolRoot 'r1h_runtime_provenance_readonly.sh'
Write-NewUtf8 $RuntimeOutput $RuntimeText

# Point the common library at the task-local runtime leaf and hash-gate it.
$CommonKey = '09_HOST_TOOLS\R1hCampaignCommon.ps1'
$Common = $Adapted[$CommonKey]
$Common = $Common.Replace("Path = Join-Path `$script:R1hTaskRoot 'scripts\r1h_runtime_provenance_readonly.sh'","Path = Join-Path `$script:R1hToolRoot 'r1h_runtime_provenance_readonly.sh'")
$Common = $Common.Replace('Bytes = 3247L',"Bytes = $($RuntimeBytes.Length)L")
$Common = $Common.Replace('8F8C0D31691BB5866BD86369DB28A9B9B12EDA498D2AFCB0C539D6E826F1A4F5',$RuntimeSha)

$WaitNeedle = @'
    [double]$wait = [double]$document.r1hBit.requiredWaitSeconds
    if ([Math]::Abs($wait - 33.536673744) -gt 0.000000000001) {
        throw 'frozen R1h Arm-A wait is not exactly 33.536673744 seconds'
    }
    return $document
'@
$WaitInsert = @'
    if ([string]$document.formalBit.filename -cne 'ahd_capture_v41_phase2_p1.bit' -or
        [long]$document.formalBit.bytes -ne 2192144L -or
        [string]$document.formalBit.sha256 -cne '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2' -or
        [string]$document.formalBit.sourceCommit -cne 'c89e88bcdf389614c884fb129e8b2d42a585bccb' -or
        [string]$document.formalBit.sourceTree -cne '417820c69c134161fcafae0947dc5976919814d1') {
        throw 'exact formal Phase-2 identity binding mismatch'
    }
    [double]$modeled = [double]$document.r1hBit.modeledProbeCompleteSeconds
    [double]$wait = [double]$document.r1hBit.requiredWaitSeconds
    if ($modeled -lt 0.0 -or $modeled + 2.0 -gt 33.536673744) {
        throw 'modeled R1h probe completion plus two seconds exceeds the frozen Arm-A wait'
    }
    if ([Math]::Abs($wait - 33.536673744) -gt 0.000000000001) {
        throw 'frozen R1h Arm-A wait is not exactly 33.536673744 seconds'
    }
    return $document
'@
if ([regex]::Matches($Common,[regex]::Escape($WaitNeedle)).Count -ne 1) { throw 'R1h wait-contract insertion point mismatch' }
$Common = $Common.Replace($WaitNeedle,$WaitInsert)
$Adapted[$CommonKey] = $Common

# Freeze the seven R1h remote evidence-directory adaptations.  Only the path
# literal/list differs from the exact accepted R7 payloads.
$PreloaderSource = Join-Path $R7TaskRoot 'scripts\r7_post_reboot_preloader_readonly.sh'
$SafetySource = Join-Path $R7TaskRoot 'scripts\r7_prebootstrap_safety_readonly.sh'
Assert-ExactFile $PreloaderSource 7419 '21748CA9D698B2657862F8EB423DD00D9151A5FB501C18385B7F4B8470B3163D'
Assert-ExactFile $SafetySource 13540 'FC7868B7CD536A4F3C3D8365AA6950F8B76378687CEE6B8047DECDF2FD6FDB45'
$PreloaderText = [IO.File]::ReadAllText($PreloaderSource,[Text.UTF8Encoding]::new($false,$true))
$PhaseKinds = [ordered]@{
    Bootstrap=@('formal_bootstrap','bootstrap_driver'); A1=@('arm_a_r1e','a1_driver'); B1=@('arm_b_formal','b1_driver')
    A2=@('arm_a_r1e','a2_driver'); B2=@('arm_b_formal','b2_driver'); A3=@('arm_a_r1e','a3_driver'); B3=@('arm_b_formal','b3_driver')
}
$OldByKind = @{formal_bootstrap='/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/bootstrap_driver';arm_a_r1e='/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_a_driver';arm_b_formal='/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_b_driver'}
$R1gHashes = [ordered]@{Bootstrap='0A24E8A4367306705D08C9F499973890E70290505DE57F2D796B986B0BD85E64';A1='292FC3D84BFBC08C118F7FDDCD1C41F1130F032114066BE8F4956797EE2E4E73';B1='1029FE242F59ED373C198AC60CC0EBD7D38D1009E4149F08F05DC6AA1CBE7358';A2='0CE089EEF9BBC76CE20758D328B080187D074903D097BE114AA4CBB7505C109D';B2='160C5DA87E264FD54BD90BFD0AFEECDD2EF870DC1B1D0AD79B5BF47A8DBEFF3D';A3='C6B5F81692D4F7883B758072DAEF75B68B171D989A1B0D32502D2135930EF0FE';B3='32FBEACC85E185784F4FF3F6FB45DA011ECDE83CCCAA748BC53C6348ECA559DE'}
$R1hHashes = [ordered]@{}
foreach ($phase in $PhaseKinds.GetEnumerator()) {
    $old = $OldByKind[$phase.Value[0]]
    if ([regex]::Matches($PreloaderText,[regex]::Escape($old)).Count -ne 1) { throw "R7 preloader literal mismatch: $($phase.Key)" }
    $new = "/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/$($phase.Value[1])"
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($PreloaderText.Replace($old,$new))
    $R1hHashes[$phase.Key] = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
}
$HostStepKey = '09_HOST_TOOLS\Invoke-R1hHostStep.ps1'
foreach ($phase in $R1gHashes.Keys) { $Adapted[$HostStepKey] = $Adapted[$HostStepKey].Replace($R1gHashes[$phase],$R1hHashes[$phase]) }

$SafetyText = [IO.File]::ReadAllText($SafetySource,[Text.UTF8Encoding]::new($false,$true))
$start = $SafetyText.IndexOf('for evidence_dir in \',[StringComparison]::Ordinal)
$end = $SafetyText.IndexOf("`n`nmapfile -t xilinx_functions",$start,[StringComparison]::Ordinal)
if ($start -lt 0 -or $end -lt 0) { throw 'R7 safety directory block not found' }
$nl = if ($SafetyText.Contains("`r`n",[StringComparison]::Ordinal)) { "`r`n" } else { "`n" }
$dirs = @('bootstrap_driver','a1_driver','b1_driver','a2_driver','b2_driver','a3_driver','b3_driver') | ForEach-Object { "  /home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/$_" }
for ($i=0;$i -lt $dirs.Count-1;$i++) { $dirs[$i] += ' \' }
$block = 'for evidence_dir in \' + $nl + ($dirs -join $nl) + '; do' + $nl + '  [[ ! -e $evidence_dir ]] || fail DRIVER_EVIDENCE_DIRECTORY_NOT_FRESH 87' + $nl + '  printf ''FRESH_DRIVER_EVIDENCE_DIRECTORY=%s STATE=ABSENT_FRESH\n'' "$evidence_dir"' + $nl + 'done'
$SafetyAdapted = $SafetyText.Substring(0,$start) + $block + $SafetyText.Substring($end)
$SafetySha = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($SafetyAdapted)))
$SafetyKey = '10_HARDWARE_PRECHECK\Invoke-R1hStartSafetyReadOnly.ps1'
$Adapted[$SafetyKey] = $Adapted[$SafetyKey].Replace('05D01DF870B104C9870E5D670508ACF2CC8C5893F0C349F7C95342AFA7B45B5B',$SafetySha)

foreach ($entry in $Adapted.GetEnumerator()) { Write-NewUtf8 (Join-Path $TaskRoot $entry.Key) $entry.Value }

# Preserve byte-identical reader/statistics/fixtures under the task root.
$FrozenInputs = [ordered]@{
    'read_nvp_r1f.py'=@('5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C',46868)
    'r1f_statistics.py'=@('C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD',38404)
    'test_nvp_r1f_tools.py'=@('7AD2E8FA36D685CFC916B007A65BE9B807398A71CB6730E067C31CD9673C52B1',17276)
    'fixtures\r1f_valid_scenario.json'=@('8D6C63878488F79B1299F1AD2576EF830C52741F2938A9715EC597FBF4FAB1A8',899)
    'read_nvp_r1e.py'=@('0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037',8385)
}
foreach ($entry in $FrozenInputs.GetEnumerator()) {
    $source = Join-Path (Join-Path $R1gTaskRoot '09_HOST_TOOLS\frozen_r1f_host_tools') $entry.Key
    Assert-ExactFile $source $entry.Value[1] $entry.Value[0]
    $destination = Join-Path $FrozenRoot $entry.Key
    if (Test-Path -LiteralPath $destination) { throw "refusing to overwrite frozen host tool: $destination" }
    [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
    [IO.File]::WriteAllBytes($destination,[IO.File]::ReadAllBytes($source))
}

$BindingTemplate = @'
{
  "schemaVersion": 1,
  "status": "PENDING_R1H_BUILD",
  "selectedJtagCanonicalId": "Xilinx/80802026a98b01",
  "selectedFullJtagTargetPath": "PENDING_FRESH_DISCOVERY",
  "fpgaPart": "xc7a35t",
  "fpgaIdcode": "0362D093",
  "host": {"ip":"10.132.1.111","user":"vcdeagent1","kernel":"7.0.0-29-generic"},
  "driver": {
    "modulePath":"/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko",
    "moduleSha256":"1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A",
    "loaderPath":"/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh",
    "loaderSha256":"7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F"
  },
  "formalBit": {
    "path": "C:\\FPGA\\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\\01_ARTIFACT_IDENTITY\\artifacts\\ahd_capture_v41_phase2_p1.bit",
    "filename": "ahd_capture_v41_phase2_p1.bit",
    "bytes": 2192144,
    "sha256": "7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2",
    "sourceCommit": "c89e88bcdf389614c884fb129e8b2d42a585bccb",
    "sourceTree": "417820c69c134161fcafae0947dc5976919814d1",
    "requiredWaitSeconds": 5.0
  },
  "r1hBit": {
    "path": "PENDING_ONE_CLEAN_BUILD",
    "filename": "ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit",
    "bytes": 0,
    "sha256": "PENDING_ONE_CLEAN_BUILD",
    "sourceCommit": "PENDING_ONE_R1H_SOURCE_COMMIT",
    "sourceTree": "PENDING_ONE_R1H_SOURCE_COMMIT",
    "modeledProbeCompleteSeconds": "PENDING_POST_BUILD_TIMING_MODEL",
    "requiredWaitSeconds": 33.536673744
  },
  "r1hReader": {
    "path": "C:\\FPGA\\WORKTREES\\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\\scripts\\v41\\read_nvp_r1f.py",
    "bytes": 46868,
    "sha256": "5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C",
    "responseLatencyContract": "BLOCKING_PREAD_VARIABLE_LATENCY"
  },
  "r1hSourceCommit": "PENDING_ONE_R1H_SOURCE_COMMIT",
  "r1hSourceTree": "PENDING_ONE_R1H_SOURCE_COMMIT"
}
'@
Write-NewUtf8 (Join-Path $ToolRoot 'R1H_HARDWARE_BINDINGS.template.json') ($BindingTemplate.TrimStart())

$Sequence = @'
sequence,phase_token,image,local_evidence_directory,observer_mode,configured_receipt,minimum_wait_seconds,remote_driver_directory,program_max,reboot_max,driver_load_max,retry_max
0,Bootstrap,FORMAL,C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\11_BOOTSTRAP\FORMAL_BOOTSTRAP,BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM,NO_RECEIPT_REQUIRED,5.0,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/bootstrap_driver,1,1,1,0
1,A1,R1H,C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\12_PAIR_1\A1_R1H,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,FORMAL_READY_RECEIPT,33.536673744,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/a1_driver,1,1,1,0
2,B1,FORMAL,C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\12_PAIR_1\B1_FORMAL,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,VALID_ARM_A_OR_TERMINAL_SAFE_DONE1_RECEIPT,5.0,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/b1_driver,1,1,1,0
3,A2,R1H,C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\13_PAIR_2\A2_R1H,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,FORMAL_READY_RECEIPT,33.536673744,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/a2_driver,1,1,1,0
4,B2,FORMAL,C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\13_PAIR_2\B2_FORMAL,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,VALID_ARM_A_OR_TERMINAL_SAFE_DONE1_RECEIPT,5.0,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/b2_driver,1,1,1,0
5,A3,R1H,C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\14_PAIR_3\A3_R1H,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,FORMAL_READY_RECEIPT,33.536673744,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/a3_driver,1,1,1,0
6,B3,FORMAL,C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\14_PAIR_3\B3_FORMAL,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,VALID_ARM_A_OR_TERMINAL_SAFE_DONE1_RECEIPT,5.0,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/b3_driver,1,1,1,0
'@
Write-NewUtf8 (Join-Path $PrecheckRoot 'R1H_FROZEN_CAMPAIGN_SEQUENCE.csv') ($Sequence.TrimStart())

$GateTemplate = (Adapt-R1gText ([IO.File]::ReadAllText((Join-Path $R1gTaskRoot '10_HARDWARE_PRECHECK\R1G_FRESH_FORMAL_START_GATE.template.txt'))))
Write-NewUtf8 (Join-Path $PrecheckRoot 'R1H_FRESH_FORMAL_START_GATE.template.txt') $GateTemplate

$AdapterLines = [Collections.Generic.List[string]]::new()
$AdapterLines.Add('base_file,phase_token,adapter_class,base_sha256,adapted_sha256,old_literal_count,new_literal_count,semantic_change')
$AdapterLines.Add("r7_prebootstrap_safety_readonly.sh,START,REMOTE_EVIDENCE_DIRECTORY_BLOCK_ONLY,FC7868B7CD536A4F3C3D8365AA6950F8B76378687CEE6B8047DECDF2FD6FDB45,$SafetySha,3,7,NONE_OUTSIDE_FRESH_DIRECTORY_LIST")
foreach ($phase in $R1hHashes.Keys) { $AdapterLines.Add("r7_post_reboot_preloader_readonly.sh,$phase,REMOTE_EVIDENCE_DIRECTORY_LITERAL_ONLY,21748CA9D698B2657862F8EB423DD00D9151A5FB501C18385B7F4B8470B3163D,$($R1hHashes[$phase]),1,1,NONE_OUTSIDE_SELECTED_DIRECTORY_LITERAL") }
Write-NewUtf8 (Join-Path $PrecheckRoot 'R1H_REMOTE_DIRECTORY_ADAPTER_AUDIT.csv') (($AdapterLines -join "`r`n")+"`r`n")

$BindingRows = @(
    'name,path,bytes,sha256,reuse_class',
    'ModeAwareObserverTcl,C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\program_once_mode_aware.tcl,11334,55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7,EXACT_BYTE_IDENTICAL_LIVE_LEAF',
    'ProgramObserverParser,C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6\scripts\ProgramObserverCommon.ps1,5102,6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66,EXACT_BYTE_IDENTICAL_LIVE_LEAF',
    'SelectedTargetSelector,C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6\scripts\select_r6_jtag_target.tcl,5676,3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE,EXACT_BYTE_IDENTICAL_LIVE_LEAF',
    'IndependentDoneTcl,C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\read_jtag_identity_done_r7_selected.tcl,3527,122C960412B7A8ADFD2926BE9A863A2786D4D022854AE8A0D56798461E0CD91B,EXACT_BYTE_IDENTICAL_READ_ONLY_LEAF',
    'JtagReconfirmationTcl,C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\r7_jtag_reconfirmation_session.tcl,6368,6642F60F6D0FDF0208481C7A3CC25AC1127F981851BE7081CFFA3DF64860FF73,EXACT_BYTE_IDENTICAL_READ_ONLY_LEAF',
    'ContextualPlink,C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\Invoke-ContextualPlink.ps1,10952,5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9,EXACT_BYTE_IDENTICAL_CREDENTIAL_HOSTKEY_LEAF',
    'BarParser,C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\parse_pci_bars.py,3380,5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922,EXACT_BYTE_IDENTICAL_READ_ONLY_LEAF',
    'PreLoaderValidator,C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\r7_post_reboot_preloader_readonly.sh,7419,21748CA9D698B2657862F8EB423DD00D9151A5FB501C18385B7F4B8470B3163D,EXACT_SOURCE_WITH_R1H_REMOTE_DIRECTORY_LITERAL_ADAPTER',
    'PreBootstrapSafetyPayload,C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\r7_prebootstrap_safety_readonly.sh,13540,FC7868B7CD536A4F3C3D8365AA6950F8B76378687CEE6B8047DECDF2FD6FDB45,EXACT_SOURCE_WITH_R1H_REMOTE_DIRECTORY_BLOCK_ADAPTER',
    'HostBaselinePayload,C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\r7_host_baseline_sample_readonly.sh,3717,0C49C3FB9192E40F53285844343BAA7AC6EE1801798C62627A6C45EAC718D730,EXACT_BYTE_IDENTICAL_READ_ONLY_PAYLOAD',
    "R1hRuntimeProvenance,$RuntimeOutput,$($RuntimeBytes.Length),$RuntimeSha,TASK_LOCAL_READ_ONLY_VARIABLE_LATENCY_SOURCE_COMMIT_BUILD_FLAGS_AND_FORMAL_ZERO_SUPPLEMENT",
    'R1fReader,C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\scripts\v41\read_nvp_r1f.py,46868,5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C,EXACT_BYTE_IDENTICAL_BLOCKING_PREAD_VARIABLE_LATENCY_READER',
    'R1fStatistics,C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\scripts\v41\r1f_statistics.py,38404,C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD,EXACT_BYTE_IDENTICAL_FROZEN_STATISTICAL_PLAN',
    'Plink084,C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe,1043072,E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915,EXACT_BINARY'
)
Write-NewUtf8 (Join-Path $ToolRoot 'R1H_INHERITED_TOOL_BINDINGS.csv') (($BindingRows -join "`r`n")+"`r`n")

"GENERATED_R1H_WRAPPERS=$($Adapted.Count)"
"R1H_RUNTIME_PROVENANCE_SHA256=$RuntimeSha"
"R1H_PREBOOTSTRAP_ADAPTED_SHA256=$SafetySha"
foreach ($phase in $R1hHashes.Keys) { "R1H_PRELOADER_${phase}_ADAPTED_SHA256=$($R1hHashes[$phase])" }
'ACTIVE_SOURCE_COMMIT_BINDING=PENDING_ONE_R1H_SOURCE_COMMIT'
'ACTIVE_BIT_BINDING=PENDING_ONE_CLEAN_BUILD'
'LIVE_SSH_JTAG_VIVADO_MMIO_PROGRAM_REBOOT_DRIVER_ACTIONS=0'
