[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken,
    [Parameter(Mandatory)][ValidateSet('WarmReboot','WaitHostCycle','PreLoaderValidate','ExactDriverLoad')][string]$Step,
    [Parameter(Mandatory)][string]$BindingPath,
    [ValidatePattern('^$|^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$PreviousBootId = '',
    [ValidateRange(30,600)][int]$TimeoutSeconds = 300,
    [ValidateRange(100,5000)][int]$PollMilliseconds = 1000
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'R1gCampaignCommon.ps1')

$binding = Get-R1gBindingDocument -BindingPath $BindingPath
Assert-R1gAcceptedToolSet
$phase = Get-R1gPhaseSpec $PhaseToken
$phaseDirectory = Assert-R1gPhaseDirectory $phase
$helperPath = $script:R1gAcceptedTools.ContextualPlink.Path
$plinkPath = $script:R1gAcceptedTools.Plink084.Path
$barParserPath = $script:R1gAcceptedTools.BarParser.Path
$preLoaderPath = $script:R1gAcceptedTools.PreLoaderValidator.Path
$hostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
$moduleSha = '1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A'
$loaderSha = '7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F'

function ConvertTo-GzipBase64([byte[]]$Bytes) {
    $output = [IO.MemoryStream]::new()
    try {
        $gzip = [IO.Compression.GzipStream]::new($output,[IO.Compression.CompressionLevel]::Optimal,$true)
        try { $gzip.Write($Bytes,0,$Bytes.Length) } finally { $gzip.Dispose() }
        return [Convert]::ToBase64String($output.ToArray())
    } finally { $output.Dispose() }
}

function Require-ExactLine([string]$Path,[string]$Key,[string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "required predecessor evidence absent: $Path" }
    $text = [IO.File]::ReadAllText($Path)
    $matches = [regex]::Matches($text,'(?m)^' + [regex]::Escape($Key) + '=' + [regex]::Escape($Expected) + '\r?$')
    if ($matches.Count -ne 1) { throw "$Key=$Expected exact-line count is $($matches.Count), expected 1 in $Path" }
}

function Test-Tcp22 {
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $task = $client.ConnectAsync('10.132.1.111',22)
        if (-not $task.Wait([Math]::Min($PollMilliseconds,5000))) { return $false }
        if ($task.IsFaulted) { return $false }
        return $client.Connected
    } catch { return $false } finally { $client.Dispose() }
}

$outputPath = switch ($Step) {
    'WarmReboot' { Join-Path $phaseDirectory 'WARM_REBOOT_EVIDENCE.log' }
    'WaitHostCycle' { Join-Path $phaseDirectory 'HOST_CYCLE_RECEIPT.txt' }
    'PreLoaderValidate' { Join-Path $phaseDirectory 'PRELOADER_EVIDENCE.log' }
    'ExactDriverLoad' { Join-Path $phaseDirectory 'LOADER_EVIDENCE.log' }
}
if (Test-Path -LiteralPath $outputPath) { throw "one-shot host-step evidence already exists: $outputPath" }

switch ($Step) {
    'WarmReboot' {
        $existing = @(Get-ChildItem -LiteralPath $script:R1gTaskRoot -Filter WARM_REBOOT_EVIDENCE.log -File -Recurse -ErrorAction SilentlyContinue)
        if ($existing.Count -ge $script:R1gMaximumWarmReboots) { throw 'warm-reboot maximum already reached' }
        Require-ExactLine (Join-Path $phaseDirectory 'PROGRAM_WAIT_RECEIPT.txt') WAIT_GATE PASS
        # Exactly one state-changing command; there is no retry or polling loop.
        $remoteCommand = "sudo -S -k -p '' /usr/sbin/reboot"
        & $helperPath -PlinkPath $plinkPath -HostKey $hostKey -RemoteCommand $remoteCommand `
            -EvidencePath $outputPath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
            -EvidenceKind ("R1G_WARM_REBOOT_{0}" -f $PhaseToken) -SendPasswordToStdin `
            -SudoPasswordCopies 1 -TimeoutSeconds 30
        exit $LASTEXITCODE
    }
    'WaitHostCycle' {
        Require-ExactLine (Join-Path $phaseDirectory 'WARM_REBOOT_EVIDENCE.log') RESULT PASS
        $startUtc=[DateTime]::UtcNow.ToString('o')
        $frequency=[Diagnostics.Stopwatch]::Frequency
        $startTicks=[Diagnostics.Stopwatch]::GetTimestamp()
        $deadline=$startTicks+[long]($TimeoutSeconds*$frequency)
        $records=[Collections.Generic.List[string]]::new()
        $downSeen=$false;$upAfterDown=$false;$sample=0
        while([Diagnostics.Stopwatch]::GetTimestamp()-lt$deadline) {
            $sample++;$tick=[Diagnostics.Stopwatch]::GetTimestamp();$up=Test-Tcp22
            $records.Add(('SAMPLE={0} TICK={1} TCP22={2}' -f $sample,$tick,$(if($up){'UP'}else{'DOWN'})))
            if(-not $downSeen -and -not $up){$downSeen=$true}
            elseif($downSeen -and $up){$upAfterDown=$true;break}
            Start-Sleep -Milliseconds $PollMilliseconds
        }
        $endTicks=[Diagnostics.Stopwatch]::GetTimestamp()
        $gate=if($downSeen -and $upAfterDown){'PASS_HOST_DISAPPEARED_AND_RETURNED'}else{'FAIL'}
        $lines=[Collections.Generic.List[string]]::new()
        foreach($line in @(
            "PHASE_TOKEN=$PhaseToken","UTC_START=$startUtc","UTC_END=$([DateTime]::UtcNow.ToString('o'))",
            "STOPWATCH_FREQUENCY=$frequency","START_TICKS=$startTicks","END_TICKS=$endTicks",
            "HOST_DOWN_OBSERVED=$(if($downSeen){'YES'}else{'NO'})",
            "HOST_UP_AFTER_DOWN_OBSERVED=$(if($upAfterDown){'YES'}else{'NO'})","HOST_CYCLE_GATE=$gate"
        )){$lines.Add($line)}
        foreach($record in $records){$lines.Add($record)}
        Write-R1gUtf8NoBom -Path $outputPath -Lines $lines.ToArray()
        $lines|Select-Object -First 9
        if($gate-cne'PASS_HOST_DISAPPEARED_AND_RETURNED'){exit 1}
        exit 0
    }
    'PreLoaderValidate' {
        if (-not $PreviousBootId) { throw 'PreLoaderValidate requires the exact previous boot ID' }
        Require-ExactLine (Join-Path $phaseDirectory 'HOST_CYCLE_RECEIPT.txt') HOST_CYCLE_GATE PASS_HOST_DISAPPEARED_AND_RETURNED
        $roleToken = switch($phase.Kind){'BOOTSTRAP'{'formal_bootstrap'}'ARM_A'{'arm_a_r1g'}'ARM_B'{'arm_b_formal'}}
        $inheritedRoleToken = if($phase.Kind -ceq 'BOOTSTRAP'){'formal_bootstrap'}elseif($phase.Kind -ceq 'ARM_A'){'arm_a_r1e'}else{'arm_b_formal'}
        $oldDriverDirectory = switch($inheritedRoleToken){'formal_bootstrap'{'/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/bootstrap_driver'}'arm_a_r1e'{'/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_a_driver'}'arm_b_formal'{'/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_b_driver'}}
        $validatorText=[IO.File]::ReadAllText($preLoaderPath,[Text.UTF8Encoding]::new($false,$true))
        if([regex]::Matches($validatorText,[regex]::Escape($oldDriverDirectory)).Count-ne1){throw 'accepted preloader directory literal count is not exactly one'}
        $adaptedText=$validatorText.Replace($oldDriverDirectory,$phase.RemoteDriverAbsolutePath)
        if($adaptedText.Contains($oldDriverDirectory,[StringComparison]::Ordinal)-or-not$adaptedText.Contains($phase.RemoteDriverAbsolutePath,[StringComparison]::Ordinal)){throw 'preloader directory-only adapter failed closed'}
        $adaptedBytes=[Text.UTF8Encoding]::new($false).GetBytes($adaptedText)
        $adaptedSha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($adaptedBytes))
        $expectedAdaptedSha=switch($PhaseToken){'Bootstrap'{'0A24E8A4367306705D08C9F499973890E70290505DE57F2D796B986B0BD85E64'}'A1'{'292FC3D84BFBC08C118F7FDDCD1C41F1130F032114066BE8F4956797EE2E4E73'}'B1'{'1029FE242F59ED373C198AC60CC0EBD7D38D1009E4149F08F05DC6AA1CBE7358'}'A2'{'0CE089EEF9BBC76CE20758D328B080187D074903D097BE114AA4CBB7505C109D'}'B2'{'160C5DA87E264FD54BD90BFD0AFEECDD2EF870DC1B1D0AD79B5BF47A8DBEFF3D'}'A3'{'C6B5F81692D4F7883B758072DAEF75B68B171D989A1B0D32502D2135930EF0FE'}'B3'{'32FBEACC85E185784F4FF3F6FB45DA011ECDE83CCCAA748BC53C6348ECA559DE'}}
        if($adaptedSha-cne$expectedAdaptedSha){throw 'preloader adapted-payload SHA-256 mismatch'}
        $adapterReceipt=Join-Path $phaseDirectory 'PRELOADER_PAYLOAD_ADAPTER_RECEIPT.txt'
        if(Test-Path -LiteralPath $adapterReceipt){throw 'refusing to overwrite preloader adapter receipt'}
        Write-R1gUtf8NoBom -Path $adapterReceipt -Lines @("BASE_PAYLOAD_SHA256=$($script:R1gAcceptedTools.PreLoaderValidator.Sha256)","ADAPTER_CLASS=REMOTE_EVIDENCE_DIRECTORY_LITERAL_ONLY","OLD_REMOTE_DIRECTORY=$oldDriverDirectory","NEW_REMOTE_DIRECTORY=$($phase.RemoteDriverAbsolutePath)","ADAPTED_PAYLOAD_SHA256=$adaptedSha",'ADAPTED_PAYLOAD_SHA256_GATE=PASS')
        $validatorPayload = ConvertTo-GzipBase64 $adaptedBytes
        $barPayload = ConvertTo-GzipBase64 ([IO.File]::ReadAllBytes($barParserPath))
        # The accepted R7 validator accepts its role as a label; all kernel,
        # boot-ID, endpoint, Gen1 x1 and BAR gates are role-independent.
        $template='sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2" "$3" "$4" "$5"'' _ ''{0}'' ''{1}'' ''{2}'' ''{3}'' ''{4}'''
        $remoteCommand=$template -f $validatorPayload,$inheritedRoleToken,$PreviousBootId,$barPayload,$script:R1gAcceptedTools.BarParser.Sha256
        & $helperPath -PlinkPath $plinkPath -HostKey $hostKey -RemoteCommand $remoteCommand `
            -EvidencePath $outputPath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
            -EvidenceKind ("R1G_PRELOADER_{0}_{1}" -f $PhaseToken,$roleToken) -SendPasswordToStdin `
            -SudoPasswordCopies 1 -TimeoutSeconds 180
        exit $LASTEXITCODE
    }
    'ExactDriverLoad' {
        $existing = @(Get-ChildItem -LiteralPath $script:R1gTaskRoot -Filter LOADER_EVIDENCE.log -File -Recurse -ErrorAction SilentlyContinue)
        if ($existing.Count -ge $script:R1gMaximumDriverLoads) { throw 'driver-load maximum already reached' }
        Require-ExactLine (Join-Path $phaseDirectory 'PRELOADER_EVIDENCE.log') RESULT PASS
        $driverDirectory=$phase.RemoteDriverDirectory
        $remoteTemplate=@'
set -eu; module="$HOME/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko"; loader="$HOME/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh"; out="$HOME/FPGA_AHD_HOST/v41_nvp_r1g/__DRIVER_DIRECTORY__"; test -f "$module"; test ! -L "$module"; test -f "$loader"; test ! -L "$loader"; test "$(sha256sum "$module" | awk '{print toupper($1)}')" = __MODULE_SHA__; test "$(sha256sum "$loader" | awk '{print toupper($1)}')" = __LOADER_SHA__; test "$(stat -Lc '%a' "$loader")" = 644; test ! -e "$out"; exec sudo -S -k -p '' /usr/bin/bash "$loader" "$module" __MODULE_SHA__ "$out"
'@
        $remoteCommand=$remoteTemplate.Trim().Replace('__DRIVER_DIRECTORY__',$driverDirectory).Replace('__MODULE_SHA__',$moduleSha).Replace('__LOADER_SHA__',$loaderSha)
        & $helperPath -PlinkPath $plinkPath -HostKey $hostKey -RemoteCommand $remoteCommand `
            -EvidencePath $outputPath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
            -EvidenceKind ("R1G_EXACT_PINNED_LOADER_{0}" -f $PhaseToken) -SendPasswordToStdin `
            -SudoPasswordCopies 1 -TimeoutSeconds 120
        exit $LASTEXITCODE
    }
}
