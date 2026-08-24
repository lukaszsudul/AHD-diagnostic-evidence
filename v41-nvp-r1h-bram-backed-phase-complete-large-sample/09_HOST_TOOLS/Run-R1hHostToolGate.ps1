param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$Evidence = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\09_HOST_TOOLS'
$Python = 'C:\AMDDesignTools\2025.2\tps\win64\python-3.13.0\python.exe'
$ExactParent = 'e112a5addb7ac62700a9a71af81bf368fad0bada'
$ExpectedFiles = @(
  'scripts/v41/read_nvp_r1f.py',
  'scripts/v41/r1f_statistics.py',
  'tests/python/test_nvp_r1f_tools.py',
  'tests/python/test_nvp_r1f_tri_phase_probe_model.py'
)

if ((git -C $Repo rev-parse HEAD).Trim() -ne $ExactParent) {
  throw 'R1h candidate is not based on exact R1g HEAD'
}
if (-not (Test-Path -LiteralPath $Python -PathType Leaf)) {
  throw 'exact Vivado-bundled Python is unavailable'
}

$identity = [System.Collections.Generic.List[string]]::new()
$identity.Add('relative_path,r1g_blob_sha1,current_blob_sha1,current_sha256,unchanged')
foreach ($relative in $ExpectedFiles) {
  $currentBlob = (git -C $Repo hash-object -- $relative).Trim()
  $r1gBlob = (git -C $Repo rev-parse "$ExactParent`:$relative").Trim()
  $sha = (Get-FileHash -LiteralPath (Join-Path $Repo $relative) -Algorithm SHA256).Hash
  if ($currentBlob -ne $r1gBlob) {
    throw "host/statistics file changed from exact R1g: $relative"
  }
  $identity.Add(('"{0}",{1},{2},{3},YES' -f $relative,$r1gBlob,$currentBlob,$sha))
}
[System.IO.File]::WriteAllLines(
  (Join-Path $Evidence 'R1H_HOST_TOOL_SOURCE_IDENTITY.csv'),
  $identity,
  [System.Text.UTF8Encoding]::new($false))

$command = @('-B','-m','unittest','discover','-s','tests/python','-p','test_nvp_r1f*.py','-v')
[System.IO.File]::WriteAllLines(
  (Join-Path $Evidence 'python_unittest.command.txt'),
  @("TOOL=$Python","WORKING_DIRECTORY=$Repo","ARGS=$($command -join ' ')"),
  [System.Text.UTF8Encoding]::new($false))

Push-Location -LiteralPath $Repo
try {
  $output = @(& $Python @command 2>&1 | ForEach-Object { $_.ToString() })
  $exitCode = $LASTEXITCODE
}
finally {
  Pop-Location
}
[System.IO.File]::WriteAllLines(
  (Join-Path $Evidence 'python_unittest.log'),
  $output,
  [System.Text.UTF8Encoding]::new($false))

$text = $output -join "`n"
if ($exitCode -ne 0 -or $text -notmatch 'Ran 24 tests' -or
    $text -notmatch '(?m)^OK\s*$' -or $text -match '(?m)^FAILED \(') {
  throw "R1h host fixture gate failed (exit $exitCode)"
}

$logSha = (Get-FileHash -LiteralPath (Join-Path $Evidence 'python_unittest.log') -Algorithm SHA256).Hash
[System.IO.File]::WriteAllLines(
  (Join-Path $Evidence 'R1H_HOST_TOOL_GATE.txt'),
  @(
    'R1G_HOST_AND_STATISTICAL_SOURCES_UNCHANGED=YES',
    'HOST_TOOL_FIXTURES=PASS_24_OF_24',
    'STATISTICAL_SCRIPT_FIXTURES=PASS',
    'HOST_MMIO_WRITES=0',
    "PROCESS_EXIT_CODE=$exitCode",
    "PYTHON_UNITTEST_LOG_SHA256=$logSha"
  ),
  [System.Text.UTF8Encoding]::new($false))

Write-Output 'R1H_HOST_TOOL_GATE=PASS_24_OF_24'
