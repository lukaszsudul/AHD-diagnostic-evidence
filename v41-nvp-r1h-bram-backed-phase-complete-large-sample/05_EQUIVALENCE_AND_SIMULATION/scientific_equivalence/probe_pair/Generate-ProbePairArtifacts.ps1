$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ReferenceRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY'
$CandidateRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$OutRoot = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\05_EQUIVALENCE_AND_SIMULATION\scientific_equivalence\probe_pair\generated_02'
$ExactCommit = 'e112a5addb7ac62700a9a71af81bf368fad0bada'
$ExactTree = '3a59ebec130103055d24a3a32ecda00dedde5534'
$Relative = 'rtl\v41\nvp_i2c_tri_phase_probe.sv'

$commit = (git -C $ReferenceRoot rev-parse HEAD).Trim()
$tree = (git -C $ReferenceRoot rev-parse 'HEAD^{tree}').Trim()
$status = (git -C $ReferenceRoot status --porcelain --untracked-files=all) -join "`n"
$candidateParent = (git -C $CandidateRoot rev-parse HEAD).Trim()
if ($commit -ne $ExactCommit -or $tree -ne $ExactTree -or $status) { throw 'exact clean R1g reference unavailable' }
if ($candidateParent -ne $ExactCommit) { throw 'R1h candidate parent mismatch' }

$refPath = Join-Path $ReferenceRoot $Relative
$candPath = Join-Path $CandidateRoot $Relative
$refText = [IO.File]::ReadAllText($refPath)
$candText = [IO.File]::ReadAllText($candPath)
$refHash = (Get-FileHash $refPath -Algorithm SHA256).Hash
$candHash = (Get-FileHash $candPath -Algorithm SHA256).Hash

function Get-OutputPorts([string]$Text) {
  $ports = @{}
  foreach ($match in [regex]::Matches($Text, '(?m)^\s*output\s+logic\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*([A-Za-z_][A-Za-z0-9_]*)')) {
    $msb = if ($match.Groups[1].Success) { [int]$match.Groups[1].Value } else { 0 }
    $lsb = if ($match.Groups[2].Success) { [int]$match.Groups[2].Value } else { 0 }
    $ports[$match.Groups[3].Value] = [math]::Abs($msb - $lsb) + 1
  }
  return $ports
}

$refPorts = Get-OutputPorts $refText
$candPorts = Get-OutputPorts $candText
$common = @($refPorts.Keys | Where-Object {
  $candPorts.ContainsKey($_) -and $refPorts[$_] -eq $candPorts[$_] -and $_ -notin @('index_read_data')
} | Sort-Object)
if ($common.Count -lt 80) { throw "unexpected common output count $($common.Count)" }

if (Test-Path $OutRoot) { throw "generated output already sealed: $OutRoot" }
[void](New-Item -ItemType Directory -Path $OutRoot)

$renamed = [regex]::Replace($refText, '(?m)^module\s+nvp_i2c_tri_phase_probe\s*#\(', 'module r1g_nvp_i2c_tri_phase_probe_reference #(', 1)
if ($renamed -eq $refText) { throw 'reference module rename did not occur' }
$renamedPath = Join-Path $OutRoot 'r1g_nvp_i2c_tri_phase_probe_reference_generated.sv'
[IO.File]::WriteAllText($renamedPath, $renamed, [Text.UTF8Encoding]::new($false))

$includeLines = [Collections.Generic.List[string]]::new()
$includeLines.Add('`ifndef R1H_PROBE_COMMON_OUTPUTS_GENERATED_SVH')
$includeLines.Add('`define R1H_PROBE_COMMON_OUTPUTS_GENERATED_SVH')
$includeLines.Add('`define PROBE_COMMON_OUTPUTS \')
for ($i=0; $i -lt $common.Count; $i++) {
  $suffix = if ($i -lt $common.Count-1) { ' \' } else { '' }
  $includeLines.Add("  ``PROBE_X($($refPorts[$common[$i]]), $($common[$i]))$suffix")
}
$includeLines.Add('`endif')
$includePath = Join-Path $OutRoot 'probe_common_outputs_generated.svh'
[IO.File]::WriteAllLines($includePath, $includeLines, [Text.UTF8Encoding]::new($false))

$csv = [Collections.Generic.List[string]]::new(); $csv.Add('name,width,reference_width,candidate_width')
foreach ($name in $common) { $csv.Add("$name,$($refPorts[$name]),$($refPorts[$name]),$($candPorts[$name])") }
[IO.File]::WriteAllLines((Join-Path $OutRoot 'COMMON_OUTPUT_INVENTORY.csv'),$csv,[Text.UTF8Encoding]::new($false))

$identity = @(
  "REFERENCE_COMMIT=$commit",
  "REFERENCE_TREE=$tree",
  "CANDIDATE_PARENT=$candidateParent",
  "REFERENCE_PROBE_SHA256=$refHash",
  "CANDIDATE_PROBE_SHA256=$candHash",
  "COMMON_OUTPUT_COUNT=$($common.Count)",
  'EXCLUDED_INTERFACE=index_read_data_WIDTH_AND_LATENCY_CHANGED_BY_AUTHORIZATION',
  'REFERENCE_TRANSFORMATION=EXACTLY_ONE_MODULE_IDENTIFIER_RENAME',
  "GENERATED_REFERENCE_SHA256=$((Get-FileHash $renamedPath -Algorithm SHA256).Hash)",
  "GENERATED_INCLUDE_SHA256=$((Get-FileHash $includePath -Algorithm SHA256).Hash)"
)
[IO.File]::WriteAllLines((Join-Path $OutRoot 'GENERATION_IDENTITY.txt'),$identity,[Text.UTF8Encoding]::new($false))
$identity
