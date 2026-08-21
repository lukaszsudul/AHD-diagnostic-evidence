[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DiagnosticWorktree,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{40}$')]
    [string]$DiagnosticSourceCommit,
    [Parameter(Mandatory = $true)]
    [string]$DiagnosticBitPath,
    [Parameter(Mandatory = $true)]
    [string]$FormalBitPath,
    [Parameter(Mandatory = $true)]
    [string]$PlinkPath
)

$ErrorActionPreference = 'Stop'

$formalSha = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
$formalSize = 2192144L
$formalFilename = 'ahd_capture_v41_phase2_p1.bit'
$diagnosticCommit = 'f007dc172d43d30b02729755e60382f8ce3dbff4'
$diagnosticTree = 'b8f87966c8021396acb6341bd2d7d86a10fd7f13'
$diagnosticBranch = 'diag/v41-nvp-i2c-25khz-r1'
$diagnosticFilename = 'ahd_capture_v41_i2c_25khz_r1.bit'
$diagnosticSize = 2192144L
$diagnosticSha = 'B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191'
$diagnosticCanonicalPath = 'C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\04_BUILD\FULL_BUILD_EVIDENCE\artifacts\ahd_capture_v41_i2c_25khz_r1.bit'
$plinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$vivadoSettings = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
$vivadoWrapper = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$vivadoSettingsSha = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
$vivadoWrapperSha = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'

function Gate-File([string]$Role, [string]$Path, [string]$ExpectedSha, [long]$ExpectedSize) {
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $item = Get-Item -LiteralPath $resolved
    $sha = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
    $pass = ($sha -ceq $ExpectedSha.ToUpperInvariant() -and ($ExpectedSize -le 0 -or $item.Length -eq $ExpectedSize))
    [pscustomobject]@{ Role=$Role; Path=$resolved; Size=$item.Length; SHA256=$sha; Pass=$pass }
}

$worktree = (Resolve-Path -LiteralPath $DiagnosticWorktree -ErrorAction Stop).Path
$actualHead = (& git -C $worktree rev-parse HEAD).Trim()
$actualTree = (& git -C $worktree rev-parse 'HEAD^{tree}').Trim()
$actualBranch = (& git -C $worktree branch --show-current).Trim()
$actualStatus = (& git -C $worktree status --porcelain --untracked-files=all) -join "`n"
$sourceGate = (
    $DiagnosticSourceCommit.ToLowerInvariant() -ceq $diagnosticCommit -and
    $actualHead -ceq $diagnosticCommit -and
    $actualTree -ceq $diagnosticTree -and
    $actualBranch -ceq $diagnosticBranch -and
    [string]::IsNullOrEmpty($actualStatus)
)

$results = @(
    Gate-File FORMAL_BIT $FormalBitPath $formalSha $formalSize
    Gate-File DIAGNOSTIC_BIT $DiagnosticBitPath $diagnosticSha $diagnosticSize
    Gate-File PLINK $PlinkPath $plinkSha 1043072L
    Gate-File VIVADO_SETTINGS $vivadoSettings $vivadoSettingsSha 779L
    Gate-File VIVADO_WRAPPER $vivadoWrapper $vivadoWrapperSha 1263L
)

$diagnosticBitItem = Get-Item -LiteralPath (Resolve-Path -LiteralPath $DiagnosticBitPath)
$formalBitItem = Get-Item -LiteralPath (Resolve-Path -LiteralPath $FormalBitPath)
$diagnosticFilenameGate = $diagnosticBitItem.Name -ceq $diagnosticFilename
$diagnosticPathGate = $diagnosticBitItem.FullName -ceq $diagnosticCanonicalPath
$formalFilenameGate = $formalBitItem.Name -ceq $formalFilename

'DIAGNOSTIC_SOURCE_COMMIT_EXPECTED={0}' -f $diagnosticCommit
'DIAGNOSTIC_SOURCE_COMMIT_OBSERVED={0}' -f $actualHead
'DIAGNOSTIC_SOURCE_TREE_EXPECTED={0}' -f $diagnosticTree
'DIAGNOSTIC_SOURCE_TREE_OBSERVED={0}' -f $actualTree
'DIAGNOSTIC_BRANCH_EXPECTED={0}' -f $diagnosticBranch
'DIAGNOSTIC_BRANCH_OBSERVED={0}' -f $actualBranch
'DIAGNOSTIC_WORKTREE_CLEAN={0}' -f $(if ([string]::IsNullOrEmpty($actualStatus)) { 'YES' } else { 'NO' })
'DIAGNOSTIC_SOURCE_GATE={0}' -f $(if ($sourceGate) { 'PASS' } else { 'FAIL' })
'DIAGNOSTIC_BIT_HASH_SOURCE=SEALED_POST_BUILD_GATE_PASS'
'DIAGNOSTIC_BIT_SHA256_EXPECTED={0}' -f $diagnosticSha
'DIAGNOSTIC_BIT_SIZE_EXPECTED={0}' -f $diagnosticSize
'DIAGNOSTIC_BIT_PATH_EXPECTED={0}' -f $diagnosticCanonicalPath
'DIAGNOSTIC_BIT_PATH_GATE={0}' -f $(if ($diagnosticPathGate) { 'PASS' } else { 'FAIL' })
'DIAGNOSTIC_BIT_FILENAME_EXPECTED={0}' -f $diagnosticFilename
'DIAGNOSTIC_BIT_FILENAME_GATE={0}' -f $(if ($diagnosticFilenameGate) { 'PASS' } else { 'FAIL' })
'FORMAL_BIT_FILENAME_EXPECTED={0}' -f $formalFilename
'FORMAL_BIT_FILENAME_GATE={0}' -f $(if ($formalFilenameGate) { 'PASS' } else { 'FAIL' })
'EXPECTED_GIT_SHA_W0=0xF007DC17'
'EXPECTED_GIT_SHA_W1=0x2D43D30B'
'EXPECTED_GIT_SHA_W2=0x02729755'
'EXPECTED_GIT_SHA_W3=0xE60382F8'
'EXPECTED_GIT_SHA_W4=0xCE3DBFF4'
'EXPECTED_BUILD_FLAGS=0x00000002'

foreach ($result in $results) {
    'ROLE={0} PATH={1} SIZE={2} SHA256={3} GATE={4}' -f $result.Role,$result.Path,$result.Size,$result.SHA256,$(if ($result.Pass) { 'PASS' } else { 'FAIL' })
}

$owners = Get-CimInstance Win32_Process -ErrorAction Stop |
    Where-Object { $_.Name -in @('vivado.exe','hw_server.exe') } |
    Select-Object Name,ProcessId,ExecutablePath,CommandLine
'HARDWARE_OWNER_PROCESS_COUNT={0}' -f @($owners).Count
foreach ($owner in $owners) {
    'HARDWARE_OWNER_PROCESS={0} PID={1} PATH={2} COMMAND_LINE={3}' -f $owner.Name,$owner.ProcessId,$owner.ExecutablePath,$owner.CommandLine
}

if (-not $sourceGate -or -not $diagnosticFilenameGate -or -not $diagnosticPathGate -or -not $formalFilenameGate -or
    $results.Where({ -not $_.Pass }).Count -gt 0) {
    'LOCAL_STATIC_GATE=FAIL_IDENTITY'
    exit 1
}
if (@($owners).Count -gt 0) {
    'LOCAL_STATIC_GATE=BLOCKED_EXISTING_HARDWARE_OWNER_REVIEW_REQUIRED'
    exit 2
}
'LOCAL_STATIC_GATE=PASS'
