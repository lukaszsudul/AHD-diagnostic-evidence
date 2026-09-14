[CmdletBinding()]
param(
  [string]$HarnessRoot = (Split-Path -Parent $PSCommandPath),
  [string]$OutputReceipt = '',
  [string]$RepoRoot = 'C:\FPGA\V41_G2B_NVP_DIAG2_RM1'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = [IO.Path]::GetFullPath($HarnessRoot)
$build = Join-Path $root 'g2b_nvp_diag2_rm1_build.tcl'
$finalizer = Join-Path $root 'g2b_nvp_diag2_rm1_finalize.tcl'
$launcher = Join-Path $root 'invoke_rm1_one_shot_build.ps1'
$affected = Join-Path $root 'run_rm1_affected_regressions.ps1'
$tclCheck = Join-Path $root 'check_rm1_harness_syntax.tcl'
$binder = Join-Path $root 'bind_rm1_receipts_to_source.ps1'
$schema = Join-Path $root 'RM1_PUBLICATION_READBACK_RECEIPT_SCHEMA.json'
$readme = Join-Path $root 'RM1_BUILD_HARNESS_README.md'
$donor = 'C:\FPGA\G2B_NVP_VIDEO_DIAG1_R3_20260910T200154Z\scripts\g2b_nvp_video_diag1_r3_build.tcl'
$repoRoot = [IO.Path]::GetFullPath($RepoRoot)
$xdc = Join-Path $repoRoot 'xdc\common\g2b_nvp_diag2_rm1_cdc.xdc'
$sourceContractChecker = Join-Path $repoRoot `
    'tests\nvp_video_diag\check_nvp_diag2_rm1_contract.ps1'
$tclsh = 'C:\AMDDesignTools\2025.2\Vivado\bin\xtclsh.bat'
foreach ($path in @($build, $finalizer, $launcher, $binder, $affected,
                     $schema, $readme, $xdc, $sourceContractChecker,
                     $tclCheck, $tclsh, $donor)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "RM1_HARNESS_INPUT_MISSING:$path"
  }
}
if ((Get-FileHash -LiteralPath $donor -Algorithm SHA256).Hash -ne
    '74CA15C2FCEADBC59876249E8EEB08D71D7FD787A0F7B422DC69BE737FB57D59') {
  throw 'RM1_HARNESS_R3_DONOR_FIXED_SHA_MISMATCH'
}

$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
    $launcher, [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count -ne 0) {
  throw "RM1_LAUNCHER_POWERSHELL_SYNTAX:$($parseErrors[0].Message)"
}
$affectedErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
    $affected, [ref]$null, [ref]$affectedErrors)
if ($affectedErrors.Count -ne 0) {
  throw "RM1_AFFECTED_POWERSHELL_SYNTAX:$($affectedErrors[0].Message)"
}
$binderErrors = $null
$binderAst = [Management.Automation.Language.Parser]::ParseFile(
    $binder, [ref]$null, [ref]$binderErrors)
if ($binderErrors.Count -ne 0) {
  throw "RM1_BINDER_POWERSHELL_SYNTAX:$($binderErrors[0].Message)"
}

$snapshotFunctionNames = @(
  'Get-ValidatedReceiptSnapshot',
  'Assert-ReceiptSnapshotsCurrent'
)
$snapshotFunctions = @($binderAst.FindAll({
      param($node)
      $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
      $snapshotFunctionNames -ccontains $node.Name
    }, $true))
if ($snapshotFunctions.Count -ne 2 -or
    @($snapshotFunctionNames | Where-Object {
        @($snapshotFunctions.Name) -cnotcontains $_
      }).Count -ne 0) {
  throw 'RM1_BINDER_SNAPSHOT_FUNCTION_EXTRACTION_FAILED'
}
$snapshotFunctionText = ($snapshotFunctions | Sort-Object Name |
    ForEach-Object { $_.Extent.Text }) -join "`n`n"
$snapshotAdversarialBody = @'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('rm1-binder-snapshot-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($testRoot)
$labels = @('FOCUSED', 'AFFECTED_R3', 'PUBLICATION')
$paths = [ordered]@{}
$utf8 = [Text.UTF8Encoding]::new($false)
$originalBytes = $utf8.GetBytes('{"Result":"PASS","Snapshot":"ORIGINAL"}')
try {
  foreach ($label in $labels) {
    $path = Join-Path $testRoot ($label.ToLowerInvariant() + '.json')
    [IO.File]::WriteAllBytes($path, $originalBytes)
    $paths[$label] = $path
  }
  $snapshots = @(
    Get-ValidatedReceiptSnapshot -Path $paths.FOCUSED -Label FOCUSED
    Get-ValidatedReceiptSnapshot -Path $paths.AFFECTED_R3 -Label AFFECTED_R3
    Get-ValidatedReceiptSnapshot -Path $paths.PUBLICATION -Label PUBLICATION
  )
  if ($snapshots.Count -ne 3 -or
      @($snapshots | Where-Object { $_.Json.Result -cne 'PASS' }).Count -ne 0) {
    throw 'BINDER_SNAPSHOT_MOCK_PARSE_OR_SET_FAILED'
  }
  Assert-ReceiptSnapshotsCurrent -Snapshots $snapshots
  foreach ($label in $labels) {
    $swappedBytes = $utf8.GetBytes(
        ('{"Result":"SWAPPED","Receipt":"' + $label + '"}'))
    [IO.File]::WriteAllBytes([string]$paths[$label], $swappedBytes)
    $failedClosed = $false
    try {
      Assert-ReceiptSnapshotsCurrent -Snapshots $snapshots
    } catch {
      if ($_.Exception.Message -like
          ('RM1_BIND_RECEIPT_CHANGED_AFTER_VALIDATION:' + $label + ':*')) {
        $failedClosed = $true
      } else {
        throw
      }
    } finally {
      [IO.File]::WriteAllBytes([string]$paths[$label], $originalBytes)
    }
    if (-not $failedClosed) {
      throw "BINDER_SNAPSHOT_MOCK_SWAP_FALSE_PASS:$label"
    }
    Assert-ReceiptSnapshotsCurrent -Snapshots $snapshots
    Write-Output "BINDER_SNAPSHOT_SWAP_$label=PASS"
  }
  $omnibusPath = [string]$paths.FOCUSED
  $omnibusAliases = @(
    $omnibusPath,
    $omnibusPath.ToUpperInvariant(),
    $omnibusPath.ToLowerInvariant()
  )
  if (@($omnibusAliases | Sort-Object -CaseSensitive -Unique).Count -lt 2) {
    throw 'BINDER_SNAPSHOT_MOCK_CASE_ALIAS_UNAVAILABLE'
  }
  $omnibusSnapshots = @(
    Get-ValidatedReceiptSnapshot -Path $omnibusAliases[0] -Label FOCUSED
    Get-ValidatedReceiptSnapshot -Path $omnibusAliases[1] -Label AFFECTED_R3
    Get-ValidatedReceiptSnapshot -Path $omnibusAliases[2] -Label PUBLICATION
  )
  $aliasFailedClosed = $false
  try {
    Assert-ReceiptSnapshotsCurrent -Snapshots $omnibusSnapshots
  } catch {
    if ($_.Exception.Message -like 'RM1_BIND_SNAPSHOT_SET_OR_IDENTITY_INVALID:*') {
      $aliasFailedClosed = $true
    } else {
      throw
    }
  }
  if (-not $aliasFailedClosed) {
    throw 'BINDER_SNAPSHOT_MOCK_CASE_ALIAS_OMNIBUS_FALSE_PASS'
  }
  Write-Output 'BINDER_SNAPSHOT_CASE_ALIAS_OMNIBUS=PASS'
} finally {
  if (Test-Path -LiteralPath $testRoot -PathType Container) {
    foreach ($path in @($paths.Values)) {
      if (Test-Path -LiteralPath $path -PathType Leaf) {
        [IO.File]::Delete([string]$path)
      }
    }
    [IO.Directory]::Delete($testRoot, $false)
  }
}
'@
$snapshotAdversarialScript = [scriptblock]::Create(
    $snapshotFunctionText + "`n`n" + $snapshotAdversarialBody)
$snapshotAdversarialOutput = @(& $snapshotAdversarialScript |
    ForEach-Object { "$_" })
if ($snapshotAdversarialOutput.Count -ne 4 -or
    @($snapshotAdversarialOutput | Where-Object {
        $_ -notmatch '^BINDER_SNAPSHOT_(SWAP_(FOCUSED|AFFECTED_R3|PUBLICATION)|CASE_ALIAS_OMNIBUS)=PASS$'
      }).Count -ne 0 -or
    @(@('FOCUSED', 'AFFECTED_R3', 'PUBLICATION') | Where-Object {
        $snapshotAdversarialOutput -cnotcontains "BINDER_SNAPSHOT_SWAP_$_=PASS"
      }).Count -ne 0 -or
    $snapshotAdversarialOutput -cnotcontains
        'BINDER_SNAPSHOT_CASE_ALIAS_OMNIBUS=PASS') {
  throw 'RM1_BINDER_SNAPSHOT_ADVERSARIAL_GATE_FAILED'
}
$snapshotAdversarialOutput | Write-Output

$tclOutput = @(& $tclsh $tclCheck $build $finalizer $xdc 2>&1 | ForEach-Object { "$_" })
$tclExitCode = $LASTEXITCODE
$tclOutputText = $tclOutput -join "`n"
$tclOutput | Write-Output
if ($tclExitCode -ne 0 -or
    ([regex]::Matches($tclOutputText, '(?m)^TCL_SCRIPT_COMPLETE=')).Count -ne 3 -or
    ([regex]::Matches($tclOutputText, '(?m)^BINDING_MOCK_.*=PASS$')).Count -ne 5 -or
    ([regex]::Matches($tclOutputText, '(?m)^PRESEAL_MOCK_.*=PASS$')).Count -ne 5 -or
    ([regex]::Matches($tclOutputText, '(?m)^XDC_MOCK_.*=PASS$')).Count -ne 3 -or
    $tclOutputText -match '(?im)while executing|extra characters after close-brace|invalid command name|MOCK_.*FAILED') {
  throw 'RM1_TCL_SYNTAX_OR_SEMANTIC_GATE_FAILED'
}

$buildText = Get-Content -LiteralPath $build -Raw
$finalText = Get-Content -LiteralPath $finalizer -Raw
$launchText = Get-Content -LiteralPath $launcher -Raw
$binderText = Get-Content -LiteralPath $binder -Raw
$readmeText = Get-Content -LiteralPath $readme -Raw
$xdcText = Get-Content -LiteralPath $xdc -Raw
$affectedSetBlock = [regex]::Match($binderText,
    '(?s)\$requiredAffected\s*=\s*@\((?<body>.*?)\)\s*\$affectedBound').Groups['body'].Value
if ([string]::IsNullOrWhiteSpace($affectedSetBlock)) {
  throw 'RM1_AFFECTED_EXACT_SET_BLOCK_NOT_FOUND'
}
$sourceBlock = [regex]::Match($buildText,
    '(?s)set sv_rel_files \{(?<body>.*?)\}\s*set vhdl_rel_files').Groups['body'].Value
if ([string]::IsNullOrWhiteSpace($sourceBlock)) { throw 'RM1_SOURCE_BLOCK_NOT_FOUND' }

function Require-Count([string]$Text, [string]$Pattern, [int]$Expected,
                       [string]$Label) {
  $actual = ([regex]::Matches($Text, $Pattern)).Count
  if ($actual -ne $Expected) { throw "RM1_HARNESS_${Label}_COUNT:$actual/$Expected" }
}
function Require-Literal([string]$Text, [string]$Value, [string]$Label) {
  if (-not $Text.Contains($Value)) { throw "RM1_HARNESS_LITERAL_MISSING:$Label" }
}

function Require-MatchBlock([string]$Text, [string]$Pattern, [string]$Label) {
  $match = [regex]::Match($Text, $Pattern)
  if (-not $match.Success -or [string]::IsNullOrWhiteSpace($match.Groups['body'].Value)) {
    throw "RM1_HARNESS_BLOCK_NOT_FOUND:$Label"
  }
  return $match.Groups['body'].Value
}

$preVivadoInputBlock = Require-MatchBlock $launchText `
    '(?s)\$preVivadoInputs\s*=\s*\[ordered\]@\{(?<body>.*?)\r?\n\}' `
    'LAUNCHER_PRE_VIVADO_INPUTS'
foreach ($entry in ([ordered]@{
    FOCUSED_RECEIPT = '$focused'
    AFFECTED_R3_RECEIPT = '$affected'
    RECEIPT_BINDING = '$bindingReceipt'
    PUBLICATION_READBACK_RECEIPT = '$publication'
    R3_DONOR_BUILD_TCL = '$donor'
    BUILD_HARNESS = '$buildTcl'
    FINALIZER = '$finalizeTcl'
    LAUNCHER = '[IO.Path]::GetFullPath($PSCommandPath)'
    BINDER = '$binder'
    AFFECTED_RUNNER = '$affectedRunner'
    STATIC_CHECKER = '$staticChecker'
    TCL_SYNTAX_CHECKER = '$tclSyntaxChecker'
    PUBLICATION_SCHEMA = '$publicationSchema'
    README = '$readme'
  }).GetEnumerator()) {
  Require-Count $preVivadoInputBlock `
      ("(?m)^\s*" + $entry.Key + "\s*=\s*" + [regex]::Escape($entry.Value) + "\s*$") `
      1 "PRE_VIVADO_INPUT_$($entry.Key)"
}

$binderChangeBlock = Require-MatchBlock $binderText `
    '(?s)\$authorizedChanges\s*=\s*\[ordered\]@\{(?<body>.*?)\r?\n\}' `
    'BINDER_AUTHORIZED_CHANGES'
$launcherChangeBlock = Require-MatchBlock $launchText `
    '(?s)\$authorizedChanges\s*=\s*\[ordered\]@\{(?<body>.*?)\r?\n\}' `
    'LAUNCHER_AUTHORIZED_CHANGES'
$buildChangeBlock = Require-MatchBlock $buildText `
    '(?s)set authorized_changes\s+\[dict create(?<body>.*?)\]\s*\r?\n\s*set sv_rel_files' `
    'BUILD_AUTHORIZED_CHANGES'
$finalChangeBlock = Require-MatchBlock $finalText `
    '(?s)set authorized_changes\s+\[dict create(?<body>.*?)\]\s*\r?\n\s*proc read_text' `
    'FINAL_AUTHORIZED_CHANGES'

$authorizedChangeStatus = [ordered]@{
  'rtl/g2b/v41_g2b_onech_c2h.sv' = 'M'
  'rtl/top/ahd_capture_top_xdma.sv' = 'M'
  'rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv' = 'A'
  'rtl/diagnostic/g2b_nvp_rm1_route_controller.sv' = 'A'
  'rtl/g2b/g2b_nvp_video_diag2_rm1.sv' = 'A'
  'xdc/common/g2b_nvp_diag2_rm1_cdc.xdc' = 'A'
  'tests/nvp_video_diag/check_nvp_diag2_rm1_contract.ps1' = 'A'
  'tests/nvp_video_diag/tb_g2b_nvp_diag2_rm1_focused.sv' = 'A'
  'tests/nvp_video_diag/tb_g2b_nvp_rm1_route_controller.sv' = 'A'
  'tests/nvp_video_diag/tb_g2b_nvp_rm1_parser_tap.sv' = 'A'
  'tests/nvp_video_diag/run_nvp_diag2_rm1_focused_gate.ps1' = 'A'
}
foreach ($entry in $authorizedChangeStatus.GetEnumerator()) {
  Require-Count $binderChangeBlock `
      ("(?m)^\s*'" + [regex]::Escape($entry.Key) + "'\s*=\s*'" + $entry.Value + "'\s*$") `
      1 "BINDER_CHANGED_$($entry.Key)"
  Require-Count $launcherChangeBlock `
      ("(?m)^\s*'" + [regex]::Escape($entry.Key) + "'\s*=\s*'" + $entry.Value + "'\s*$") `
      1 "LAUNCHER_CHANGED_$($entry.Key)"
  Require-Count $buildChangeBlock `
      ("(?m)^\s*" + [regex]::Escape($entry.Key) + "\s+" + $entry.Value + "\s*\\?\s*$") `
      1 "BUILD_CHANGED_$($entry.Key)"
  Require-Count $finalChangeBlock `
      ("(?m)^\s*" + [regex]::Escape($entry.Key) + "\s+" + $entry.Value + "\s*\\?\s*$") `
      1 "FINAL_CHANGED_$($entry.Key)"
}
foreach ($pair in @(
    @($binderText, 'BINDER'), @($launchText, 'LAUNCHER'),
    @($buildText, 'BUILD'), @($finalText, 'FINAL'))) {
  Require-Literal $pair[0] 'fc37d815b5d64ef90dfbd99c57ae4cc09567b56f' "$($pair[1])_EXPECTED_PARENT"
  Require-Literal $pair[0] 'rev-list' "$($pair[1])_DIRECT_PARENT"
  Require-Literal $pair[0] 'diff-tree' "$($pair[1])_DIFF_TREE"
  Require-Literal $pair[0] '--find-renames' "$($pair[1])_RENAME_DETECTION"
  Require-Literal $pair[0] '--find-copies' "$($pair[1])_COPY_DETECTION"
  Require-Literal $pair[0] '--find-copies-harder' "$($pair[1])_HARD_COPY_DETECTION"
  Require-Literal $pair[0] '11' "$($pair[1])_EXACT_11"
}
Require-Literal $binderText '$authorizedChanges.Keys -ccontains $relative' `
    'BINDER_CASE_SENSITIVE_CHANGED_PATH'
Require-Literal $launchText '$authorizedChanges.Keys -ccontains $relative' `
    'LAUNCHER_CASE_SENSITIVE_CHANGED_PATH'
Require-Literal $binderText 'AuthorizedChangedSetBinding' 'BINDER_CHANGED_SET_RECEIPT'
Require-Literal $binderText 'DirectParentBinding' 'BINDER_DIRECT_PARENT_RECEIPT'
Require-Literal $binderText 'function Get-ValidatedReceiptSnapshot' `
    'BINDER_BYTE_SNAPSHOT_FUNCTION'
Require-Literal $binderText '[IO.File]::ReadAllBytes($normalized)' `
    'BINDER_SINGLE_SNAPSHOT_READ'
Require-Literal $binderText '[Security.Cryptography.SHA256]::HashData($bytes)' `
    'BINDER_SNAPSHOT_BYTE_SHA'
Require-Literal $binderText '$decoder.GetString($bytes)' 'BINDER_SNAPSHOT_BYTE_DECODE'
Require-Literal $binderText 'ConvertFrom-Json -InputObject $text' `
    'BINDER_SNAPSHOT_JSON_PARSE'
Require-Count $binderText '(?m)^\$(focused|affected|publication)Snapshot = Get-ValidatedReceiptSnapshot ' 3 `
    'BINDER_EXACT_THREE_SNAPSHOT_CALLS'
Require-Literal $binderText '$focused = $focusedSnapshot.Json' 'BINDER_FOCUSED_PARSE_SNAPSHOT'
Require-Literal $binderText '$affected = $affectedSnapshot.Json' 'BINDER_AFFECTED_PARSE_SNAPSHOT'
Require-Literal $binderText '$publication = $publicationSnapshot.Json' `
    'BINDER_PUBLICATION_PARSE_SNAPSHOT'
foreach ($snapshot in @('focusedSnapshot', 'affectedSnapshot', 'publicationSnapshot')) {
  Require-Count $binderText ('ReceiptSHA256 = \$' + $snapshot + '\.SHA256') 1 `
      "BINDER_RETAINED_VALIDATED_SHA_$snapshot"
}
Require-Literal $binderText 'function Assert-ReceiptSnapshotsCurrent' `
    'BINDER_FINAL_LIVE_REHASH_FUNCTION'
Require-Literal $binderText 'RM1_BIND_RECEIPT_CHANGED_AFTER_VALIDATION' `
    'BINDER_FINAL_LIVE_REHASH_FAIL_CLOSED'
Require-Count $binderText '(?s)function Assert-ReceiptSnapshotsCurrent.*?\$seenPaths\s*=.*?StringComparer\]::OrdinalIgnoreCase' 1 `
    'BINDER_WINDOWS_CASEFOLD_PATH_UNIQUENESS'
Require-Count $binderText '(?s)\$receiptJson = .*?\$encoding = .*?Assert-ReceiptSnapshotsCurrent -Snapshots \$receiptSnapshots\s*\$stream = \[IO\.File\]::Open\(\$outputPath, \[IO\.FileMode\]::CreateNew' 1 `
    'BINDER_FINAL_REHASH_IMMEDIATELY_BEFORE_CREATE_NEW'
Require-Count $binderText 'Get-FileHash -LiteralPath \$(focusedPath|affectedPath|publicationPath)' 0 `
    'BINDER_NO_LATE_LIVE_HASH_BLESSING'
Require-Literal $launchText 'Assert-AuthorizedChangedSet' 'LAUNCHER_CHANGED_SET_CALL'
Require-Literal $buildText 'set sealed_changed_set [rm1_changed_set_current]' 'BUILD_CHANGED_SET_CALL'
Require-Literal $finalText 'set sealed_changed_set [changed_set_current]' 'FINAL_CHANGED_SET_CALL'
Require-Literal $launchText 'function Assert-PreVivadoSealCurrent' `
    'LAUNCHER_PRE_VIVADO_RECHECK_FUNCTION'
Require-Literal $launchText '$Inputs.Count -ne 14' 'LAUNCHER_ASSERT_EXACT_14_INPUTS'
Require-Literal $launchText '$preVivadoInputs.Count -ne 14' 'LAUNCHER_EXACT_14_INPUTS'
Require-Count $launchText '(?s)\$sealedPaths\s*=.*?StringComparer\]::OrdinalIgnoreCase' 1 `
    'LAUNCHER_WINDOWS_CASEFOLD_PATH_UNIQUENESS'
Require-Literal $launchText '$preVivadoRows | Set-Content -LiteralPath $preVivadoSeal' `
    'LAUNCHER_PERSISTED_PRE_VIVADO_SEAL'
Require-Literal $launchText '$preVivadoSealSHA = (Get-FileHash -LiteralPath $preVivadoSeal' `
    'LAUNCHER_PRE_VIVADO_SEAL_SHA'
Require-Count $launchText '(?m)^\s*Assert-PreVivadoSealCurrent\s+-Inputs\s+' 3 `
    'LAUNCHER_PRE_VIVADO_RECHECK_CALLS'
Require-Literal $launchText '$publication $donor $preVivadoSeal $preVivadoSealSHA' `
    'LAUNCHER_BUILD_SEAL_ARGUMENTS'
foreach ($hashArgument in @(
    '$preVivadoHashes.FOCUSED_RECEIPT', '$preVivadoHashes.AFFECTED_R3_RECEIPT',
    '$preVivadoHashes.RECEIPT_BINDING',
    '$preVivadoHashes.PUBLICATION_READBACK_RECEIPT')) {
  Require-Count $launchText ([regex]::Escape($hashArgument)) 1 `
      "LAUNCHER_BUILD_HASH_ARG_$hashArgument"
}
Require-Literal $launchText '$handoffSHA = (Get-FileHash -LiteralPath $handoff' `
    'LAUNCHER_HANDOFF_SHA_PIN'
Require-Literal $launchText '$SourceCommit $SourceTree $buildTcl $handoffSHA' `
    'LAUNCHER_FINALIZER_HANDOFF_SHA_ARG'
Require-Literal $buildText 'if {$argc != 16}' 'BUILD_EXACT_AUTHORITY_ARGC'
Require-Literal $buildText 'proc rm1_pre_vivado_seal_gate' 'BUILD_PRE_VIVADO_SEAL_GATE'
Require-Literal $buildText '[dict size $expected_paths] != 14' 'BUILD_EXACT_14_PRE_VIVADO_INPUTS'
Require-Literal $buildText '[sha256_file $pre_vivado_seal] ne $expected_pre_vivado_seal_sha' `
    'BUILD_LAUNCHER_PINNED_SEAL_SHA'
Require-Literal $buildText 'R3_DONOR_BUILD_TCL $donor_build_tcl' `
    'BUILD_PRE_VIVADO_DONOR_PATH'
Require-Literal $buildText 'R3_DONOR_BUILD_TCL $expected_donor_sha' `
    'BUILD_PRE_VIVADO_DONOR_SHA'
Require-Count $buildText '\[rm1_bootstrap_sha256 \$donor_build_tcl\] ne \$expected_donor_sha' 2 `
    'BUILD_DONOR_FIXED_SHA_BEFORE_AND_AFTER_IMPORT'
Require-Literal $buildText 'immutable R3 donor harness changed during procedure import' `
    'BUILD_DONOR_POST_IMPORT_GATE'
Require-Literal $buildText 'set observed_casefold_paths [dict create]' `
    'BUILD_CASEFOLD_PATH_SET'
Require-Literal $buildText 'set casefold_path [string tolower $normalized_expected_path]' `
    'BUILD_CASEFOLD_PATH_KEY'
Require-Literal $buildText '[dict size $observed_casefold_paths] != 14' `
    'BUILD_EXACT_14_CASEFOLD_PATHS'
Require-Literal $buildText 'proc rm1_json_string_field' 'BUILD_STRICT_JSON_STRING_PARSER'
Require-Literal $buildText 'JSON string field cardinality mismatch' 'BUILD_DUPLICATE_JSON_FIELD_REJECTION'
Require-Literal $buildText 'proc rm1_binding_receipt_gate' 'BUILD_BINDING_EXACT_GATE'
Require-Literal $buildText 'if {$recorded_path ne $expected_path}' 'BUILD_BINDING_EXACT_PATH_COMPARE'
Require-Literal $buildText '$recorded_sha ne $current_sha' 'BUILD_BINDING_CURRENT_SHA_COMPARE'
foreach ($authority in ([ordered]@{
    FOCUSED = 'FocusedReceipt FocusedReceiptSHA256 $focused_receipt $focused_sha'
    AFFECTED_R3 = 'AffectedR3Receipt AffectedR3ReceiptSHA256 $affected_receipt $affected_sha'
    PUBLICATION = 'PublicationReadbackReceipt PublicationReadbackReceiptSHA256'
  }).GetEnumerator()) {
  Require-Literal $buildText ("[list " + $authority.Key + " " + $authority.Value) `
      "BUILD_BINDING_$($authority.Key)_EXACT_ROW"
}
Require-Count $buildText '"BINDING_\$\{name\}_CURRENT=PASS"' 1 `
    'BUILD_BINDING_CURRENT_PASS_EMISSION'
Require-Count $buildText '(?s)set pre_vivado_seal_rows \[rm1_pre_vivado_seal_gate\].*?set binding_validation_rows \[rm1_binding_receipt_gate.*?set sealed_inputs \[rm1_canonical_inputs\].*?file mkdir \$build_root' 1 `
    'BUILD_AUTHORITY_BEFORE_OUTPUT_CREATION'
Require-Literal $buildText '$binding_receipt $publication_receipt $pre_vivado_seal' `
    'BUILD_MANIFEST_INCLUDES_PRE_VIVADO_SEAL'
foreach ($handoffField in @(
    'PRE_VIVADO_SEAL_SHA256=', 'FOCUSED_RECEIPT_SHA256=',
    'AFFECTED_R3_RECEIPT_SHA256=', 'RECEIPT_BINDING_SHA256=',
    'PUBLICATION_READBACK_RECEIPT_SHA256=', 'R3_DONOR_BUILD_TCL=',
    'R3_DONOR_BUILD_TCL_SHA256=')) {
  Require-Literal $buildText $handoffField "BUILD_HANDOFF_AUTHORITY_$handoffField"
}
Require-Literal $finalText 'if {$argc != 7}' 'FINAL_EXACT_HANDOFF_ARGC'
Require-Literal $finalText '[sha256_file $handoff_path] ne $expected_handoff_sha' `
    'FINAL_LAUNCHER_PINNED_HANDOFF_SHA'
Require-Literal $finalText 'proc final_authority_seal_current' 'FINAL_AUTHORITY_RECHECK_PROC'
Require-Literal $finalText '[dict size $sealed_authority_hashes] != 6' `
    'FINAL_EXACT_AUTHORITY_COMPONENT_COUNT'
Require-Count $finalText '\[final_authority_seal_current\]' 3 `
    'FINAL_AUTHORITY_RECHECK_CALLS'
foreach ($authorityField in @(
    'PRE_VIVADO_SEAL PRE_VIVADO_SEAL_SHA256',
    'FOCUSED_RECEIPT FOCUSED_RECEIPT_SHA256',
    'AFFECTED_R3_RECEIPT AFFECTED_R3_RECEIPT_SHA256',
    'RECEIPT_BINDING RECEIPT_BINDING_SHA256',
    'PUBLICATION_READBACK_RECEIPT PUBLICATION_READBACK_RECEIPT_SHA256',
    'R3_DONOR_BUILD_TCL R3_DONOR_BUILD_TCL_SHA256')) {
  Require-Count $finalText ([regex]::Escape($authorityField)) 1 `
      "FINAL_AUTHORITY_FIELD_$authorityField"
}
Require-Literal $finalText '[list R3_DONOR_BUILD_TCL_SHA256 $expected_donor_sha]' `
    'FINAL_DONOR_CONSTANT_SHA_GATE'
Require-Literal $finalText 'set sealed_harness_casefold_paths [dict create]' `
    'FINAL_HARNESS_CASEFOLD_PATH_SET'
Require-Literal $finalText '[dict size $sealed_harness_casefold_paths] != 9' `
    'FINAL_EXACT_9_CASEFOLD_HARNESS_PATHS'
Require-Literal $finalText 'set sealed_authority_casefold_paths [dict create]' `
    'FINAL_AUTHORITY_CASEFOLD_PATH_SET'
Require-Literal $finalText '[dict size $sealed_authority_casefold_paths] != 6' `
    'FINAL_EXACT_6_CASEFOLD_AUTHORITY_PATHS'

foreach ($guard in @(
    'RM1_CDC_XDC_SYNC1_CELL_COUNT=', 'RM1_CDC_XDC_SYNC1_D_PIN_COUNT=',
    'RM1_CDC_XDC_SESSION_CELL_COUNT=', 'RM1_CDC_XDC_ROUTE_CELL_COUNT=',
    'RM1_CDC_XDC_WINDOW_CELL_COUNT=', 'RM1_CDC_XDC_MAILBOX_CELL_COUNT=',
    'RM1_CDC_XDC_MAILBOX_D_PIN_COUNT=')) {
  Require-Literal $xdcText $guard "XDC_GUARD_$guard"
}
Require-Literal $xdcText 'foreach {rm1_vector_leaf rm1_vector_width}' 'XDC_PAIRED_VECTOR_LOOP'
Require-Literal $xdcText 'session_source 16' 'XDC_SESSION_16'
Require-Literal $xdcText 'route_source 3' 'XDC_ROUTE_3'
Require-Literal $xdcText 'window_source 2' 'XDC_WINDOW_2'
Require-Literal $xdcText 'set rm1_arm_mailbox_cells [concat' 'XDC_COLLECTION_CONCAT'
Require-Count $xdcText '(?m)^\s*set_false_path\s+-to\s+\$rm1_sync1_d\s*$' 1 `
    'XDC_SYNC1_FALSE_PATH_TARGET'
Require-Count $xdcText '(?m)^\s*set_false_path\s+-to\s+\$rm1_arm_mailbox_d\s*$' 1 `
    'XDC_MAILBOX_FALSE_PATH_TARGET'
Require-Count $xdcText '(?m)^\s*set_false_path\s+-to\s+' 2 'XDC_FALSE_PATH_COMMANDS'
Require-Count $xdcText '(?m)^\s*(set_input_delay|set_output_delay|create_clock)\b' 0 'XDC_UNAUTHORIZED_TIMING_CREATION'
Require-Count $xdcText '(?im)^\s*set_false_path.*\b(nvp_scl|nvp_sda|nvp_rst|sys_rst_n)\b' 0 `
    'XDC_CONTROL_PORT_FALSE_PATH'

foreach ($literal in @(
    'rtl/v41/nvp_i2c_fixed_master.sv',
    'rtl/diagnostic/g2b_nvp_rm1_route_controller.sv',
    'rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv',
    'rtl/g2b/g2b_nvp_video_diag2_rm1.sv')) {
  Require-Literal $sourceBlock $literal "SOURCE_$literal"
}
foreach ($forbidden in @('scan1', 'acq1', 'mode1')) {
  if ($sourceBlock -match $forbidden) { throw "RM1_FORBIDDEN_SOURCE_INCLUDED:$forbidden" }
}
Require-Count $buildText '(?m)^\s*xdc/common/g2b_nvp_diag2_rm1_cdc\.xdc\s*$' 1 'XDC'
Require-Literal $buildText 'ENABLE_NVP_VIDEO_DIAG2_RM1=1' 'RM1_GENERIC_ON'
Require-Literal $buildText 'ENABLE_NVP_VIDEO_DIAGNOSTIC=0' 'R3_GENERIC_OFF'
Require-Literal $buildText 'ENABLE_RTRACK_DIAGNOSTICS=0' 'RTRACK_GENERIC_OFF'
Require-Literal $buildText 'set lut_hard_max 20384' 'LUT_HARD_98'
Require-Literal $buildText 'set lut_preferred_max 19760' 'LUT_PREFERRED_95'
Require-Literal $buildText 'run_exact_routed_bus_skew_gate' 'BUS_SKEW_EXACT'
Require-Literal $buildText 'skew_pass != 11' 'BUS_SKEW_11'
Require-Literal $buildText 'promoted_pass != 17' 'PROMOTED_17'
Require-Literal $buildText 'rm1_cdc_gate' 'RM1_CDC_GATE'
Require-Literal $buildText 'ABORT_ACK_SYNC1_AXI' 'CDC_ABORT_ACK_DISPOSITION'
foreach ($textAndLabel in @(@($buildText, 'BUILD'), @($finalText, 'FINAL'))) {
  $text = $textAndLabel[0]
  $label = $textAndLabel[1]
  Require-Literal $text 'STARTPOINT_PIN' "${label}_CDC_SOURCE_PROPERTY"
  Require-Literal $text 'ENDPOINT_PIN' "${label}_CDC_DESTINATION_PROPERTY"
  Require-Literal $text 'property_or_unknown EXCEPTION' "${label}_CDC_EXCEPTION_PROPERTY"
  Require-Literal $text 'CDC-3|INFO|FALSE PATH|' "${label}_CDC3_INFO_EXACT"
  Require-Literal $text 'CDC-15|WARNING|FALSE PATH|' "${label}_CDC15_WARNING_EXACT"
  Require-Literal $text 'dict size $expected] != 33' "${label}_CDC_EXACT_33"
  Require-Literal $text '{$bit < 16}' "${label}_CDC_SESSION_16"
  Require-Literal $text '{$bit < 3}' "${label}_CDC_ROUTE_3"
  Require-Literal $text '{$bit < 2}' "${label}_CDC_WINDOW_2"
  foreach ($endpoint in @(
      'CLEAR_TOGGLE_AXI_REG/C CLEAR_SYNC1_SOURCE_REG/D',
      'ARM_TOGGLE_AXI_REG/C ARM_SYNC1_SOURCE_REG/D',
      'FREEZE_TOGGLE_AXI_REG/C FREEZE_SYNC1_SOURCE_REG/D',
      'FREEZE_MANUAL_TOGGLE_AXI_REG/C FREEZE_MANUAL_SYNC1_SOURCE_REG/D',
      'ACK_TOGGLE_AXI_REG/C ACK_SYNC1_SOURCE_REG/D',
      'ABORT_EPOCH_TOGGLE_AXI_REG/C ABORT_EPOCH_SYNC1_SOURCE_REG/D',
      'ARMED_SOURCE_REG/C ARMED_SYNC1_AXI_REG/D',
      'DONE_TOGGLE_SOURCE_REG/C DONE_SYNC1_AXI_REG/D',
      'SNAPSHOT_VALID_SOURCE_REG/C VALID_SYNC1_AXI_REG/D',
      'TRACE_OVERFLOW_SOURCE_REG/C OVERFLOW_SYNC1_AXI_REG/D',
      'ACK_DONE_TOGGLE_SOURCE_REG/C ACK_DONE_SYNC1_AXI_REG/D',
      'ABORT_ACK_TOGGLE_SOURCE_REG/C ABORT_ACK_SYNC1_AXI_REG/D')) {
    Require-Count $text ([regex]::Escape($endpoint)) 1 "${label}_CDC_ENDPOINT_$endpoint"
  }
  if ($text.Contains('severity ne "UNKNOWN"') -or $text.Contains('EXACT_DESTINATION=')) {
    throw "RM1_HARNESS_BROAD_CDC_DISPOSITION_REMAINS:$label"
  }
}
Require-Literal $finalText 'set final_cdc_findings [final_cdc_gate]' 'FINAL_INDEPENDENT_CDC_CALL'
foreach ($structural in @(
    @($buildText, 'BUILD', 'proc rm1_expected_xdc_destinations',
      'RM1_XDC_SYNC1_CELLS=12/12', 'RM1_XDC_SYNC1_D_PINS=12/12',
      'RM1_XDC_MAILBOX_CELLS=21/21', 'RM1_XDC_MAILBOX_D_PINS=21/21'),
    @($finalText, 'FINAL', 'proc final_expected_xdc_destinations',
      'RM1_SYNC1_CELLS=12/12', 'RM1_SYNC1_D_PINS=12/12',
      'RM1_MAILBOX_CELLS=21/21', 'RM1_MAILBOX_D_PINS=21/21'))) {
  $text = $structural[0]
  $label = $structural[1]
  foreach ($literal in $structural[2..6]) {
    Require-Literal $text $literal "${label}_INDEPENDENT_XDC_STRUCTURE_$literal"
  }
  Require-Literal $text 'get_pins -quiet -of_objects' "${label}_RESOLVED_D_PINS"
  Require-Literal $text 'REF_PIN_NAME == D' "${label}_D_PIN_FILTER"
}
Require-Literal $buildText 'RM1_XDC_DESTINATION_PINS=33/33' 'BUILD_XDC_DESTINATION_PIN_GATE'
Require-Literal $finalText 'RM1_DESTINATION_PINS=33/33' 'FINAL_DESTINATION_PIN_GATE'
Require-Literal $buildText 'RM1_FALSE_PATH_DESTINATION_PINS=$false_path_destination_pins/33' 'BUILD_EXCEPTION_COVERAGE'
Require-Literal $finalText 'RM1_FALSE_PATH_DESTINATION_PINS=$false_path_destination_pins/33' 'FINAL_EXCEPTION_COVERAGE'
foreach ($textAndLabel in @(@($buildText, 'BUILD'), @($finalText, 'FINAL'))) {
  Require-Literal $textAndLabel[0] '$false_path_destination_pins == 33' `
      "$($textAndLabel[1])_EXACT_FALSE_PATH_PREDICATE"
}

foreach ($textAndLabel in @(@($buildText, 'BUILD'), @($finalText, 'FINAL'))) {
  $text = $textAndLabel[0]
  $label = $textAndLabel[1]
  Require-Count $text '(?s)report_timing_summary\s+-delay_type\s+min_max.*?-report_unconstrained' 1 "${label}_REPORT_UNCONSTRAINED"
  Require-Count $text '(?m)^\s*check_timing\s+-verbose\s+-file\s+' 1 "${label}_STANDALONE_CHECK_TIMING"
  Require-Literal $text 'no_clock 0 constant_clock 0 pulse_width_clock 2' "${label}_CHECK_TIMING_FIRST_CATEGORIES"
  Require-Literal $text 'unconstrained_internal_endpoints 0 no_input_delay 0 no_output_delay 0' "${label}_CHECK_TIMING_IO_CATEGORIES"
  Require-Literal $text 'multiple_clock 0 generated_clocks 0 loops 0 partial_input_delay 0' "${label}_CHECK_TIMING_REMAINING_CATEGORIES"
  Require-Literal $text 'partial_output_delay 0 latch_loops 0' "${label}_CHECK_TIMING_LAST_CATEGORIES"
  Require-Literal $text 'raw unconstrained path table is not empty' "${label}_RAW_UNCONSTRAINED_TABLE_MUST_BE_EMPTY"
  Require-Literal $text 'RAW_NO_INPUT_DELAY=' "${label}_RAW_NO_INPUT_DELAY"
  Require-Literal $text 'RAW_NO_OUTPUT_DELAY=' "${label}_RAW_NO_OUTPUT_DELAY"
  Require-Literal $text 'RAW_UNCONSTRAINED_PATH_TABLE_ROWS=' "${label}_RAW_UNCONSTRAINED_ROWS"
  Require-Literal $text 'RAW_UNCONSTRAINED_ENDPOINTS=0' "${label}_RAW_UNCONSTRAINED_ZERO"
  Require-Literal $text 'UNCONSTRAINED_GATE=PASS' "${label}_UNCONSTRAINED_GATE"
  Require-Literal $text '"TNS=[format %.3f $tns]"' "${label}_DERIVED_TNS"
  Require-Literal $text '"THS=[format %.3f $ths]"' "${label}_DERIVED_THS"
}
if ($buildText.Contains('EXACT_CONTROL_IO_DISPOSITION') -or
    $finalText.Contains('EXACT_CONTROL_IO_DISPOSITION') -or
    $buildText.Contains('no_input_delay 3') -or $finalText.Contains('no_input_delay 3') -or
    $buildText.Contains('no_output_delay 3') -or $finalText.Contains('no_output_delay 3')) {
  throw 'RM1_HARNESS_UNAUTHORIZED_UNCONSTRAINED_DISPOSITION_REMAINS'
}
Require-Literal $finalText 'set unconstrained [final_unconstrained_gate]' 'FINAL_INDEPENDENT_UNCONSTRAINED_CALL'
foreach ($textAndLabel in @(@($buildText, 'BUILD'), @($finalText, 'FINAL'))) {
  $text = $textAndLabel[0]
  $label = $textAndLabel[1]
  Require-Literal $text 'set unknown_or_unrecognized 0' "${label}_UNKNOWN_SEVERITY_COUNTER"
  Require-Literal $text 'default { incr unknown_or_unrecognized }' `
      "${label}_UNKNOWN_SEVERITY_INCREMENT"
  Require-Count $text '(?s)set result \[expr \{\$errors == 0 && \$critical == 0 &&\s*\$unknown_or_unrecognized == 0 \? \{PASS\} : \{FAIL\}\}\]' 1 `
      "${label}_UNKNOWN_SEVERITY_FAIL_PREDICATE"
  Require-Count $text '(?m)^\s*report_drc\s+-file\s+' 1 "${label}_DRC_REPORT_INVOCATION"
  Require-Count $text '(?m)^\s*report_methodology\s+-file\s+' 1 `
      "${label}_METHODOLOGY_REPORT_INVOCATION"
  Require-Literal $text 'get_drc_violations' "${label}_DRC_QUERY"
  Require-Literal $text 'get_methodology_violations' "${label}_METHODOLOGY_QUERY"
  Require-Literal $text 'UNKNOWN_OR_UNRECOGNIZED_SEVERITY=$unknown_or_unrecognized' `
      "${label}_UNKNOWN_SEVERITY_RECEIPT"
}
Require-Literal $buildText 'lassign [rm1_drc_methodology_gate]' 'BUILD_DRC_METHODOLOGY_GATE_CALL'
Require-Literal $finalText 'lassign [final_drc_methodology_gate]' 'FINAL_DRC_METHODOLOGY_GATE_CALL'
Require-Literal $binderText 'RM1_BIND_DUPLICATE_AFFECTED_PATH' 'AFFECTED_DUPLICATE_GUARD'
Require-Literal $binderText 'RM1_BIND_AFFECTED_SET_MISMATCH' 'AFFECTED_EXACT_SET_GUARD'
Require-Literal $binderText '$affectedBound.Count -ne 11' 'AFFECTED_EXACT_COUNT'
foreach ($affectedInput in @(
    'tests/nvp_video_diag/run_nvp_video_diag1_sim.ps1',
    'tests/nvp_video_diag/check_nvp_diag2_rm1_contract.ps1',
    'rtl/g2b/g2b_nvp_video_diag.sv',
    'rtl/v41/axi_lite_host_bridge.sv',
    'rtl/g2b/v41_g2b_mmio_router.sv',
    'tests/nvp_video_diag/tb_g2b_nvp_video_diag.sv',
    'tests/nvp_video_diag/tb_nvp_i2c_fixed_master.sv',
    'tests/nvp_video_diag/tb_g2b_nvp_video_diag_mmio_protocol.sv',
    'tests/nvp_video_diag/tb_g2b_nvp_video_diag_axi_integration.sv',
    'tests/nvp_video_diag/run_nvp_video_diag_r3_sim.ps1',
    'tests/nvp_video_diag/check_nvp_video_diag_r3_contract.ps1')) {
  Require-Count $affectedSetBlock ([regex]::Escape("'$affectedInput'")) 1 `
      "AFFECTED_INPUT_$affectedInput"
}
Require-Literal $buildText 'rm1_drc_methodology_gate' 'DRC_METHODOLOGY_GATE'
Require-Literal $buildText 'rm1_profile_gate POST_SYNTH' 'POST_SYNTH_PROFILE'
Require-Literal $buildText 'rm1_profile_gate POST_OPT' 'POST_OPT_PROFILE'
Require-Literal $buildText 'rm1_profile_gate ROUTED' 'ROUTED_PROFILE'
Require-Literal $buildText 'R3_CORE_COUNT=' 'R3_ABSENCE'
Require-Literal $buildText 'RM1_SNAPSHOT_BRAM_PRIMITIVE_COUNT=' 'BRAM_PRESENCE'
Require-Count $buildText '(?m)^\s*synth_design\s' 1 'SYNTH_DESIGN'
Require-Count $buildText '(?m)^\s*opt_design\s*$' 1 'OPT_DESIGN'
Require-Count $buildText '(?m)^\s*place_design\s*$' 1 'PLACE_DESIGN'
Require-Count $buildText '(?m)^\s*phys_opt_design\s*$' 1 'PHYS_OPT_DESIGN'
Require-Count $buildText '(?m)^\s*route_design\s' 1 'ROUTE_DESIGN'
Require-Count $buildText '(?m)^\s*write_bitstream\s' 0 'BUILD_BITSTREAM_WRITER'
Require-Count $finalText '(?m)^\s*write_checkpoint\s' 1 'FINAL_SIGNED_DCP_WRITER'
Require-Count $finalText '(?m)^\s*write_bitstream\s' 1 'FINAL_BITSTREAM_WRITER'
Require-Count $launchText '(?m)^\s*& \$vivadoExe ' 2 'VIVADO_PROCESS'
Require-Literal $launchText 'PASS_ONE_DCP_ONE_BITSTREAM' 'ONE_DCP_ONE_BIT'
Require-Literal $launchText 'HARDWARE_ACCESSED=NO' 'NO_HARDWARE'
Require-Literal $launchText 'PublicationReadbackReceipt' 'PUBLICATION_RECEIPT_REQUIRED'
Require-Literal $launchText 'ls-remote --exit-code' 'LIVE_REMOTE_REF_READBACK'
Require-Literal $launchText 'bind_rm1_receipts_to_source.ps1' 'RECEIPT_BINDER'
Require-Literal $buildText 'FocusedHashAfterBinding' 'FOCUSED_HASH_BINDING_REQUIRED'
Require-Literal $buildText 'CommitPinnedBlobReadback' 'COMMIT_BLOB_READBACK_REQUIRED'
Require-Literal $buildText 'g2b_nvp_diag2_rm1_finalize.tcl' 'FINALIZER_SEALED'
Require-Literal $finalText 'harness component not sealed by build input manifest' 'FINALIZER_SELF_SEAL'
Require-Literal $finalText 'proc final_harness_seal_current' 'FINALIZER_FULL_HARNESS_RECHECK_PROC'
Require-Literal $finalText '[dict size $sealed_harness_hashes] != 9' `
    'FINALIZER_EXACT_HARNESS_COMPONENT_COUNT'
Require-Count $finalText '\[final_harness_seal_current\]' 3 `
    'FINALIZER_FULL_HARNESS_RECHECK_CALLS'
Require-Literal $readmeText 'one direct child of' 'README_DIRECT_PARENT'
Require-Literal $readmeText 'must be raw zero' 'README_RAW_ZERO_CATEGORIES'
Require-Literal $readmeText 'Unconstrained Path Table must be empty' `
    'README_EMPTY_UNCONSTRAINED_TABLE'
Require-Literal $readmeText '14-entry pre-Vivado seal' 'README_EXACT_14_PRE_VIVADO_SEAL'
Require-Literal $readmeText 'same six authority files' 'README_EXACT_6_FINAL_AUTHORITY'
Require-Literal $readmeText 'both before and after importing its procedures' `
    'README_DONOR_PRE_POST_IMPORT_SHA'
Require-Literal $readmeText 'exactly once as a byte array' `
    'README_BINDER_SINGLE_BYTE_SNAPSHOT'
Require-Literal $readmeText 'immediately before a `CreateNew` output write' `
    'README_BINDER_FINAL_REHASH_BOUNDARY'
Require-Literal $readmeText 'all three cases to fail closed' `
    'README_BINDER_THREE_SWAP_NEGATIVES'
Require-Literal $readmeText 'Windows case-insensitive uniqueness' `
    'README_WINDOWS_CASEFOLD_UNIQUENESS'
Require-Literal $readmeText 'Case-varied aliases to one omnibus file fail closed' `
    'README_CASE_ALIAS_OMNIBUS_NEGATIVE'

$receipt = [ordered]@{
  Task = 'AHD_V41_G2B_NVP_DIAG2_RM1_BUILD_HARNESS_STATIC_GATE'
  Result = 'PASS'
  TclSyntax = 'PASS'
  PowerShellSyntax = 'PASS'
  XdcSemanticMock = 'EXACT_12_PLUS_21_AND_NEGATIVE_CASES_PASS'
  BindingSemanticMock = 'EXACT_PATH_SHA_AND_NEGATIVE_CASES_PASS'
  BinderSnapshotAdversarial = 'FOCUSED_AFFECTED_PUBLICATION_SWAP_3_OF_3_PLUS_CASE_ALIAS_OMNIBUS_FAIL_CLOSED'
  PreVivadoSealSemanticMock = 'EXACT_14_DONOR_AND_NEGATIVE_CASES_PASS'
  ReceiptToSourceBinding = 'REQUIRED_PRE_VIVADO'
  RemotePublicationAndBlobReadback = 'REQUIRED_PRE_VIVADO'
  Rm1Sources = 'PRESENT'
  Rm1XdcCount = 1
  ExactProfile = 'RM1=1;R3=0;RTRACK=0'
  ScannerAcqMode1Sources = 'ABSENT'
  ProfileElaborationStages = 'POST_SYNTH;POST_OPT;ROUTED;FINALIZER'
  ActiveBusSkew = '11/11_REQUIRED'
  PromotedReplacements = '17/17_REQUIRED'
  LutHard = '<=98%'
  LutPreferred = '<=95%'
  BuildBitstreamWriterCount = 0
  FinalizerSignedDcpWriterCount = 1
  FinalizerBitstreamWriterCount = 1
  FullVivadoBuildExecutedByThisCheck = 'NO'
  HardwareAccessed = 'NO'
  Hashes = [ordered]@{
    Build = (Get-FileHash -LiteralPath $build -Algorithm SHA256).Hash
    Finalizer = (Get-FileHash -LiteralPath $finalizer -Algorithm SHA256).Hash
    Launcher = (Get-FileHash -LiteralPath $launcher -Algorithm SHA256).Hash
    Binder = (Get-FileHash -LiteralPath $binder -Algorithm SHA256).Hash
    AffectedR3 = (Get-FileHash -LiteralPath $affected -Algorithm SHA256).Hash
    R3Donor = (Get-FileHash -LiteralPath $donor -Algorithm SHA256).Hash
    Xdc = (Get-FileHash -LiteralPath $xdc -Algorithm SHA256).Hash
    SourceContractChecker = (Get-FileHash -LiteralPath $sourceContractChecker -Algorithm SHA256).Hash
    StaticChecker = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
    TclSyntaxChecker = (Get-FileHash -LiteralPath $tclCheck -Algorithm SHA256).Hash
    PublicationSchema = (Get-FileHash -LiteralPath $schema -Algorithm SHA256).Hash
    Readme = (Get-FileHash -LiteralPath $readme -Algorithm SHA256).Hash
  }
}
if (-not [string]::IsNullOrWhiteSpace($OutputReceipt)) {
  $target = [IO.Path]::GetFullPath($OutputReceipt)
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent)) {
    [void][IO.Directory]::CreateDirectory($parent)
  }
  $receipt | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $target -Encoding utf8NoBOM
}
$receipt | ConvertTo-Json -Depth 5
