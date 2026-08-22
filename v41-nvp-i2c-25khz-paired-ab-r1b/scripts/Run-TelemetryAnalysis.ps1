[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputPath,
    [Parameter(Mandatory)][ValidateSet('ARM_A_25KHZ','ARM_B_FORMAL_50KHZ')][string]$Role,
    [Parameter(Mandatory)][string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$analyzer = Join-Path $PSScriptRoot 'Analyze-I25Telemetry.ps1'
$expectedAnalyzerSha = '396FBB902947C3869AA4AFF68FD656F63BBABB0116E9E788C8810F756B12DB23'
if ((Get-FileHash -LiteralPath $analyzer -Algorithm SHA256).Hash -cne $expectedAnalyzerSha) {
    throw 'telemetry analyzer identity mismatch'
}
if (Test-Path -LiteralPath $OutputPath) { throw 'parsed output path must be fresh' }
$lines = @(& $analyzer -InputPath $InputPath -Role $Role)
[IO.File]::WriteAllLines($OutputPath,$lines,[Text.UTF8Encoding]::new($false))
$lines
