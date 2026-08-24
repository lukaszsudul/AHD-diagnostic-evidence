[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY'
$publishedR1f = 'C:\FPGA\EVIDENCE_WORKTREES\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1\v41-nvp-r1f-phase-complete-observability'
$r1fWorktree = 'C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY'
$r1gWorktree = 'C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY'
$toolRoot = Join-Path $taskRoot '09_HOST_TOOLS'
$precheckRoot = Join-Path $taskRoot '10_HARDWARE_PRECHECK'
$frozenRoot = Join-Path $toolRoot 'frozen_r1f_host_tools'

foreach ($directory in @($toolRoot,$precheckRoot,$frozenRoot)) {
    [IO.Directory]::CreateDirectory($directory) | Out-Null
}

function Assert-ExactFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][long]$Bytes,
        [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$Sha256
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "missing exact source file: $Path" }
    $item = Get-Item -LiteralPath $Path
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    if ($item.Length -ne $Bytes -or $hash -cne $Sha256) {
        throw "exact-file gate failed: $Path bytes=$($item.Length)/$Bytes sha=$hash/$Sha256"
    }
}

function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Text)
    [IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false))
}

$sources = [ordered]@{
    '08_HOST_TOOLS\Initialize-R1fCampaignEvidenceDirectories.ps1' = @('D44A398217A97884C205A389840B734E3E0ED5ABF42E05AD03A248B5EE08CBE4',1087,'09_HOST_TOOLS\Initialize-R1gCampaignEvidenceDirectories.ps1')
    '08_HOST_TOOLS\Invoke-R1fHostStep.ps1' = @('14DCB75B3252368B0BBA0A1AE166F5B69EEEB2DCF14D2D35CB47BD4AF7217627',11053,'09_HOST_TOOLS\Invoke-R1gHostStep.ps1')
    '08_HOST_TOOLS\Invoke-R1fIndependentDoneReadOnly.ps1' = @('E19DB5FD068CEA4CD4DEBF07487D3063ADC6950028517DDEFDC8E705959818D6',7553,'09_HOST_TOOLS\Invoke-R1gIndependentDoneReadOnly.ps1')
    '08_HOST_TOOLS\Invoke-R1fProgramOnce.ps1' = @('98FE27F476508124646E66B5654EADE6929C70810D67037550B07A906B9A5255',15677,'09_HOST_TOOLS\Invoke-R1gProgramOnce.ps1')
    '08_HOST_TOOLS\Invoke-R1fTelemetryReadOnly.ps1' = @('952011FAA90903AD149650B733FDE0D76EB271B02D14062EA9C093EBA0694311',2963,'09_HOST_TOOLS\Invoke-R1gTelemetryReadOnly.ps1')
    '08_HOST_TOOLS\New-R1fConfiguredImageReceipt.ps1' = @('5B2A98E35FEA3E04FD2BBFE7F85CBA73A7AF6EF454419A3987FDF2CE3E584760',5897,'09_HOST_TOOLS\New-R1gConfiguredImageReceipt.ps1')
    '08_HOST_TOOLS\R1fCampaignCommon.ps1' = @('EB1988A7CFA7F785F81A3D1BF83563375063700877988B62FB0A5CEC6D50F4A2',13857,'09_HOST_TOOLS\R1gCampaignCommon.ps1')
    '08_HOST_TOOLS\Wait-R1fProgramMinimum.ps1' = @('AEA9F35B6CA1E4A5A1F3536E187D50C9CC8199FCE8615135DE71ADB3715EC981',4763,'09_HOST_TOOLS\Wait-R1gProgramMinimum.ps1')
    '09_HARDWARE_PRECHECK\Finalize-R1fFreshFormalStartGate.ps1' = @('CA611D83B922C881E8CB94F4D1A483803785CDD1F5118D9EDB1B49A5330FDFBE',3219,'10_HARDWARE_PRECHECK\Finalize-R1gFreshFormalStartGate.ps1')
    '09_HARDWARE_PRECHECK\Invoke-R1fExistingFormalTelemetryReadOnly.ps1' = @('423F611557454B9F27445C74AE52BC670672044CB95AA0CB3BA6D9BCB8D2BEF2',2475,'10_HARDWARE_PRECHECK\Invoke-R1gExistingFormalTelemetryReadOnly.ps1')
    '09_HARDWARE_PRECHECK\Invoke-R1fHostBaselineReadOnly.ps1' = @('880F6C8361B6398923CAF511202D62D3896165FC55BF81C1BCD35C420899717E',5398,'10_HARDWARE_PRECHECK\Invoke-R1gHostBaselineReadOnly.ps1')
    '09_HARDWARE_PRECHECK\Invoke-R1fPrecheckJtagDoneReadOnly.ps1' = @('992AF76AD3D934308D35CCE874FAB0024B7AAEE8BAFC7917DF24D9B01B696A45',5677,'10_HARDWARE_PRECHECK\Invoke-R1gPrecheckJtagDoneReadOnly.ps1')
    '09_HARDWARE_PRECHECK\Invoke-R1fStartSafetyReadOnly.ps1' = @('CEEDBEA9C993D435354B6051775768E3BB2D62BD005B7F5D48E9FCB50CB4E64A',6979,'10_HARDWARE_PRECHECK\Invoke-R1gStartSafetyReadOnly.ps1')
    '09_HARDWARE_PRECHECK\New-R1fExistingFormalStartReceipt.ps1' = @('3E9703D07644E76A06E82AAECC37C1F6BB37083595AD5A99DE2F9A52F1F0C119',3038,'10_HARDWARE_PRECHECK\New-R1gExistingFormalStartReceipt.ps1')
}

$directoryRewrites = [ordered]@{
    '10_BOOTSTRAP\FORMAL_BOOTSTRAP' = '11_BOOTSTRAP\FORMAL_BOOTSTRAP'
    '11_PAIR_1\A1_R1F' = '12_PAIR_1\A1_R1G'
    '11_PAIR_1\B1_FORMAL' = '12_PAIR_1\B1_FORMAL'
    '12_PAIR_2\A2_R1F' = '13_PAIR_2\A2_R1G'
    '12_PAIR_2\B2_FORMAL' = '13_PAIR_2\B2_FORMAL'
    '13_PAIR_3\A3_R1F' = '14_PAIR_3\A3_R1G'
    '13_PAIR_3\B3_FORMAL' = '14_PAIR_3\B3_FORMAL'
}

$generated = [Collections.Generic.List[string]]::new()
foreach ($entry in $sources.GetEnumerator()) {
    $input = Join-Path $publishedR1f $entry.Key
    Assert-ExactFile -Path $input -Sha256 $entry.Value[0] -Bytes $entry.Value[1]
    $text = [IO.File]::ReadAllText($input,[Text.UTF8Encoding]::new($false,$true))
    $text = $text.Replace('C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY',$taskRoot)
    $text = $text.Replace($r1fWorktree,$r1gWorktree)
    foreach ($rewrite in $directoryRewrites.GetEnumerator()) {
        $text = $text.Replace($rewrite.Key,$rewrite.Value)
    }
    $text = $text.Replace('/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1f/','/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/')
    $text = $text.Replace('08_HOST_TOOLS','09_HOST_TOOLS').Replace('09_HARDWARE_PRECHECK','10_HARDWARE_PRECHECK')
    $text = $text.Replace('R1f','R1g').Replace('R1F','R1G').Replace('r1f','r1g')

    # The scientific register map and decoder remain R1f.  R1g changes only
    # source-language syntax, so the exact inherited reader still accepts the
    # image selector literal "r1f" and emits the R1F_READER_RESULT ABI.
    if ($entry.Key -ceq '08_HOST_TOOLS\Invoke-R1fTelemetryReadOnly.ps1') {
        $text = $text.Replace("`$expect=if(`$phase.Image-ceq'R1G'){'r1g'}else{'formal'}","`$expect=if(`$phase.Image-ceq'R1G'){'r1f'}else{'formal'}")
    }

    # Arm-A's model-derived floor is frozen by the R1g owner prompt.
    if ($entry.Key -ceq '08_HOST_TOOLS\R1fCampaignCommon.ps1') {
        $text = $text.Replace("ReceiptType = 'FORMAL_READY_RECEIPT'; RequiredWaitFloorSeconds = 10.0","ReceiptType = 'FORMAL_READY_RECEIPT'; RequiredWaitFloorSeconds = 33.536673744")
        $text = $text.Replace("if (`$wait -lt 10.0) { throw 'frozen R1g Arm-A wait is below the mandatory 10-second floor' }","if (`$wait -lt 33.536673744) { throw 'frozen R1g Arm-A wait is below 33.536673744 seconds' }")
    }

    $output = Join-Path $taskRoot $entry.Value[2]
    Write-Utf8NoBom -Path $output -Text $text
    $generated.Add($output)
}

# Bind the task-local supplementary read-only runtime-provenance leaf.  The
# inherited R1f full decoder intentionally preserves the R1f register ABI, but
# it does not compare the runtime Git words to the R1g child commit.  This leaf
# adds that read-only comparison without changing the scientific decoder.
$runtimeLeaf = Join-Path $taskRoot 'scripts\r1g_runtime_provenance_readonly.sh'
Assert-ExactFile -Path $runtimeLeaf -Bytes 3247 -Sha256 '8F8C0D31691BB5866BD86369DB28A9B9B12EDA498D2AFCB0C539D6E826F1A4F5'
$commonPath = Join-Path $toolRoot 'R1gCampaignCommon.ps1'
$commonText = [IO.File]::ReadAllText($commonPath)
$commonNeedle = @'
    Plink084 = [pscustomobject]@{
'@
$commonInsert = @'
    RuntimeProvenancePayload = [pscustomobject]@{
        Path = Join-Path $script:R1gTaskRoot 'scripts\r1g_runtime_provenance_readonly.sh'
        Bytes = 3247L
        Sha256 = '8F8C0D31691BB5866BD86369DB28A9B9B12EDA498D2AFCB0C539D6E826F1A4F5'
    }
    Plink084 = [pscustomobject]@{
'@
if ([regex]::Matches($commonText,[regex]::Escape($commonNeedle)).Count -ne 1) { throw 'common runtime-leaf insertion point mismatch' }
$commonText = $commonText.Replace($commonNeedle,$commonInsert)

# Active hardware bindings must bind the exact R1g source words used by the
# bitstream as well as the immutable R1f scientific reader.
$bindingNeedle = @'
    [double]$wait = [double]$document.r1gBit.requiredWaitSeconds
    if ($wait -lt 33.536673744) { throw 'frozen R1g Arm-A wait is below 33.536673744 seconds' }
    return $document
'@
$bindingInsert = @'
    if ([string]$document.r1gSourceCommit -notmatch '^[0-9a-f]{40}$' -or
        [string]$document.r1gSourceTree -notmatch '^[0-9a-f]{40}$') {
        throw 'R1g source commit/tree binding is unresolved'
    }
    if ([string]$document.r1gBit.sourceCommit -cne [string]$document.r1gSourceCommit -or
        [string]$document.r1gBit.sourceTree -cne [string]$document.r1gSourceTree) {
        throw 'R1g bit/source provenance fields disagree'
    }
    if ([string]$document.r1gBit.filename -cne 'ahd_capture_v41_i2c_25khz_r1g_phase_complete_observability.bit' -or
        [long]$document.r1gBit.bytes -ne 2192144L) {
        throw 'R1g bit filename/byte-count binding mismatch'
    }
    if ([string]$document.r1gReader.sha256 -cne '5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C' -or
        [long]$document.r1gReader.bytes -ne 46868L) {
        throw 'exact inherited R1f reader identity mismatch'
    }
    [double]$wait = [double]$document.r1gBit.requiredWaitSeconds
    if ([Math]::Abs($wait - 33.536673744) -gt 0.000000000001) {
        throw 'frozen R1g Arm-A wait is not exactly 33.536673744 seconds'
    }
    return $document
'@
if ([regex]::Matches($commonText,[regex]::Escape($bindingNeedle)).Count -ne 1) { throw 'common binding-contract insertion point mismatch' }
$commonText = $commonText.Replace($bindingNeedle,$bindingInsert)
Write-Utf8NoBom -Path $commonPath -Text $commonText

$telemetryPath = Join-Path $toolRoot 'Invoke-R1gTelemetryReadOnly.ps1'
$telemetryText = [IO.File]::ReadAllText($telemetryPath)
$telemetryNeedle = @'
$output=Join-Path $directory 'TELEMETRY_EVIDENCE.log'
if(Test-Path -LiteralPath $output){throw 'refusing to overwrite telemetry evidence'}
$readerPath=[string]$binding.r1gReader.path
'@
$telemetryInsert = @'
$output=Join-Path $directory 'TELEMETRY_EVIDENCE.log'
$runtimeOutput=Join-Path $directory 'RUNTIME_PROVENANCE_EVIDENCE.log'
foreach($fresh in @($output,$runtimeOutput)){if(Test-Path -LiteralPath $fresh){throw "refusing to overwrite telemetry/provenance evidence: $fresh"}}
$runtimePayload=ConvertTo-GzipBase64([IO.File]::ReadAllBytes($script:R1gAcceptedTools.RuntimeProvenancePayload.Path))
$runtimeRole=if($phase.Image-ceq'R1G'){'r1g'}else{'formal'}
$runtimeCommit=if($phase.Image-ceq'R1G'){[string]$binding.r1gSourceCommit}else{'NOT_APPLICABLE'}
$runtimeTemplate='sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2" "$3" /dev/xdma0_user'' _ ''{0}'' ''{1}'' ''{2}'''
$runtimeRemote=$runtimeTemplate -f $runtimePayload,$runtimeRole,$runtimeCommit
$helper=$script:R1gAcceptedTools.ContextualPlink.Path
&$helper -PlinkPath $script:R1gAcceptedTools.Plink084.Path -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $runtimeRemote -EvidencePath $runtimeOutput -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
    -EvidenceKind("R1G_RUNTIME_PROVENANCE_{0}_{1}"-f$PhaseToken,$runtimeRole.ToUpperInvariant()) -SendPasswordToStdin -SudoPasswordCopies 1 -TimeoutSeconds 180
if($LASTEXITCODE-ne0){exit $LASTEXITCODE}
$runtimeText=[IO.File]::ReadAllText($runtimeOutput)
foreach($required in @('RESULT=PASS','EXIT_CODE=0','RUNTIME_PROVENANCE_GATE=PASS','MMIO_ACCESS=READ_ONLY','AXI_LITE_WRITES=0','C2H_TRANSFERS=0','H2C_TRANSFERS=0')) {
    if(-not$runtimeText.Contains($required,[StringComparison]::Ordinal)){throw "runtime provenance contract missing $required"}
}
$readerPath=[string]$binding.r1gReader.path
'@
if ([regex]::Matches($telemetryText,[regex]::Escape($telemetryNeedle)).Count -ne 1) { throw 'telemetry runtime-provenance insertion point mismatch' }
$telemetryText = $telemetryText.Replace($telemetryNeedle,$telemetryInsert)
Write-Utf8NoBom -Path $telemetryPath -Text $telemetryText

$receiptPath = Join-Path $toolRoot 'New-R1gConfiguredImageReceipt.ps1'
$receiptText = [IO.File]::ReadAllText($receiptPath)
$receiptNeedle = @'
    $loader=Join-Path $directory 'LOADER_EVIDENCE.log'
    $telemetry=Join-Path $directory 'TELEMETRY_EVIDENCE.log'
    $finalDone=Join-Path $directory 'FINAL_DONE_RECEIPT.txt'
'@
$receiptInsert = @'
    $loader=Join-Path $directory 'LOADER_EVIDENCE.log'
    $runtimeProvenance=Join-Path $directory 'RUNTIME_PROVENANCE_EVIDENCE.log'
    $telemetry=Join-Path $directory 'TELEMETRY_EVIDENCE.log'
    $finalDone=Join-Path $directory 'FINAL_DONE_RECEIPT.txt'
'@
if ([regex]::Matches($receiptText,[regex]::Escape($receiptNeedle)).Count -ne 1) { throw 'receipt runtime-provenance path insertion mismatch' }
$receiptText = $receiptText.Replace($receiptNeedle,$receiptInsert)
$receiptText = $receiptText.Replace(
    "    Require-ExactLine `$telemetry RESULT PASS",
    "    Require-ExactLine `$runtimeProvenance RESULT PASS`r`n    Require-ExactLine `$runtimeProvenance EXIT_CODE 0`r`n    Require-ExactLine `$runtimeProvenance RUNTIME_PROVENANCE_GATE PASS`r`n    Require-ExactLine `$runtimeProvenance MMIO_ACCESS READ_ONLY`r`n    Require-ExactLine `$telemetry RESULT PASS")
$receiptText = $receiptText.Replace(
    'LOADER=$loader;TELEMETRY=$telemetry',
    'LOADER=$loader;RUNTIME_PROVENANCE=$runtimeProvenance;TELEMETRY=$telemetry')
$receiptText = $receiptText.Replace(
    '        $lines.Add("R1G_BIT_SHA256=$([string]$binding.r1gBit.sha256)")',
    '        $lines.Add("R1G_BIT_SHA256=$([string]$binding.r1gBit.sha256)")' + "`r`n" +
    '        $lines.Add("R1G_SOURCE_COMMIT=$([string]$binding.r1gSourceCommit)")' + "`r`n" +
    '        $lines.Add("R1G_SOURCE_TREE=$([string]$binding.r1gSourceTree)")')
Write-Utf8NoBom -Path $receiptPath -Text $receiptText

# Freeze the directory-only adapter hashes for the R1g remote evidence root.
$preloaderSource = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\r7_post_reboot_preloader_readonly.sh'
Assert-ExactFile -Path $preloaderSource -Bytes 7419 -Sha256 '21748CA9D698B2657862F8EB423DD00D9151A5FB501C18385B7F4B8470B3163D'
$preloaderText = [IO.File]::ReadAllText($preloaderSource,[Text.UTF8Encoding]::new($false,$true))
$phaseKinds = [ordered]@{
    Bootstrap = @('formal_bootstrap','bootstrap_driver')
    A1 = @('arm_a_r1e','a1_driver')
    B1 = @('arm_b_formal','b1_driver')
    A2 = @('arm_a_r1e','a2_driver')
    B2 = @('arm_b_formal','b2_driver')
    A3 = @('arm_a_r1e','a3_driver')
    B3 = @('arm_b_formal','b3_driver')
}
$oldByKind = @{
    formal_bootstrap = '/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/bootstrap_driver'
    arm_a_r1e = '/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_a_driver'
    arm_b_formal = '/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_b_driver'
}
$preloaderHashes = [ordered]@{}
foreach ($phase in $phaseKinds.GetEnumerator()) {
    $old = $oldByKind[$phase.Value[0]]
    $new = "/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/$($phase.Value[1])"
    if ([regex]::Matches($preloaderText,[regex]::Escape($old)).Count -ne 1) { throw "preloader source literal mismatch for $($phase.Key)" }
    $adapted = $preloaderText.Replace($old,$new)
    $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($adapted)))
    $preloaderHashes[$phase.Key] = $hash
}
$hostStepPath = Join-Path $toolRoot 'Invoke-R1gHostStep.ps1'
$hostStepText = [IO.File]::ReadAllText($hostStepPath)
$oldPreloaderHashes = [ordered]@{
    Bootstrap='19CF42DE01F485321197ADEB829C92B433CB177C268CCE26DB98221218AD139E'
    A1='86A64AE776F8DF340863B720AE92F6DDBDC7C88122864CF25FA2766679469D76'
    B1='C2C7AEA6D1EE19FDD48D462053C5F88586B88798A19FC28CF1C9F4416F40F4F0'
    A2='F26CE0E89ABFE64BEA3A4404F9ACBFA49FAE67B09FFD0C3CF310D9001069B495'
    B2='4F4B5DDB044CA590ECF6B4AF3FBBEFAE22ABDB392C573B91155E2F950A96F130'
    A3='0725C79101F32DFB510D2DEDB130DB9331587472E5FEB04D7264F174DAD8CF0B'
    B3='E81E319C061BD846B55283D0894F74D870A8C3514C46651A4C2E93819C367B05'
}
foreach ($phase in $oldPreloaderHashes.Keys) {
    $hostStepText = $hostStepText.Replace($oldPreloaderHashes[$phase],$preloaderHashes[$phase])
}
Write-Utf8NoBom -Path $hostStepPath -Text $hostStepText

$safetySource = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\r7_prebootstrap_safety_readonly.sh'
Assert-ExactFile -Path $safetySource -Bytes 13540 -Sha256 'FC7868B7CD536A4F3C3D8365AA6950F8B76378687CEE6B8047DECDF2FD6FDB45'
$safetySourceText = [IO.File]::ReadAllText($safetySource,[Text.UTF8Encoding]::new($false,$true))
$startMarker = 'for evidence_dir in \'
$start = $safetySourceText.IndexOf($startMarker,[StringComparison]::Ordinal)
$endMarker = "`n`nmapfile -t xilinx_functions"
$end = $safetySourceText.IndexOf($endMarker,$start,[StringComparison]::Ordinal)
if ($start -lt 0 -or $end -lt 0) { throw 'prebootstrap evidence-directory block not found' }
$nl = if ($safetySourceText.Contains("`r`n",[StringComparison]::Ordinal)) { "`r`n" } else { "`n" }
$remoteDirs = @('bootstrap_driver','a1_driver','b1_driver','a2_driver','b2_driver','a3_driver','b3_driver') | ForEach-Object { "  /home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/$_" }
for ($i=0;$i -lt $remoteDirs.Count-1;$i++) { $remoteDirs[$i] += ' \' }
$newBlock = 'for evidence_dir in \' + $nl + ($remoteDirs -join $nl) + '; do' + $nl + '  [[ ! -e $evidence_dir ]] || fail DRIVER_EVIDENCE_DIRECTORY_NOT_FRESH 87' + $nl + '  printf ''FRESH_DRIVER_EVIDENCE_DIRECTORY=%s STATE=ABSENT_FRESH\n'' "$evidence_dir"' + $nl + 'done'
$safetyAdapted = $safetySourceText.Substring(0,$start) + $newBlock + $safetySourceText.Substring($end)
$safetyHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($safetyAdapted)))
$startSafetyPath = Join-Path $precheckRoot 'Invoke-R1gStartSafetyReadOnly.ps1'
$startSafetyText = [IO.File]::ReadAllText($startSafetyPath).Replace('98B776EDF8FEDD8638F71FCAF908D797EF3218938CF79B83A1DFBD6BF0B3EE05',$safetyHash)
Write-Utf8NoBom -Path $startSafetyPath -Text $startSafetyText

$adapterLines = [Collections.Generic.List[string]]::new()
$adapterLines.Add('base_file,phase_token,adapter_class,base_sha256,adapted_sha256,old_literal_count,new_literal_count,semantic_change')
$adapterLines.Add("r7_prebootstrap_safety_readonly.sh,START,REMOTE_EVIDENCE_DIRECTORY_BLOCK_ONLY,FC7868B7CD536A4F3C3D8365AA6950F8B76378687CEE6B8047DECDF2FD6FDB45,$safetyHash,3,7,NONE_OUTSIDE_FRESH_DIRECTORY_LIST")
foreach ($phase in $phaseKinds.Keys) {
    $adapterLines.Add("r7_post_reboot_preloader_readonly.sh,$phase,REMOTE_EVIDENCE_DIRECTORY_LITERAL_ONLY,21748CA9D698B2657862F8EB423DD00D9151A5FB501C18385B7F4B8470B3163D,$($preloaderHashes[$phase]),1,1,NONE_OUTSIDE_SELECTED_DIRECTORY_LITERAL")
}
[IO.File]::WriteAllLines((Join-Path $precheckRoot 'R1G_REMOTE_DIRECTORY_ADAPTER_AUDIT.csv'),$adapterLines,[Text.UTF8Encoding]::new($false))

# Preserve exact accepted scientific readers, statistical plan implementation,
# and their primary fixtures as byte-identical evidence-local copies.
$frozenFiles = [ordered]@{
    (Join-Path $r1fWorktree 'scripts\v41\read_nvp_r1f.py') = @('5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C',46868,'read_nvp_r1f.py')
    (Join-Path $r1fWorktree 'scripts\v41\r1f_statistics.py') = @('C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD',38404,'r1f_statistics.py')
    (Join-Path $r1fWorktree 'tests\python\test_nvp_r1f_tools.py') = @('7AD2E8FA36D685CFC916B007A65BE9B807398A71CB6730E067C31CD9673C52B1',17276,'test_nvp_r1f_tools.py')
    (Join-Path $r1fWorktree 'tests\python\fixtures\r1f_valid_scenario.json') = @('8D6C63878488F79B1299F1AD2576EF830C52741F2938A9715EC597FBF4FAB1A8',899,'fixtures\r1f_valid_scenario.json')
    (Join-Path $r1fWorktree 'scripts\v41\read_nvp_r1e.py') = @('0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037',8385,'read_nvp_r1e.py')
}
$frozenManifest = [Collections.Generic.List[string]]::new()
foreach ($entry in $frozenFiles.GetEnumerator()) {
    Assert-ExactFile -Path $entry.Key -Sha256 $entry.Value[0] -Bytes $entry.Value[1]
    $destination = Join-Path $frozenRoot $entry.Value[2]
    [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
    [IO.File]::WriteAllBytes($destination,[IO.File]::ReadAllBytes($entry.Key))
    $manifestName = ([string]$entry.Value[2]).Replace('\','/')
    $frozenManifest.Add("$($entry.Value[0])  $($entry.Value[1])  09_HOST_TOOLS/frozen_r1f_host_tools/$manifestName")
}
[IO.File]::WriteAllLines((Join-Path $toolRoot 'R1G_FROZEN_R1F_HOST_TOOL_SHA256.txt'),$frozenManifest,[Text.UTF8Encoding]::new($false))

$template = @'
{
  "schemaVersion": 1,
  "status": "PENDING_R1G_BUILD",
  "selectedJtagCanonicalId": "Xilinx/80802026a98b01",
  "selectedFullJtagTargetPath": "PENDING_FRESH_DISCOVERY",
  "fpgaPart": "xc7a35t",
  "fpgaIdcode": "0362D093",
  "formalBit": {
    "path": "C:\\FPGA\\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\\01_ARTIFACT_IDENTITY\\artifacts\\ahd_capture_v41_phase2_p1.bit",
    "filename": "ahd_capture_v41_phase2_p1.bit",
    "bytes": 2192144,
    "sha256": "7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2",
    "sourceCommit": "c89e88bcdf389614c884fb129e8b2d42a585bccb",
    "sourceTree": "417820c69c134161fcafae0947dc5976919814d1",
    "requiredWaitSeconds": 5.0
  },
  "r1gBit": {
    "path": "PENDING_ONE_CLEAN_BUILD",
    "filename": "ahd_capture_v41_i2c_25khz_r1g_phase_complete_observability.bit",
    "bytes": 0,
    "sha256": "PENDING_ONE_CLEAN_BUILD",
    "sourceCommit": "PENDING_ONE_R1G_SOURCE_COMMIT",
    "sourceTree": "PENDING_ONE_R1G_SOURCE_COMMIT",
    "requiredWaitSeconds": 33.536673744
  },
  "r1gReader": {
    "path": "C:\\FPGA\\WORKTREES\\V41_NVP_R1G_VHDL_COMPATIBILITY\\scripts\\v41\\read_nvp_r1f.py",
    "bytes": 46868,
    "sha256": "5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C"
  },
  "r1gSourceCommit": "PENDING_ONE_R1G_SOURCE_COMMIT",
  "r1gSourceTree": "PENDING_ONE_R1G_SOURCE_COMMIT"
}
'@
Write-Utf8NoBom -Path (Join-Path $toolRoot 'R1G_HARDWARE_BINDINGS.template.json') -Text ($template.TrimStart())

$sequence = @'
sequence,phase_token,image,local_evidence_directory,observer_mode,configured_receipt,minimum_wait_seconds,remote_driver_directory,program_max,reboot_max,driver_load_max
0,Bootstrap,FORMAL,C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\11_BOOTSTRAP\FORMAL_BOOTSTRAP,BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM,NO_RECEIPT_REQUIRED,5.0,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/bootstrap_driver,1,1,1
1,A1,R1G,C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\12_PAIR_1\A1_R1G,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,FORMAL_READY_RECEIPT,33.536673744,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/a1_driver,1,1,1
2,B1,FORMAL,C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\12_PAIR_1\B1_FORMAL,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,VALID_ARM_A_OR_TERMINAL_SAFE_DONE1_RECEIPT,5.0,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/b1_driver,1,1,1
3,A2,R1G,C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\13_PAIR_2\A2_R1G,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,FORMAL_READY_RECEIPT,33.536673744,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/a2_driver,1,1,1
4,B2,FORMAL,C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\13_PAIR_2\B2_FORMAL,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,VALID_ARM_A_OR_TERMINAL_SAFE_DONE1_RECEIPT,5.0,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/b2_driver,1,1,1
5,A3,R1G,C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\14_PAIR_3\A3_R1G,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,FORMAL_READY_RECEIPT,33.536673744,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/a3_driver,1,1,1
6,B3,FORMAL,C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\14_PAIR_3\B3_FORMAL,TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE,VALID_ARM_A_OR_TERMINAL_SAFE_DONE1_RECEIPT,5.0,/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/b3_driver,1,1,1
'@
Write-Utf8NoBom -Path (Join-Path $precheckRoot 'R1G_FROZEN_CAMPAIGN_SEQUENCE.csv') -Text ($sequence.TrimStart())

"GENERATED_R1G_CAMPAIGN_FILES=$($generated.Count)"
"R1G_PREBOOTSTRAP_ADAPTED_SHA256=$safetyHash"
foreach ($phase in $preloaderHashes.Keys) { "R1G_PRELOADER_${phase}_ADAPTED_SHA256=$($preloaderHashes[$phase])" }
'LIVE_SSH_JTAG_VIVADO_MMIO_PROGRAM_REBOOT_DRIVER_ACTIONS=0'
