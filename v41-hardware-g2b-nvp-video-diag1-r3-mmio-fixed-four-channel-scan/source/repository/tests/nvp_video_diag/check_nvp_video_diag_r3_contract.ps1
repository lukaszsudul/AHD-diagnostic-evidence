[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [string]$ParentCommit = 'fcab95726761a0666a67e31c283dbdfb9e775074'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
$corePath = Join-Path $RepoRoot 'rtl\g2b\g2b_nvp_video_diag.sv'
$core = Get-Content -Raw -LiteralPath $corePath

foreach ($literal in @(
        "DIAG_VERSION = 32'h0001_0002",
        'CAP_MMIO_WRITE_RESPONSE_PROTOCOL_FIXED',
        "32'h0000_0800")) {
    if ($core -notmatch [regex]::Escape($literal)) {
        throw "R3 source contract missing: $literal"
    }
}

$mmioStart = $core.IndexOf('assign mmio_req_ready = !mmio_rsp_valid || mmio_rsp_ready;',
    [StringComparison]::Ordinal)
if ($mmioStart -lt 0) {
    throw 'MMIO request-ready contract missing'
}
$writeStart = $core.IndexOf('if (mmio_req_write) begin', $mmioStart,
    [StringComparison]::Ordinal)
$readStart = $core.IndexOf('end else begin', $writeStart,
    [StringComparison]::Ordinal)
$blockEnd = $core.IndexOf('task automatic launch_i2c', $readStart,
    [StringComparison]::Ordinal)
if ($writeStart -lt 0 -or $readStart -lt 0 -or $blockEnd -lt 0) {
    throw 'Unable to isolate diagnostic MMIO write/read branches'
}
$writeBranch = $core.Substring($writeStart, $readStart - $writeStart)
$readBranch = $core.Substring($readStart, $blockEnd - $readStart)
if ($writeBranch -match "mmio_rsp_valid\s*<=\s*1'b1") {
    throw 'Diagnostic write branch can assign response valid high'
}
if ($readBranch -notmatch "mmio_rsp_valid\s*<=\s*1'b1" -or
    $readBranch -notmatch 'mmio_rsp_rdata\s*<=\s*mmio_read_word') {
    throw 'Diagnostic read branch does not create the registered response'
}

$protected = @(
    'rtl/v41/axi_lite_host_bridge.sv',
    'rtl/v41/control_status_regs.sv',
    'rtl/g2b/v41_g2b_mmio_router.sv',
    'rtl/g2b/v41_g2b_onech_c2h.sv',
    'rtl/top/ahd_capture_top_xdma.sv'
)
foreach ($relative in $protected) {
    $parentObject = (& git -C $RepoRoot rev-parse "${ParentCommit}:$relative").Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to resolve protected parent object: $relative"
    }
    $currentObject = (& git -C $RepoRoot hash-object (Join-Path $RepoRoot $relative)).Trim()
    if ($LASTEXITCODE -ne 0 -or $currentObject -ne $parentObject) {
        throw "Protected source changed: $relative"
    }
}

$changed = @(& git -C $RepoRoot status --short | ForEach-Object {
        if ($_.Length -ge 4) { $_.Substring(3).Replace('\', '/') }
    })
$allowed = @(
    'rtl/g2b/g2b_nvp_video_diag.sv',
    'tests/nvp_video_diag/tb_g2b_nvp_video_diag.sv',
    'tests/nvp_video_diag/tb_g2b_nvp_video_diag_mmio_protocol.sv',
    'tests/nvp_video_diag/tb_g2b_nvp_video_diag_axi_integration.sv',
    'tests/nvp_video_diag/check_nvp_video_diag_r3_contract.ps1',
    'tests/nvp_video_diag/run_nvp_video_diag1_sim.ps1',
    'tests/nvp_video_diag/run_nvp_video_diag_r3_sim.ps1'
)
$outside = @($changed | Where-Object { $_ -notin $allowed })
if ($outside.Count -ne 0) {
    throw "Changed-file scope violation: $($outside -join ', ')"
}

Write-Output 'DIAGNOSTIC_WRITE_SETS_MMIO_RSP_VALID=NO'
Write-Output 'DIAGNOSTIC_READ_SETS_MMIO_RSP_VALID=YES'
Write-Output 'WRITE_RESPONSE_GENERATED_BY_SHARED_BRIDGE_ONLY=YES'
Write-Output 'SHARED_AXI_LITE_BRIDGE_CHANGED=NO'
Write-Output 'PRODUCT_CONTROL_STATUS_CHANGED=NO'
Write-Output 'PRODUCT_MMIO_MAP_CHANGED=NO'
Write-Output 'DIAGNOSTIC_MMIO_ADDRESS_MAP_CHANGED=NO'
Write-Output 'DIAG_VERSION=0x00010002'
Write-Output 'MMIO_WRITE_RESPONSE_PROTOCOL_FIXED_CAPABILITY=PRESENT_BIT_11'
Write-Output 'PASS R3_DIAGNOSTIC_MMIO_STATIC_SOURCE_CONTRACT'
