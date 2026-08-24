[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'R1gCampaignCommon.ps1')

$created = [Collections.Generic.List[string]]::new()
foreach ($token in @('Bootstrap','A1','B1','A2','B2','A3','B3')) {
    $spec = Get-R1gPhaseSpec $token
    if (Test-Path -LiteralPath $spec.Directory) {
        if (-not (Test-Path -LiteralPath $spec.Directory -PathType Container)) {
            throw "campaign evidence path exists but is not a directory: $($spec.Directory)"
        }
        continue
    }
    $parent = Split-Path -Parent $spec.Directory
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw "required task phase parent is absent: $parent"
    }
    if ($PSCmdlet.ShouldProcess($spec.Directory,'create exact one-shot campaign evidence directory')) {
        [void](New-Item -ItemType Directory -LiteralPath $spec.Directory)
        $created.Add($spec.Directory)
    }
}

$created | ForEach-Object { "CREATED=$_" }
"CREATED_COUNT=$($created.Count)"
'HARDWARE_ACTIONS=0'

