[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$env:GIT_TERMINAL_PROMPT = '0'
$env:GIT_OPTIONAL_LOCKS = '0'

$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$rawRoot = Join-Path $taskRoot 'raw'
$runStamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$runUtc = [DateTime]::UtcNow.ToString('o')
$outputStem = "OFFLINE_AUTHORITY_AUDIT_$runStamp"
$jsonPath = Join-Path $rawRoot "$outputStem.json"
$logPath = Join-Path $rawRoot "$outputStem.log"
$markdownPath = Join-Path $rawRoot "$outputStem.md"

$evidenceRepo = 'C:\FPGA\V41_G2B_EVIDENCE'
$productRepo = 'C:\FPGA\V41_G2B'
$driverRepo = 'C:\FPGA\V41_G2B_DRV'
$readbackA = 'C:\FPGA\G2B_HW0_DRV1_REMOTE_READBACK_20260906_A'
$readbackB = 'C:\FPGA\G2B_HW0_DRV1_REMOTE_READBACK_20260906_B'
$evidenceRemoteExpected = 'https://github.com/lukaszsudul/AHD-diagnostic-evidence.git'
$sourceRemoteExpected = 'https://github.com/lukaszsudul/FPGA_AHD.git'
$githubApiBase = 'https://api.github.com/repos/lukaszsudul/AHD-diagnostic-evidence'

$expected = [ordered]@{
    evidence_main_commit = '9aacc157dab5fe604faf66501b0129613b98ae2d'
    meta8a_commit = 'f92f4d8fcc0dc88d3dc5753c799e1d891846e392'
    recovery4_commit = '6843d582fd367fbc0edc0b1d55a9617162c489b0'
    r2_commit = '9caa9c339966eda999219e4ed686c01654b9a87e'
    driver_source_commit = '0a201aab7adb13be079e784c6ed97dfad2ed7764'
    driver_source_tree = '6f079bf086878ddbce1f1ec82fece3039eae6573'
    driver_source_branch = 'host/v41-g2b-hw0-ahd-xdma-driver'
    product_source_commit = '92e9b3d914134c044371779def1ee18eaaeda98a'
    product_source_tree = 'cf6bf82249c90782eab1978c68541ed9c0e6430b'
    product_source_branch = 'integration/v41-g2b-onech-c2h'
    product_bitstream_sha256 = 'AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7'
    product_bitstream_size = 2192144L
    signed_dcp_sha256 = '95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175'
    signed_dcp_size = 15726324L
    project_state_revision = 8
}

$checks = [Collections.Generic.List[object]]::new()
$logLines = [Collections.Generic.List[string]]::new()
$packageResults = [Collections.Generic.List[object]]::new()
$failureCount = 0
$fatalError = $null
$httpClient = $null
$apiCache = @{}

function Add-Log {
    param([Parameter(Mandatory = $true)][string]$Message)
    $script:logLines.Add(('[{0}] {1}' -f [DateTime]::UtcNow.ToString('o'), $Message))
}

function Convert-SafeString {
    param($Value)
    if ($null -eq $Value) { return '<null>' }
    if ($Value -is [string]) { return $Value }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        return (@($Value) -join ',')
    }
    return [string]$Value
}

function Add-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][bool]$Pass,
        $ExpectedValue,
        $ActualValue,
        [string]$Evidence = ''
    )
    $status = if ($Pass) { 'PASS' } else { 'FAIL' }
    if (-not $Pass) { $script:failureCount++ }
    $entry = [ordered]@{
        name = $Name
        result = $status
        expected = Convert-SafeString $ExpectedValue
        actual = Convert-SafeString $ActualValue
        evidence = $Evidence
    }
    $script:checks.Add([pscustomobject]$entry)
    Add-Log "$status $Name expected=$($entry.expected) actual=$($entry.actual) evidence=$Evidence"
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [string]$Repository = ''
    )
    $gitArguments = [Collections.Generic.List[string]]::new()
    $gitArguments.Add('-c')
    $gitArguments.Add('credential.interactive=never')
    if ($Repository) {
        $gitArguments.Add('-C')
        $gitArguments.Add($Repository)
    }
    foreach ($argument in $Arguments) { $gitArguments.Add($argument) }
    $output = @(& git @gitArguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "READ_ONLY_GIT_COMMAND_FAILED exit=$exitCode args=$($Arguments -join ' ') output=$($output -join ' ')"
    }
    return (($output -join "`n").TrimEnd())
}

function Get-LsRemoteSha {
    param(
        [Parameter(Mandatory = $true)][string]$RemoteUrl,
        [Parameter(Mandatory = $true)][string]$RefName
    )
    $text = Invoke-Git -Arguments @('ls-remote', '--refs', $RemoteUrl, $RefName)
    $lines = @($text -split "`n" | Where-Object { $_ })
    if ($lines.Count -ne 1 -or $lines[0] -notmatch '^([0-9a-f]{40})\s+') {
        throw "LS_REMOTE_EXACT_REF_NOT_FOUND ref=$RefName lines=$($lines.Count)"
    }
    return $matches[1]
}

function Get-GitBlobSha1 {
    param([Parameter(Mandatory = $true)][string]$Path)
    $item = Get-Item -LiteralPath $Path
    $incremental = [Security.Cryptography.IncrementalHash]::CreateHash(
        [Security.Cryptography.HashAlgorithmName]::SHA1
    )
    try {
        $header = [Text.Encoding]::ASCII.GetBytes(('blob {0}{1}' -f $item.Length, [char]0))
        $incremental.AppendData($header)
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        try {
            $buffer = [byte[]]::new(1048576)
            while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $incremental.AppendData($buffer, 0, $read)
            }
        }
        finally {
            $stream.Dispose()
        }
        return [Convert]::ToHexString($incremental.GetHashAndReset()).ToLowerInvariant()
    }
    finally {
        $incremental.Dispose()
    }
}

function Write-NewUtf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )
    $encoding = [Text.UTF8Encoding]::new($false)
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $writer = [IO.StreamWriter]::new($stream, $encoding)
        try { $writer.Write($Content) }
        finally { $writer.Dispose() }
    }
    finally {
        if ($stream) { $stream.Dispose() }
    }
}

function Get-GitHubJson {
    param([Parameter(Mandatory = $true)][string]$Uri)
    if ($script:apiCache.ContainsKey($Uri)) { return $script:apiCache[$Uri] }
    $response = $script:httpClient.GetAsync($Uri).GetAwaiter().GetResult()
    $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    if (-not $response.IsSuccessStatusCode) {
        throw "GITHUB_API_READ_FAILED status=$([int]$response.StatusCode) uri=$Uri body=$body"
    }
    $parsed = $body | ConvertFrom-Json -Depth 100
    $script:apiCache[$Uri] = $parsed
    return $parsed
}

function Get-RemotePackageTree {
    param(
        [Parameter(Mandatory = $true)][string]$Commit,
        [Parameter(Mandatory = $true)][string]$Directory
    )
    $commitObject = Get-GitHubJson "$githubApiBase/git/commits/$Commit"
    Add-Check -Name "github_commit_exact:$Commit" -Pass ($commitObject.sha -ceq $Commit) `
        -ExpectedValue $Commit -ActualValue $commitObject.sha -Evidence $commitObject.html_url
    $rootTree = Get-GitHubJson "$githubApiBase/git/trees/$($commitObject.tree.sha)"
    $matches = @($rootTree.tree | Where-Object { $_.path -ceq $Directory -and $_.type -ceq 'tree' })
    Add-Check -Name "github_directory_unique:${Commit}:$Directory" -Pass ($matches.Count -eq 1) `
        -ExpectedValue 1 -ActualValue $matches.Count -Evidence "root_tree=$($commitObject.tree.sha)"
    if ($matches.Count -ne 1) { throw "REMOTE_PACKAGE_DIRECTORY_NOT_UNIQUE commit=$Commit directory=$Directory" }
    $recursiveTree = Get-GitHubJson "$githubApiBase/git/trees/$($matches[0].sha)?recursive=1"
    Add-Check -Name "github_package_tree_not_truncated:${Commit}:$Directory" -Pass (-not [bool]$recursiveTree.truncated) `
        -ExpectedValue $false -ActualValue ([bool]$recursiveTree.truncated) -Evidence "subtree=$($matches[0].sha)"
    return [pscustomobject]@{
        commit = $Commit
        commit_tree = [string]$commitObject.tree.sha
        directory = $Directory
        subtree = [string]$matches[0].sha
        tree = @($recursiveTree.tree)
    }
}

function Test-Package {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Spec,
        [Parameter(Mandatory = $true)]$RemoteTree
    )
    $name = [string]$Spec.name
    $localRoot = [IO.Path]::GetFullPath([string]$Spec.local_root).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $localRoot -PathType Container)) {
        throw "LOCAL_PACKAGE_ROOT_MISSING name=$name path=$localRoot"
    }
    $remoteBlobs = @($RemoteTree.tree | Where-Object { $_.type -ceq 'blob' })
    $localFiles = @(Get-ChildItem -LiteralPath $localRoot -File -Recurse -Force)
    $remoteByPath = @{}
    foreach ($blob in $remoteBlobs) { $remoteByPath[[string]$blob.path] = $blob }
    $localByPath = @{}
    foreach ($file in $localFiles) {
        $relative = [IO.Path]::GetRelativePath($localRoot, $file.FullName).Replace('\', '/')
        $localByPath[$relative] = $file
    }

    $missing = [Collections.Generic.List[string]]::new()
    $extra = [Collections.Generic.List[string]]::new()
    $blobMismatches = [Collections.Generic.List[string]]::new()
    $sizeMismatches = [Collections.Generic.List[string]]::new()
    foreach ($path in $remoteByPath.Keys) {
        if (-not $localByPath.ContainsKey($path)) {
            $missing.Add($path)
            continue
        }
        $file = $localByPath[$path]
        $remoteBlob = $remoteByPath[$path]
        if ([long]$file.Length -ne [long]$remoteBlob.size) {
            $sizeMismatches.Add("$path expected=$($remoteBlob.size) actual=$($file.Length)")
        }
        $localBlob = Get-GitBlobSha1 -Path $file.FullName
        if ($localBlob -cne [string]$remoteBlob.sha) {
            $blobMismatches.Add("$path expected=$($remoteBlob.sha) actual=$localBlob")
        }
    }
    foreach ($path in $localByPath.Keys) {
        if (-not $remoteByPath.ContainsKey($path)) { $extra.Add($path) }
    }

    $manifestRelative = [string]$Spec.manifest
    $manifestPath = Join-Path $localRoot $manifestRelative.Replace('/', '\')
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "PACKAGE_MANIFEST_MISSING name=$name path=$manifestPath"
    }
    $manifestEntries = [Collections.Generic.List[object]]::new()
    $manifestMalformed = [Collections.Generic.List[string]]::new()
    $manifestHashMismatches = [Collections.Generic.List[string]]::new()
    $manifestMissing = [Collections.Generic.List[string]]::new()
    $coveredPaths = @{}
    $lineNumber = 0
    foreach ($line in [IO.File]::ReadAllLines($manifestPath, [Text.UTF8Encoding]::new($false, $true))) {
        $lineNumber++
        if (-not $line) { continue }
        $match = [regex]::Match($line, '^([0-9A-Fa-f]{64})  (.+)$')
        if (-not $match.Success) {
            $manifestMalformed.Add("line=$lineNumber")
            continue
        }
        $sha = $match.Groups[1].Value.ToUpperInvariant()
        $relative = $match.Groups[2].Value.Replace('\', '/')
        $candidate = [IO.Path]::GetFullPath((Join-Path $localRoot $relative.Replace('/', '\')))
        if (-not $candidate.StartsWith($localRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
            $manifestMalformed.Add("line=$lineNumber path_escape=$relative")
            continue
        }
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $manifestMissing.Add($relative)
            continue
        }
        $actualSha = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash
        if ($actualSha -cne $sha) {
            $manifestHashMismatches.Add("$relative expected=$sha actual=$actualSha")
        }
        $coveredPaths[$relative] = $true
        $manifestEntries.Add([pscustomobject]@{ path = $relative; sha256 = $sha })
    }
    $coverageMissing = [Collections.Generic.List[string]]::new()
    foreach ($path in $localByPath.Keys) {
        if ($path -cne $manifestRelative -and -not $coveredPaths.ContainsKey($path)) {
            $coverageMissing.Add($path)
        }
    }

    if ($Spec.requested_count_kind -ceq 'commit_blob_count') {
        $requestedActual = $remoteBlobs.Count
    }
    else {
        $requestedActual = $manifestEntries.Count
    }
    $requestedPass = $requestedActual -eq [int]$Spec.requested_count
    Add-Check -Name "${name}:requested_count" -Pass $requestedPass `
        -ExpectedValue $Spec.requested_count -ActualValue $requestedActual -Evidence "kind=$($Spec.requested_count_kind)"
    Add-Check -Name "${name}:commit_blob_count" -Pass ($remoteBlobs.Count -eq [int]$Spec.expected_blob_count) `
        -ExpectedValue $Spec.expected_blob_count -ActualValue $remoteBlobs.Count -Evidence "subtree=$($RemoteTree.subtree)"
    Add-Check -Name "${name}:local_file_count" -Pass ($localFiles.Count -eq [int]$Spec.expected_blob_count) `
        -ExpectedValue $Spec.expected_blob_count -ActualValue $localFiles.Count -Evidence $localRoot
    Add-Check -Name "${name}:commit_blob_identity" -Pass (
        $missing.Count -eq 0 -and $extra.Count -eq 0 -and $blobMismatches.Count -eq 0 -and $sizeMismatches.Count -eq 0
    ) -ExpectedValue 'zero mismatches' `
        -ActualValue "missing=$($missing.Count),extra=$($extra.Count),blob=$($blobMismatches.Count),size=$($sizeMismatches.Count)" `
        -Evidence "commit=$($Spec.commit) directory=$($Spec.directory)"
    Add-Check -Name "${name}:manifest_entry_count" -Pass ($manifestEntries.Count -eq [int]$Spec.expected_manifest_count) `
        -ExpectedValue $Spec.expected_manifest_count -ActualValue $manifestEntries.Count -Evidence $manifestPath
    Add-Check -Name "${name}:manifest_integrity" -Pass (
        $manifestMalformed.Count -eq 0 -and $manifestMissing.Count -eq 0 -and
        $manifestHashMismatches.Count -eq 0 -and $coverageMissing.Count -eq 0
    ) -ExpectedValue 'zero mismatches and complete non-self coverage' `
        -ActualValue "malformed=$($manifestMalformed.Count),missing=$($manifestMissing.Count),hash=$($manifestHashMismatches.Count),coverage=$($coverageMissing.Count)" `
        -Evidence $manifestPath

    $result = [ordered]@{
        name = $name
        commit = [string]$Spec.commit
        directory = [string]$Spec.directory
        commit_tree = [string]$RemoteTree.commit_tree
        subtree = [string]$RemoteTree.subtree
        local_root = $localRoot
        requested_count = [int]$Spec.requested_count
        requested_count_kind = [string]$Spec.requested_count_kind
        commit_blob_count = $remoteBlobs.Count
        local_file_count = $localFiles.Count
        manifest = $manifestRelative
        manifest_entry_count = $manifestEntries.Count
        missing_files = @($missing)
        extra_files = @($extra)
        blob_mismatches = @($blobMismatches)
        size_mismatches = @($sizeMismatches)
        manifest_malformed = @($manifestMalformed)
        manifest_missing = @($manifestMissing)
        manifest_hash_mismatches = @($manifestHashMismatches)
        manifest_coverage_missing = @($coverageMissing)
    }
    $script:packageResults.Add([pscustomobject]$result)
}

function Test-SourceWorktree {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$ExpectedBranch,
        [Parameter(Mandatory = $true)][string]$ExpectedCommit,
        [Parameter(Mandatory = $true)][string]$ExpectedTree
    )
    $top = Invoke-Git -Repository $Repository -Arguments @('rev-parse', '--show-toplevel')
    $branch = Invoke-Git -Repository $Repository -Arguments @('symbolic-ref', '--short', 'HEAD')
    $head = Invoke-Git -Repository $Repository -Arguments @('rev-parse', 'HEAD')
    $tree = Invoke-Git -Repository $Repository -Arguments @('rev-parse', 'HEAD^{tree}')
    $status = Invoke-Git -Repository $Repository -Arguments @('status', '--porcelain=v1', '--untracked-files=all')
    $origin = Invoke-Git -Repository $Repository -Arguments @('remote', 'get-url', 'origin')
    $tracking = Invoke-Git -Repository $Repository -Arguments @('rev-parse', "refs/remotes/origin/$ExpectedBranch")
    $liveRemote = Get-LsRemoteSha -RemoteUrl $origin -RefName "refs/heads/$ExpectedBranch"
    Add-Check -Name "${Name}:worktree_path" -Pass (
        [IO.Path]::GetFullPath($top).TrimEnd('\') -ieq [IO.Path]::GetFullPath($Repository).TrimEnd('\')
    ) -ExpectedValue $Repository -ActualValue $top -Evidence 'git rev-parse --show-toplevel'
    Add-Check -Name "${Name}:branch" -Pass ($branch -ceq $ExpectedBranch) -ExpectedValue $ExpectedBranch -ActualValue $branch -Evidence $Repository
    Add-Check -Name "${Name}:commit" -Pass ($head -ceq $ExpectedCommit) -ExpectedValue $ExpectedCommit -ActualValue $head -Evidence $Repository
    Add-Check -Name "${Name}:tree" -Pass ($tree -ceq $ExpectedTree) -ExpectedValue $ExpectedTree -ActualValue $tree -Evidence $Repository
    $cleanActual = if ([string]::IsNullOrEmpty($status)) { 'clean' } else { $status }
    Add-Check -Name "${Name}:clean" -Pass ([string]::IsNullOrEmpty($status)) -ExpectedValue 'clean' -ActualValue $cleanActual `
        -Evidence 'git status --porcelain=v1 --untracked-files=all'
    Add-Check -Name "${Name}:origin_url" -Pass ($origin -ceq $sourceRemoteExpected) -ExpectedValue $sourceRemoteExpected -ActualValue $origin -Evidence $Repository
    Add-Check -Name "${Name}:local_tracking_ref" -Pass ($tracking -ceq $ExpectedCommit) -ExpectedValue $ExpectedCommit -ActualValue $tracking -Evidence "refs/remotes/origin/$ExpectedBranch"
    Add-Check -Name "${Name}:live_remote_ref" -Pass ($liveRemote -ceq $ExpectedCommit) -ExpectedValue $ExpectedCommit -ActualValue $liveRemote -Evidence "refs/heads/$ExpectedBranch"
    return [pscustomobject][ordered]@{
        name = $Name
        repository = $Repository
        branch = $branch
        commit = $head
        tree = $tree
        clean = [string]::IsNullOrEmpty($status)
        origin = $origin
        local_tracking_commit = $tracking
        live_remote_commit = $liveRemote
    }
}

function Test-LocalArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][long]$ExpectedSize,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256
    )
    $exists = Test-Path -LiteralPath $Path -PathType Leaf
    Add-Check -Name "${Name}:exists" -Pass $exists -ExpectedValue $true -ActualValue $exists -Evidence $Path
    if (-not $exists) { throw "LOCAL_ARTIFACT_MISSING name=$Name path=$Path" }
    $item = Get-Item -LiteralPath $Path
    $sha = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    Add-Check -Name "${Name}:size" -Pass ($item.Length -eq $ExpectedSize) -ExpectedValue $ExpectedSize -ActualValue $item.Length -Evidence $Path
    Add-Check -Name "${Name}:sha256" -Pass ($sha -ceq $ExpectedSha256) -ExpectedValue $ExpectedSha256 -ActualValue $sha -Evidence $Path
    return [pscustomobject][ordered]@{ name = $Name; path = $Path; size = $item.Length; sha256 = $sha }
}

Add-Log 'BEGIN G2B-HW0-PRODUCT-R3 OFFLINE AUTHORITY AUDIT'
Add-Log 'BOUNDARY DUT_ACCESSED=NO HARDWARE_ACCESSED=NO GOVERNED_REPO_WRITES=NO'

$evidenceIdentity = $null
$sourceIdentities = @()
$artifactIdentities = @()
$ssotState = $null
$ssotMetaTree = $null
$ssotHeadTree = $null
$remoteMainStart = $null
$remoteMainEnd = $null

try {
    foreach ($requiredRoot in @($taskRoot, $rawRoot, $evidenceRepo, $productRepo, $driverRepo, $readbackA, $readbackB)) {
        if (-not (Test-Path -LiteralPath $requiredRoot -PathType Container)) {
            throw "REQUIRED_DIRECTORY_MISSING=$requiredRoot"
        }
    }

    $httpClient = [Net.Http.HttpClient]::new()
    $httpClient.Timeout = [TimeSpan]::FromSeconds(60)
    $httpClient.DefaultRequestHeaders.UserAgent.ParseAdd('AHD-G2B-R3-offline-authority-audit')
    $httpClient.DefaultRequestHeaders.Accept.ParseAdd('application/vnd.github+json')

    $evidenceOrigin = Invoke-Git -Repository $evidenceRepo -Arguments @('remote', 'get-url', 'origin')
    $evidenceHead = Invoke-Git -Repository $evidenceRepo -Arguments @('rev-parse', 'HEAD')
    $evidenceLocalMain = Invoke-Git -Repository $evidenceRepo -Arguments @('rev-parse', 'refs/heads/main')
    $evidenceTrackingMain = Invoke-Git -Repository $evidenceRepo -Arguments @('rev-parse', 'refs/remotes/origin/main')
    $evidenceTrackedStatus = Invoke-Git -Repository $evidenceRepo -Arguments @('status', '--porcelain=v1', '--untracked-files=no')
    $evidenceAllStatus = Invoke-Git -Repository $evidenceRepo -Arguments @('status', '--porcelain=v1', '--untracked-files=all')
    $remoteMainStart = Get-LsRemoteSha -RemoteUrl $evidenceOrigin -RefName 'refs/heads/main'
    Add-Check -Name 'evidence:origin_url' -Pass ($evidenceOrigin -ceq $evidenceRemoteExpected) -ExpectedValue $evidenceRemoteExpected -ActualValue $evidenceOrigin -Evidence $evidenceRepo
    Add-Check -Name 'evidence:worktree_head' -Pass ($evidenceHead -ceq $expected.evidence_main_commit) -ExpectedValue $expected.evidence_main_commit -ActualValue $evidenceHead -Evidence $evidenceRepo
    Add-Check -Name 'evidence:local_main' -Pass ($evidenceLocalMain -ceq $expected.evidence_main_commit) -ExpectedValue $expected.evidence_main_commit -ActualValue $evidenceLocalMain -Evidence 'refs/heads/main'
    Add-Check -Name 'evidence:local_tracking_main' -Pass ($evidenceTrackingMain -ceq $expected.evidence_main_commit) -ExpectedValue $expected.evidence_main_commit -ActualValue $evidenceTrackingMain -Evidence 'refs/remotes/origin/main'
    Add-Check -Name 'evidence:live_remote_main_start' -Pass ($remoteMainStart -ceq $expected.evidence_main_commit) -ExpectedValue $expected.evidence_main_commit -ActualValue $remoteMainStart -Evidence 'git ls-remote refs/heads/main'
    $trackedActual = if ([string]::IsNullOrEmpty($evidenceTrackedStatus)) { 'tracked clean' } else { $evidenceTrackedStatus }
    Add-Check -Name 'evidence:tracked_clean' -Pass ([string]::IsNullOrEmpty($evidenceTrackedStatus)) -ExpectedValue 'tracked clean' `
        -ActualValue $trackedActual -Evidence 'untracked files intentionally not used as authority'
    $evidenceIdentity = [pscustomobject][ordered]@{
        repository = $evidenceRepo
        origin = $evidenceOrigin
        head = $evidenceHead
        local_main = $evidenceLocalMain
        local_tracking_main = $evidenceTrackingMain
        live_remote_main_start = $remoteMainStart
        tracked_clean = [string]::IsNullOrEmpty($evidenceTrackedStatus)
        untracked_status = @($evidenceAllStatus -split "`n" | Where-Object { $_ })
    }

    $ssotHeadTree = Get-RemotePackageTree -Commit $expected.evidence_main_commit -Directory 'project-current-state'
    $ssotMetaTree = Get-RemotePackageTree -Commit $expected.meta8a_commit -Directory 'project-current-state'
    Add-Check -Name 'ssot:subtree_unchanged_since_meta8a' -Pass ($ssotHeadTree.subtree -ceq $ssotMetaTree.subtree) `
        -ExpectedValue $ssotMetaTree.subtree -ActualValue $ssotHeadTree.subtree -Evidence "META8A=$($expected.meta8a_commit) HEAD=$($expected.evidence_main_commit)"

    $ssotStatePath = Join-Path $readbackB 'project-current-state\PROJECT_STATE.json'
    $ssotState = [IO.File]::ReadAllText($ssotStatePath, [Text.UTF8Encoding]::new($false, $true)) | ConvertFrom-Json -Depth 100
    Add-Check -Name 'ssot:project_state_revision' -Pass ([int]$ssotState.project_state_revision -eq $expected.project_state_revision) `
        -ExpectedValue $expected.project_state_revision -ActualValue $ssotState.project_state_revision -Evidence $ssotStatePath
    Add-Check -Name 'ssot:meta8a_acceptance' -Pass ($ssotState.acceptance_authorization -ceq 'META-8A_TASK_DIRECTIVE') `
        -ExpectedValue 'META-8A_TASK_DIRECTIVE' -ActualValue $ssotState.acceptance_authorization -Evidence $ssotStatePath
    Add-Check -Name 'ssot:literal_write_authorization_receipt' -Pass ($ssotState.ssot_write_authorization -ceq 'SSOT WRITE AUTHORIZED') `
        -ExpectedValue 'SSOT WRITE AUTHORIZED' -ActualValue $ssotState.ssot_write_authorization -Evidence $ssotStatePath
    Add-Check -Name 'ssot:recovery4_source_commit' -Pass ($ssotState.source_evidence_commit -ceq $expected.recovery4_commit) `
        -ExpectedValue $expected.recovery4_commit -ActualValue $ssotState.source_evidence_commit -Evidence $ssotStatePath

    $packageSpecs = @(
        @{
            name = 'SSOT_REV8'; commit = $expected.evidence_main_commit; directory = 'project-current-state'
            local_root = (Join-Path $readbackB 'project-current-state'); manifest = 'SHA256_MANIFEST.txt'
            requested_count = 18; requested_count_kind = 'manifest_entry_count'; expected_manifest_count = 18; expected_blob_count = 19
        },
        @{
            name = 'META8A'; commit = $expected.meta8a_commit; directory = 'v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization'
            local_root = (Join-Path $readbackA 'v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization'); manifest = 'META8A_SHA256_MANIFEST.txt'
            requested_count = 32; requested_count_kind = 'manifest_entry_count'; expected_manifest_count = 32; expected_blob_count = 33
        },
        @{
            name = 'RECOVERY4'; commit = $expected.recovery4_commit; directory = 'v41-development-g2b-lut1-signoff-recovery-4'
            local_root = (Join-Path $readbackA 'v41-development-g2b-lut1-signoff-recovery-4'); manifest = 'G2B_LUT1_RECOVERY4_SHA256_MANIFEST.txt'
            requested_count = 181; requested_count_kind = 'manifest_entry_count'; expected_manifest_count = 181; expected_blob_count = 182
        },
        @{
            name = 'R2'; commit = $expected.r2_commit; directory = 'v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot'
            local_root = (Join-Path $readbackA 'v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot'); manifest = 'G2B_HW0_PRODUCT_R2_SHA256_MANIFEST.txt'
            requested_count = 128; requested_count_kind = 'manifest_entry_count'; expected_manifest_count = 128; expected_blob_count = 129
        },
        @{
            name = 'DRV1'; commit = $expected.evidence_main_commit; directory = 'v41-host-g2b-hw0-ahd-xdma-driver-build'
            local_root = (Join-Path $readbackB 'v41-host-g2b-hw0-ahd-xdma-driver-build'); manifest = 'G2B_HW0_DRV1_SHA256_MANIFEST.txt'
            requested_count = 30; requested_count_kind = 'commit_blob_count'; expected_manifest_count = 29; expected_blob_count = 30
        }
    )
    $remoteTreeByKey = @{
        'SSOT_REV8' = $ssotHeadTree
        'META8A' = (Get-RemotePackageTree -Commit $expected.meta8a_commit -Directory 'v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization')
        'RECOVERY4' = (Get-RemotePackageTree -Commit $expected.recovery4_commit -Directory 'v41-development-g2b-lut1-signoff-recovery-4')
        'R2' = (Get-RemotePackageTree -Commit $expected.r2_commit -Directory 'v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot')
        'DRV1' = (Get-RemotePackageTree -Commit $expected.evidence_main_commit -Directory 'v41-host-g2b-hw0-ahd-xdma-driver-build')
    }
    foreach ($spec in $packageSpecs) {
        Test-Package -Spec $spec -RemoteTree $remoteTreeByKey[$spec.name]
    }

    $sourceIdentities = @(
        Test-SourceWorktree -Name 'PRODUCT_SOURCE' -Repository $productRepo `
            -ExpectedBranch $expected.product_source_branch -ExpectedCommit $expected.product_source_commit -ExpectedTree $expected.product_source_tree
        Test-SourceWorktree -Name 'DRIVER_SOURCE' -Repository $driverRepo `
            -ExpectedBranch $expected.driver_source_branch -ExpectedCommit $expected.driver_source_commit -ExpectedTree $expected.driver_source_tree
    )

    $artifactIdentities = @(
        Test-LocalArtifact -Name 'PRODUCT_BITSTREAM' `
            -Path 'C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit' `
            -ExpectedSize $expected.product_bitstream_size -ExpectedSha256 $expected.product_bitstream_sha256
        Test-LocalArtifact -Name 'SIGNED_OFF_DCP' `
            -Path 'C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp' `
            -ExpectedSize $expected.signed_dcp_size -ExpectedSha256 $expected.signed_dcp_sha256
    )

    $remoteMainEnd = Get-LsRemoteSha -RemoteUrl $evidenceOrigin -RefName 'refs/heads/main'
    Add-Check -Name 'evidence:live_remote_main_end' -Pass ($remoteMainEnd -ceq $expected.evidence_main_commit) `
        -ExpectedValue $expected.evidence_main_commit -ActualValue $remoteMainEnd -Evidence 'second git ls-remote refs/heads/main'
    Add-Check -Name 'evidence:remote_main_stable_during_audit' -Pass ($remoteMainStart -ceq $remoteMainEnd) `
        -ExpectedValue $remoteMainStart -ActualValue $remoteMainEnd -Evidence 'start/end live queries'
}
catch {
    $fatalError = $_.Exception.Message
    Add-Check -Name 'audit:fatal_exception' -Pass $false -ExpectedValue 'none' -ActualValue $fatalError -Evidence $_.ScriptStackTrace
}
finally {
    if ($null -ne $httpClient) { $httpClient.Dispose() }
}

$resultText = if ($failureCount -eq 0 -and $null -eq $fatalError) { 'PASS' } else { 'FAIL' }
$completedUtc = [DateTime]::UtcNow.ToString('o')
$scriptSha256 = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
$record = [ordered]@{
    schema = 'G2B_HW0_PRODUCT_R3_OFFLINE_AUTHORITY_AUDIT_V1'
    task = 'G2B-HW0-PRODUCT-R3'
    result = $resultText
    started_utc = $runUtc
    completed_utc = $completedUtc
    boundary = [ordered]@{
        dut_accessed = 'NO'
        hardware_accessed = 'NO'
        governed_repository_writes = 'NO'
        remote_reads = @('Git refs over HTTPS', 'GitHub commit/tree API over HTTPS')
        output_scope = $taskRoot
    }
    verifier = [ordered]@{ path = $PSCommandPath; sha256 = $scriptSha256 }
    expected = $expected
    evidence_repository = $evidenceIdentity
    project_state = [ordered]@{
        revision = if ($null -ne $ssotState) { $ssotState.project_state_revision } else { $null }
        acceptance_authorization = if ($null -ne $ssotState) { $ssotState.acceptance_authorization } else { $null }
        source_evidence_commit = if ($null -ne $ssotState) { $ssotState.source_evidence_commit } else { $null }
        meta8a_subtree = if ($null -ne $ssotMetaTree) { $ssotMetaTree.subtree } else { $null }
        current_main_subtree = if ($null -ne $ssotHeadTree) { $ssotHeadTree.subtree } else { $null }
        unchanged_since_meta8a = if ($null -ne $ssotMetaTree -and $null -ne $ssotHeadTree) { $ssotMetaTree.subtree -ceq $ssotHeadTree.subtree } else { $false }
    }
    packages = @($packageResults)
    source_worktrees = @($sourceIdentities)
    local_candidate_artifacts = @($artifactIdentities)
    live_remote_main_start = $remoteMainStart
    live_remote_main_end = $remoteMainEnd
    checks_total = $checks.Count
    checks_pass = @($checks | Where-Object { $_.result -ceq 'PASS' }).Count
    checks_fail = @($checks | Where-Object { $_.result -ceq 'FAIL' }).Count
    checks = @($checks)
    fatal_error = $fatalError
}

$jsonText = ($record | ConvertTo-Json -Depth 100) + "`n"
$logLines.Add("RESULT=$resultText")
$logLines.Add("CHECKS_TOTAL=$($record.checks_total)")
$logLines.Add("CHECKS_PASS=$($record.checks_pass)")
$logLines.Add("CHECKS_FAIL=$($record.checks_fail)")
$logLines.Add("PROJECT_STATE_REVISION=$($record.project_state.revision)")
$logLines.Add("EVIDENCE_REMOTE_MAIN_START=$remoteMainStart")
$logLines.Add("EVIDENCE_REMOTE_MAIN_END=$remoteMainEnd")
$logLines.Add("DUT_ACCESSED=NO")
$logLines.Add("HARDWARE_ACCESSED=NO")
$logLines.Add("GOVERNED_REPOSITORY_WRITES=NO")
$logLines.Add("VERIFIER_SHA256=$scriptSha256")
$logText = ($logLines -join "`n") + "`n"

$markdown = [Text.StringBuilder]::new()
[void]$markdown.AppendLine('# G2B-HW0-PRODUCT-R3 offline authority audit')
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("Result: **$resultText**")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("- Started UTC: $runUtc")
[void]$markdown.AppendLine("- Completed UTC: $completedUtc")
[void]$markdown.AppendLine("- Verifier SHA-256: $scriptSha256")
[void]$markdown.AppendLine('- DUT accessed: `NO`')
[void]$markdown.AppendLine('- Hardware accessed: `NO`')
[void]$markdown.AppendLine('- Governed repository writes: `NO`')
[void]$markdown.AppendLine()
[void]$markdown.AppendLine('## Controlling identities')
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("- Evidence main local/remote expected: $($expected.evidence_main_commit)")
[void]$markdown.AppendLine("- Live remote main at start: $remoteMainStart")
[void]$markdown.AppendLine("- Live remote main at end: $remoteMainEnd")
[void]$markdown.AppendLine("- PROJECT_STATE_REV: $($record.project_state.revision)")
[void]$markdown.AppendLine("- SSOT subtree at META-8A: $($record.project_state.meta8a_subtree)")
[void]$markdown.AppendLine("- SSOT subtree at current main: $($record.project_state.current_main_subtree)")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine('## Commit-blob and manifest verification')
[void]$markdown.AppendLine()
[void]$markdown.AppendLine('| Package | Commit | Commit blobs | Manifest entries | Result |')
[void]$markdown.AppendLine('|---|---|---:|---:|---|')
foreach ($package in $packageResults) {
    $packagePass = (
        $package.missing_files.Count -eq 0 -and $package.extra_files.Count -eq 0 -and
        $package.blob_mismatches.Count -eq 0 -and $package.size_mismatches.Count -eq 0 -and
        $package.manifest_malformed.Count -eq 0 -and $package.manifest_missing.Count -eq 0 -and
        $package.manifest_hash_mismatches.Count -eq 0 -and $package.manifest_coverage_missing.Count -eq 0
    )
    $packageStatus = if ($packagePass) { 'PASS' } else { 'FAIL' }
    [void]$markdown.AppendLine("| $($package.name) | $($package.commit) | $($package.commit_blob_count) | $($package.manifest_entry_count) | $packageStatus |")
}
[void]$markdown.AppendLine()
[void]$markdown.AppendLine('Requested count interpretation is explicit in JSON: SSOT 18, META-8A 32, Recovery-4 181, and R2 128 are manifest-entry counts; DRV1 30 is the final commit-blob/file count and its self-excluding manifest contains 29 entries.')
[void]$markdown.AppendLine()
[void]$markdown.AppendLine('## Checks')
[void]$markdown.AppendLine()
[void]$markdown.AppendLine('| Result | Check | Expected | Actual |')
[void]$markdown.AppendLine('|---|---|---|---|')
foreach ($check in $checks) {
    $expectedMd = ([string]$check.expected).Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ')
    $actualMd = ([string]$check.actual).Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ')
    $nameMd = ([string]$check.name).Replace('|', '\|')
    [void]$markdown.AppendLine("| $($check.result) | $nameMd | $expectedMd | $actualMd |")
}
[void]$markdown.AppendLine()
[void]$markdown.AppendLine('## Claim boundary')
[void]$markdown.AppendLine()
[void]$markdown.AppendLine('This audit proves offline authority, commit/blob identity, manifest integrity, source-worktree identity, and local candidate artifact identity. It performs no DUT, JTAG, PCIe, MMIO, module, or DMA operation and makes no runtime qualification claim.')
if ($fatalError) {
    [void]$markdown.AppendLine()
    [void]$markdown.AppendLine("Fatal error: $($fatalError.Replace('`', "'"))")
}
$markdownText = $markdown.ToString().Replace("`r`n", "`n")

Write-NewUtf8File -Path $jsonPath -Content $jsonText.Replace("`r`n", "`n")
Write-NewUtf8File -Path $logPath -Content $logText.Replace("`r`n", "`n")
Write-NewUtf8File -Path $markdownPath -Content $markdownText

Write-Output "RESULT=$resultText"
Write-Output "CHECKS_TOTAL=$($record.checks_total)"
Write-Output "CHECKS_PASS=$($record.checks_pass)"
Write-Output "CHECKS_FAIL=$($record.checks_fail)"
Write-Output "JSON=$jsonPath"
Write-Output "LOG=$logPath"
Write-Output "MARKDOWN=$markdownPath"
Write-Output "VERIFIER_SHA256=$scriptSha256"
if ($resultText -ne 'PASS') { exit 1 }
