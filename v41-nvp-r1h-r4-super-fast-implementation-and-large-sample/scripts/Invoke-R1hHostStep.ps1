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
. (Join-Path $PSScriptRoot 'R1hCampaignCommon.ps1')

$binding = Get-R1hBindingDocument -BindingPath $BindingPath
Assert-R1hAcceptedToolSet
$phase = Get-R1hPhaseSpec $PhaseToken
$phaseDirectory = Assert-R1hPhaseDirectory $phase
$helperPath = $script:R1hAcceptedTools.ContextualPlink.Path
$plinkPath = $script:R1hAcceptedTools.Plink084.Path
$barParserPath = $script:R1hAcceptedTools.BarParser.Path
$preLoaderPath = $script:R1hAcceptedTools.PreLoaderValidator.Path
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
        $existing = @(Get-ChildItem -LiteralPath $script:R1hTaskRoot -Filter WARM_REBOOT_EVIDENCE.log -File -Recurse -ErrorAction SilentlyContinue)
        if ($existing.Count -ge $script:R1hMaximumWarmReboots) { throw 'warm-reboot maximum already reached' }
        Require-ExactLine (Join-Path $phaseDirectory 'PROGRAM_WAIT_RECEIPT.txt') WAIT_GATE PASS
        # Exactly one state-changing command; there is no retry or polling loop.
        $remoteCommand = "sudo -S -k -p '' /usr/sbin/reboot"
        & $helperPath -PlinkPath $plinkPath -HostKey $hostKey -RemoteCommand $remoteCommand `
            -EvidencePath $outputPath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
            -EvidenceKind ("R1H_WARM_REBOOT_{0}" -f $PhaseToken) -SendPasswordToStdin `
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
        Write-R1hUtf8NoBom -Path $outputPath -Lines $lines.ToArray()
        $lines|Select-Object -First 9
        if($gate-cne'PASS_HOST_DISAPPEARED_AND_RETURNED'){exit 1}
        exit 0
    }
    'PreLoaderValidate' {
        if (-not $PreviousBootId) { throw 'PreLoaderValidate requires the exact previous boot ID' }
        Require-ExactLine (Join-Path $phaseDirectory 'HOST_CYCLE_RECEIPT.txt') HOST_CYCLE_GATE PASS_HOST_DISAPPEARED_AND_RETURNED
        $roleToken = switch($phase.Kind){'BOOTSTRAP'{'formal_bootstrap'}'ARM_A'{'arm_a_r1h'}'ARM_B'{'arm_b_formal'}}
        $inheritedRoleToken = if($phase.Kind -ceq 'BOOTSTRAP'){'formal_bootstrap'}elseif($phase.Kind -ceq 'ARM_A'){'arm_a_r1e'}else{'arm_b_formal'}
        $oldDriverDirectory = switch($inheritedRoleToken){'formal_bootstrap'{'/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/bootstrap_driver'}'arm_a_r1e'{'/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_a_driver'}'arm_b_formal'{'/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_b_driver'}}
        $validatorText=[IO.File]::ReadAllText($preLoaderPath,[Text.UTF8Encoding]::new($false,$true))
        if([regex]::Matches($validatorText,[regex]::Escape($oldDriverDirectory)).Count-ne1){throw 'accepted preloader directory literal count is not exactly one'}
        $adaptedText=$validatorText.Replace($oldDriverDirectory,$phase.RemoteDriverAbsolutePath)
        if($adaptedText.Contains($oldDriverDirectory,[StringComparison]::Ordinal)-or-not$adaptedText.Contains($phase.RemoteDriverAbsolutePath,[StringComparison]::Ordinal)){throw 'preloader directory-only adapter failed closed'}
        $adaptedBytes=[Text.UTF8Encoding]::new($false).GetBytes($adaptedText)
        $adaptedSha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($adaptedBytes))
        $expectedAdaptedSha=switch($PhaseToken){'Bootstrap'{'BFAE646680D03D9DA4CDFCE3C40E9674F76E045AFA0609E5BE9EA1F41C253ECA'}'A1'{'ED11FABA492BF5FFCB8E35FFAA68FA9B4495CFFA8512E8BCFF877DC808462253'}'B1'{'0CB89D316FA239E35400D3ED010806C6B50C468D4C85167D5C9F68D2025F7061'}'A2'{'9BDA0D1B0265D1C47EA5535D30644B8AA385D1B38BDB200192149377DEC88C47'}'B2'{'F590E5F54A54A6AAEAD88315FC01A3F4C079CA17029C9BD7E5B8DA915A97CA04'}'A3'{'9C874C2ECA64CF82308B5A8B1C4C86FA45FEA3B6FE68F41E2AC18B0CD7B43D6D'}'B3'{'CD62EDB0130B650D79993E22E600B059FE668FF294874611A6A60BDBD4F17B21'}}
        if($adaptedSha-cne$expectedAdaptedSha){throw 'preloader adapted-payload SHA-256 mismatch'}
        $adapterReceipt=Join-Path $phaseDirectory 'PRELOADER_PAYLOAD_ADAPTER_RECEIPT.txt'
        if(Test-Path -LiteralPath $adapterReceipt){throw 'refusing to overwrite preloader adapter receipt'}
        Write-R1hUtf8NoBom -Path $adapterReceipt -Lines @("BASE_PAYLOAD_SHA256=$($script:R1hAcceptedTools.PreLoaderValidator.Sha256)","ADAPTER_CLASS=REMOTE_EVIDENCE_DIRECTORY_LITERAL_ONLY","OLD_REMOTE_DIRECTORY=$oldDriverDirectory","NEW_REMOTE_DIRECTORY=$($phase.RemoteDriverAbsolutePath)","ADAPTED_PAYLOAD_SHA256=$adaptedSha",'ADAPTED_PAYLOAD_SHA256_GATE=PASS')
        $validatorPayload = ConvertTo-GzipBase64 $adaptedBytes
        $barPayload = ConvertTo-GzipBase64 ([IO.File]::ReadAllBytes($barParserPath))
        # The accepted R7 validator accepts its role as a label; all kernel,
        # boot-ID, endpoint, Gen1 x1 and BAR gates are role-independent.
        $template='sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2" "$3" "$4" "$5"'' _ ''{0}'' ''{1}'' ''{2}'' ''{3}'' ''{4}'''
        $remoteCommand=$template -f $validatorPayload,$inheritedRoleToken,$PreviousBootId,$barPayload,$script:R1hAcceptedTools.BarParser.Sha256
        & $helperPath -PlinkPath $plinkPath -HostKey $hostKey -RemoteCommand $remoteCommand `
            -EvidencePath $outputPath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
            -EvidenceKind ("R1H_PRELOADER_{0}_{1}" -f $PhaseToken,$roleToken) -SendPasswordToStdin `
            -SudoPasswordCopies 1 -TimeoutSeconds 180
        exit $LASTEXITCODE
    }
    'ExactDriverLoad' {
        $existing = @(Get-ChildItem -LiteralPath $script:R1hTaskRoot -Filter LOADER_EVIDENCE.log -File -Recurse -ErrorAction SilentlyContinue)
        if ($existing.Count -ge $script:R1hMaximumDriverLoads) { throw 'driver-load maximum already reached' }
        Require-ExactLine (Join-Path $phaseDirectory 'PRELOADER_EVIDENCE.log') RESULT PASS
        $driverDirectory=$phase.RemoteDriverDirectory
        $remoteTemplate=@'
set -eu; module="$HOME/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko"; loader="$HOME/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh"; out="$HOME/FPGA_AHD_HOST/v41_nvp_r1h_r4_61ec5f55/__DRIVER_DIRECTORY__"; test -f "$module"; test ! -L "$module"; test -f "$loader"; test ! -L "$loader"; test "$(sha256sum "$module" | awk '{print toupper($1)}')" = __MODULE_SHA__; test "$(sha256sum "$loader" | awk '{print toupper($1)}')" = __LOADER_SHA__; test "$(stat -Lc '%a' "$loader")" = 644; test ! -e "$out"; exec sudo -S -k -p '' /usr/bin/bash "$loader" "$module" __MODULE_SHA__ "$out"
'@
        $remoteCommand=$remoteTemplate.Trim().Replace('__DRIVER_DIRECTORY__',$driverDirectory).Replace('__MODULE_SHA__',$moduleSha).Replace('__LOADER_SHA__',$loaderSha)
        & $helperPath -PlinkPath $plinkPath -HostKey $hostKey -RemoteCommand $remoteCommand `
            -EvidencePath $outputPath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
            -EvidenceKind ("R1H_EXACT_PINNED_LOADER_{0}" -f $PhaseToken) -SendPasswordToStdin `
            -SudoPasswordCopies 1 -TimeoutSeconds 120
        exit $LASTEXITCODE
    }
}
