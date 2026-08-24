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
. (Join-Path $PSScriptRoot 'R1fCampaignCommon.ps1')

$binding = Get-R1fBindingDocument -BindingPath $BindingPath
Assert-R1fAcceptedToolSet
$phase = Get-R1fPhaseSpec $PhaseToken
$phaseDirectory = Assert-R1fPhaseDirectory $phase
$helperPath = $script:R1fAcceptedTools.ContextualPlink.Path
$plinkPath = $script:R1fAcceptedTools.Plink084.Path
$barParserPath = $script:R1fAcceptedTools.BarParser.Path
$preLoaderPath = $script:R1fAcceptedTools.PreLoaderValidator.Path
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
        $existing = @(Get-ChildItem -LiteralPath $script:R1fTaskRoot -Filter WARM_REBOOT_EVIDENCE.log -File -Recurse -ErrorAction SilentlyContinue)
        if ($existing.Count -ge $script:R1fMaximumWarmReboots) { throw 'warm-reboot maximum already reached' }
        Require-ExactLine (Join-Path $phaseDirectory 'PROGRAM_WAIT_RECEIPT.txt') WAIT_GATE PASS
        # Exactly one state-changing command; there is no retry or polling loop.
        $remoteCommand = "sudo -S -k -p '' /usr/sbin/reboot"
        & $helperPath -PlinkPath $plinkPath -HostKey $hostKey -RemoteCommand $remoteCommand `
            -EvidencePath $outputPath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
            -EvidenceKind ("R1F_WARM_REBOOT_{0}" -f $PhaseToken) -SendPasswordToStdin `
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
        Write-R1fUtf8NoBom -Path $outputPath -Lines $lines.ToArray()
        $lines|Select-Object -First 9
        if($gate-cne'PASS_HOST_DISAPPEARED_AND_RETURNED'){exit 1}
        exit 0
    }
    'PreLoaderValidate' {
        if (-not $PreviousBootId) { throw 'PreLoaderValidate requires the exact previous boot ID' }
        Require-ExactLine (Join-Path $phaseDirectory 'HOST_CYCLE_RECEIPT.txt') HOST_CYCLE_GATE PASS_HOST_DISAPPEARED_AND_RETURNED
        $roleToken = switch($phase.Kind){'BOOTSTRAP'{'formal_bootstrap'}'ARM_A'{'arm_a_r1f'}'ARM_B'{'arm_b_formal'}}
        $inheritedRoleToken = if($phase.Kind -ceq 'BOOTSTRAP'){'formal_bootstrap'}elseif($phase.Kind -ceq 'ARM_A'){'arm_a_r1e'}else{'arm_b_formal'}
        $oldDriverDirectory = switch($inheritedRoleToken){'formal_bootstrap'{'/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/bootstrap_driver'}'arm_a_r1e'{'/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_a_driver'}'arm_b_formal'{'/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_b_driver'}}
        $validatorText=[IO.File]::ReadAllText($preLoaderPath,[Text.UTF8Encoding]::new($false,$true))
        if([regex]::Matches($validatorText,[regex]::Escape($oldDriverDirectory)).Count-ne1){throw 'accepted preloader directory literal count is not exactly one'}
        $adaptedText=$validatorText.Replace($oldDriverDirectory,$phase.RemoteDriverAbsolutePath)
        if($adaptedText.Contains($oldDriverDirectory,[StringComparison]::Ordinal)-or-not$adaptedText.Contains($phase.RemoteDriverAbsolutePath,[StringComparison]::Ordinal)){throw 'preloader directory-only adapter failed closed'}
        $adaptedBytes=[Text.UTF8Encoding]::new($false).GetBytes($adaptedText)
        $adaptedSha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($adaptedBytes))
        $expectedAdaptedSha=switch($PhaseToken){'Bootstrap'{'19CF42DE01F485321197ADEB829C92B433CB177C268CCE26DB98221218AD139E'}'A1'{'86A64AE776F8DF340863B720AE92F6DDBDC7C88122864CF25FA2766679469D76'}'B1'{'C2C7AEA6D1EE19FDD48D462053C5F88586B88798A19FC28CF1C9F4416F40F4F0'}'A2'{'F26CE0E89ABFE64BEA3A4404F9ACBFA49FAE67B09FFD0C3CF310D9001069B495'}'B2'{'4F4B5DDB044CA590ECF6B4AF3FBBEFAE22ABDB392C573B91155E2F950A96F130'}'A3'{'0725C79101F32DFB510D2DEDB130DB9331587472E5FEB04D7264F174DAD8CF0B'}'B3'{'E81E319C061BD846B55283D0894F74D870A8C3514C46651A4C2E93819C367B05'}}
        if($adaptedSha-cne$expectedAdaptedSha){throw 'preloader adapted-payload SHA-256 mismatch'}
        $adapterReceipt=Join-Path $phaseDirectory 'PRELOADER_PAYLOAD_ADAPTER_RECEIPT.txt'
        if(Test-Path -LiteralPath $adapterReceipt){throw 'refusing to overwrite preloader adapter receipt'}
        Write-R1fUtf8NoBom -Path $adapterReceipt -Lines @("BASE_PAYLOAD_SHA256=$($script:R1fAcceptedTools.PreLoaderValidator.Sha256)","ADAPTER_CLASS=REMOTE_EVIDENCE_DIRECTORY_LITERAL_ONLY","OLD_REMOTE_DIRECTORY=$oldDriverDirectory","NEW_REMOTE_DIRECTORY=$($phase.RemoteDriverAbsolutePath)","ADAPTED_PAYLOAD_SHA256=$adaptedSha",'ADAPTED_PAYLOAD_SHA256_GATE=PASS')
        $validatorPayload = ConvertTo-GzipBase64 $adaptedBytes
        $barPayload = ConvertTo-GzipBase64 ([IO.File]::ReadAllBytes($barParserPath))
        # The accepted R7 validator accepts its role as a label; all kernel,
        # boot-ID, endpoint, Gen1 x1 and BAR gates are role-independent.
        $template='sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2" "$3" "$4" "$5"'' _ ''{0}'' ''{1}'' ''{2}'' ''{3}'' ''{4}'''
        $remoteCommand=$template -f $validatorPayload,$inheritedRoleToken,$PreviousBootId,$barPayload,$script:R1fAcceptedTools.BarParser.Sha256
        & $helperPath -PlinkPath $plinkPath -HostKey $hostKey -RemoteCommand $remoteCommand `
            -EvidencePath $outputPath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
            -EvidenceKind ("R1F_PRELOADER_{0}_{1}" -f $PhaseToken,$roleToken) -SendPasswordToStdin `
            -SudoPasswordCopies 1 -TimeoutSeconds 180
        exit $LASTEXITCODE
    }
    'ExactDriverLoad' {
        $existing = @(Get-ChildItem -LiteralPath $script:R1fTaskRoot -Filter LOADER_EVIDENCE.log -File -Recurse -ErrorAction SilentlyContinue)
        if ($existing.Count -ge $script:R1fMaximumDriverLoads) { throw 'driver-load maximum already reached' }
        Require-ExactLine (Join-Path $phaseDirectory 'PRELOADER_EVIDENCE.log') RESULT PASS
        $driverDirectory=$phase.RemoteDriverDirectory
        $remoteTemplate=@'
set -eu; module="$HOME/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko"; loader="$HOME/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh"; out="$HOME/FPGA_AHD_HOST/v41_nvp_r1f/__DRIVER_DIRECTORY__"; test -f "$module"; test ! -L "$module"; test -f "$loader"; test ! -L "$loader"; test "$(sha256sum "$module" | awk '{print toupper($1)}')" = __MODULE_SHA__; test "$(sha256sum "$loader" | awk '{print toupper($1)}')" = __LOADER_SHA__; test "$(stat -Lc '%a' "$loader")" = 644; test ! -e "$out"; exec sudo -S -k -p '' /usr/bin/bash "$loader" "$module" __MODULE_SHA__ "$out"
'@
        $remoteCommand=$remoteTemplate.Trim().Replace('__DRIVER_DIRECTORY__',$driverDirectory).Replace('__MODULE_SHA__',$moduleSha).Replace('__LOADER_SHA__',$loaderSha)
        & $helperPath -PlinkPath $plinkPath -HostKey $hostKey -RemoteCommand $remoteCommand `
            -EvidencePath $outputPath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
            -EvidenceKind ("R1F_EXACT_PINNED_LOADER_{0}" -f $PhaseToken) -SendPasswordToStdin `
            -SudoPasswordCopies 1 -TimeoutSeconds 120
        exit $LASTEXITCODE
    }
}
