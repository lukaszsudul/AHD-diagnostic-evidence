[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$r6Observer = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6\scripts\program_once_startup_high_done_r6_selected.tcl'
$r7Observer = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\program_once_mode_aware.tcl'
$outputPath = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\02_MODE_AWARE_OBSERVER\R6_TO_R7_OBSERVER_DIFF.patch'
$gitPath = 'C:\Users\Łukasz Suduł\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'

$expected = [ordered]@{
    R6Observer = '00B612413A5322C4FC94003BDF2E6E48318DA61D0D8362D028D70035B03C47AC'
    R7Observer = '55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7'
    Git = 'C53279919FDEA03474BB23B465B3A82287157491F1BD69A5EB82DD9831582333'
}

foreach ($entry in @(
    [pscustomobject]@{ Name='R6Observer'; Path=$r6Observer },
    [pscustomobject]@{ Name='R7Observer'; Path=$r7Observer },
    [pscustomobject]@{ Name='Git'; Path=$gitPath }
)) {
    $resolved = (Resolve-Path -LiteralPath $entry.Path -ErrorAction Stop).Path
    if ($resolved -cne $entry.Path) { throw "$($entry.Name) resolved to an unexpected path: $resolved" }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolved).Hash
    if ($actual -cne $expected[$entry.Name]) { throw "$($entry.Name) SHA-256 mismatch: $actual" }
}
if (Test-Path -LiteralPath $outputPath) { throw "diff output must be fresh: $outputPath" }

$diff = @(& $gitPath -c core.autocrlf=false -c core.safecrlf=false diff --no-index --text --no-ext-diff `
    --src-prefix=a/R6/ --dst-prefix=b/R7/ -- $r6Observer $r7Observer 2>&1)
$exitCode = $LASTEXITCODE
if ($exitCode -ne 1) { throw "git diff returned $exitCode; expected 1 for the frozen differing observers" }
if ($diff.Count -eq 0 -or -not ([string]$diff[0]).StartsWith('diff --git ', [StringComparison]::Ordinal)) {
    throw 'git diff did not return a unified patch'
}
if (@($diff | Where-Object { [string]$_ -match '^(warning|fatal|error):' }).Count -ne 0) {
    throw 'git diff emitted an unexpected diagnostic'
}

[IO.File]::WriteAllLines($outputPath, [string[]]$diff, [Text.UTF8Encoding]::new($false))
'R6_TO_R7_OBSERVER_DIFF=CREATED_EXACT_INPUT_HASHES'
('R6_TO_R7_OBSERVER_DIFF_SHA256={0}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $outputPath).Hash)
