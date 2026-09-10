param(
    [Parameter(Mandatory = $true)]
    [string]$Repository
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProductCommit = '30b14d13b0b789b62b05ab513eb9578c7c43b11a'
$DiagnosticCommit = 'fcab95726761a0666a67e31c283dbdfb9e775074'
$SourcePath = 'rtl/g2b/v41_g2b_onech_c2h.sv'
$ModuleName = 'v41_g2b_onech_c2h'

$TapMap = [ordered]@{
    diag_stored_enable = 'stored_enable_axi'
    diag_c2h_active    = 'c2h_active_axi'
    diag_ring_empty    = 'ring_empty_axi'
    diag_ring_full     = 'ring_full_axi'
}

function Invoke-GitRaw {
    param([string[]]$GitArguments)

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.WorkingDirectory = $Repository
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $GitArguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw "Unable to start git."
    }

    $memory = [System.IO.MemoryStream]::new()
    $stdoutTask = $process.StandardOutput.BaseStream.CopyToAsync($memory)
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    [void]$stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()

    if ($process.ExitCode -ne 0) {
        throw "git $($GitArguments -join ' ') failed ($($process.ExitCode)): $stderr"
    }

    [pscustomobject]@{
        Bytes = $memory.ToArray()
        Stderr = $stderr
    }
}

function Convert-BytesToStrictUtf8 {
    param([byte[]]$Bytes)
    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    $utf8.GetString($Bytes)
}

function Get-Sha256Hex {
    param([byte[]]$Bytes)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash($Bytes)
    }
    finally {
        $sha256.Dispose()
    }
    ([System.BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
}

function Remove-SystemVerilogComments {
    param([string]$Text)

    $builder = [System.Text.StringBuilder]::new()
    $lineComments = 0
    $blockComments = 0
    $index = 0
    $state = 'normal'

    while ($index -lt $Text.Length) {
        $character = $Text[$index]
        $next = if ($index + 1 -lt $Text.Length) { $Text[$index + 1] } else { [char]0 }

        if ($state -eq 'normal') {
            if ($character -eq '"') {
                [void]$builder.Append($character)
                $state = 'string'
                $index++
                continue
            }
            if ($character -eq '/' -and $next -eq '/') {
                [void]$builder.Append(' ')
                $lineComments++
                $state = 'line-comment'
                $index += 2
                continue
            }
            if ($character -eq '/' -and $next -eq '*') {
                [void]$builder.Append(' ')
                $blockComments++
                $state = 'block-comment'
                $index += 2
                continue
            }
            [void]$builder.Append($character)
            $index++
            continue
        }

        if ($state -eq 'string') {
            [void]$builder.Append($character)
            if ($character -eq '\' -and $index + 1 -lt $Text.Length) {
                [void]$builder.Append($Text[$index + 1])
                $index += 2
                continue
            }
            if ($character -eq '"') {
                $state = 'normal'
            }
            $index++
            continue
        }

        if ($state -eq 'line-comment') {
            if ($character -eq "`r" -or $character -eq "`n") {
                [void]$builder.Append($character)
                $state = 'normal'
            }
            $index++
            continue
        }

        if ($state -eq 'block-comment') {
            if ($character -eq '*' -and $next -eq '/') {
                [void]$builder.Append(' ')
                $state = 'normal'
                $index += 2
                continue
            }
            if ($character -eq "`r" -or $character -eq "`n") {
                [void]$builder.Append($character)
            }
            $index++
            continue
        }
    }

    if ($state -eq 'block-comment' -or $state -eq 'string') {
        throw "Unterminated $state in source blob."
    }

    [pscustomobject]@{
        Text = $builder.ToString()
        LineCommentCount = $lineComments
        BlockCommentCount = $blockComments
    }
}

function Find-MatchingParenthesis {
    param(
        [string]$Text,
        [int]$OpenIndex
    )

    if ($Text[$OpenIndex] -ne '(') {
        throw "Expected opening parenthesis at index $OpenIndex."
    }

    $depth = 0
    $inString = $false
    for ($index = $OpenIndex; $index -lt $Text.Length; $index++) {
        $character = $Text[$index]
        if ($inString) {
            if ($character -eq '\') {
                $index++
                continue
            }
            if ($character -eq '"') {
                $inString = $false
            }
            continue
        }
        if ($character -eq '"') {
            $inString = $true
            continue
        }
        if ($character -eq '(') {
            $depth++
        }
        elseif ($character -eq ')') {
            $depth--
            if ($depth -eq 0) {
                return $index
            }
            if ($depth -lt 0) {
                throw "Parenthesis depth became negative."
            }
        }
    }
    throw "No matching closing parenthesis."
}

function Split-TopLevelCommaList {
    param([string]$Text)

    $items = [System.Collections.Generic.List[string]]::new()
    $start = 0
    $paren = 0
    $bracket = 0
    $brace = 0
    $inString = $false

    for ($index = 0; $index -lt $Text.Length; $index++) {
        $character = $Text[$index]
        if ($inString) {
            if ($character -eq '\') {
                $index++
                continue
            }
            if ($character -eq '"') {
                $inString = $false
            }
            continue
        }
        if ($character -eq '"') {
            $inString = $true
            continue
        }
        switch ($character) {
            '(' { $paren++ }
            ')' { $paren-- }
            '[' { $bracket++ }
            ']' { $bracket-- }
            '{' { $brace++ }
            '}' { $brace-- }
            ',' {
                if ($paren -eq 0 -and $bracket -eq 0 -and $brace -eq 0) {
                    $items.Add($Text.Substring($start, $index - $start))
                    $start = $index + 1
                }
            }
        }
        if ($paren -lt 0 -or $bracket -lt 0 -or $brace -lt 0) {
            throw "Unbalanced delimiter in module port list."
        }
    }

    if ($paren -ne 0 -or $bracket -ne 0 -or $brace -ne 0 -or $inString) {
        throw "Unbalanced module port list."
    }
    $items.Add($Text.Substring($start))
    $items.ToArray()
}

function Get-CompactSignature {
    param([string]$Text)
    [regex]::Replace($Text, '\s+', '')
}

function Remove-AllowlistedTapPorts {
    param(
        [string]$Text,
        [bool]$ExpectTaps
    )

    $modulePattern = '(?<![A-Za-z0-9_$])module\s+' + [regex]::Escape($ModuleName) + '(?![A-Za-z0-9_$])'
    $moduleMatches = [regex]::Matches($Text, $modulePattern)
    if ($moduleMatches.Count -ne 1) {
        throw "Expected exactly one $ModuleName module declaration; found $($moduleMatches.Count)."
    }
    $moduleMatch = $moduleMatches[0]
    $openIndex = $Text.IndexOf('(', $moduleMatch.Index + $moduleMatch.Length)
    if ($openIndex -lt 0) {
        throw "Module port-list opening parenthesis not found."
    }
    $closeIndex = Find-MatchingParenthesis -Text $Text -OpenIndex $openIndex
    $portText = $Text.Substring($openIndex + 1, $closeIndex - $openIndex - 1)
    $ports = @(Split-TopLevelCommaList -Text $portText)
    $keptPorts = [System.Collections.Generic.List[string]]::new()
    $removed = [ordered]@{}
    foreach ($tapName in $TapMap.Keys) {
        $removed[$tapName] = 0
    }

    foreach ($port in $ports) {
        $signature = Get-CompactSignature -Text $port
        $matchedTap = $null
        foreach ($tapName in $TapMap.Keys) {
            if ($signature -eq "outputlogic$tapName") {
                $matchedTap = $tapName
                break
            }
        }
        if ($null -ne $matchedTap) {
            $removed[$matchedTap]++
        }
        else {
            $keptPorts.Add($port)
        }
    }

    foreach ($tapName in $TapMap.Keys) {
        $expected = if ($ExpectTaps) { 1 } else { 0 }
        if ($removed[$tapName] -ne $expected) {
            throw "Port $tapName count $($removed[$tapName]); expected $expected."
        }
    }

    # Reconstruct the comma-separated list after deleting complete port items.
    # This canonicalizes only the separator necessarily added before the taps.
    $rebuiltPortText = [string]::Join(',', $keptPorts)
    $rebuilt = $Text.Substring(0, $openIndex + 1) + $rebuiltPortText + $Text.Substring($closeIndex)

    [pscustomobject]@{
        Text = $rebuilt
        OriginalPortCount = $ports.Count
        RetainedPortCount = $keptPorts.Count
        RemovedPorts = $removed
    }
}

function ConvertTo-SystemVerilogTokens {
    param([string]$Text)

    $tokens = [System.Collections.Generic.List[string]]::new()
    $multiOperators = @(
        '<<<', '>>>', '===', '!==', '==?', '!=?', '->>', '<->',
        '::', '->', '=>', '**', '++', '--', '&&', '||', '<<', '>>',
        '<=', '>=', '==', '!=', '+=', '-=', '*=', '/=', '%=', '&=', '|=',
        '^=', '~^', '^~', '##', '.*', '+:', '-:'
    ) | Sort-Object Length -Descending

    $index = 0
    while ($index -lt $Text.Length) {
        $character = $Text[$index]
        if ([char]::IsWhiteSpace($character)) {
            $index++
            continue
        }

        if ($character -eq '"') {
            $start = $index
            $index++
            $closed = $false
            while ($index -lt $Text.Length) {
                if ($Text[$index] -eq '\') {
                    $index += 2
                    continue
                }
                if ($Text[$index] -eq '"') {
                    $index++
                    $closed = $true
                    break
                }
                $index++
            }
            if (-not $closed) {
                throw "Unterminated string token."
            }
            $tokens.Add($Text.Substring($start, $index - $start))
            continue
        }

        if ($character -eq '\') {
            $start = $index
            $index++
            while ($index -lt $Text.Length -and -not [char]::IsWhiteSpace($Text[$index])) {
                $index++
            }
            $tokens.Add($Text.Substring($start, $index - $start))
            continue
        }

        if ([char]::IsLetterOrDigit($character) -or $character -eq '_' -or $character -eq '$') {
            $start = $index
            $index++
            while ($index -lt $Text.Length) {
                $current = $Text[$index]
                if (-not ([char]::IsLetterOrDigit($current) -or $current -eq '_' -or $current -eq '$')) {
                    break
                }
                $index++
            }
            $tokens.Add($Text.Substring($start, $index - $start))
            continue
        }

        $operator = $null
        foreach ($candidate in $multiOperators) {
            if ($index + $candidate.Length -le $Text.Length -and
                $Text.Substring($index, $candidate.Length) -ceq $candidate) {
                $operator = $candidate
                break
            }
        }
        if ($null -ne $operator) {
            $tokens.Add($operator)
            $index += $operator.Length
        }
        else {
            $tokens.Add([string]$character)
            $index++
        }
    }
    $tokens.ToArray()
}

function Count-Token {
    param(
        [string[]]$Tokens,
        [string]$Needle
    )
    (@($Tokens | Where-Object { $_ -ceq $Needle })).Count
}

function Remove-AllowlistedTapAssignments {
    param(
        [string[]]$Tokens,
        [bool]$ExpectTaps
    )

    $removeAt = [System.Collections.Generic.HashSet[int]]::new()
    $counts = [ordered]@{}
    foreach ($tapName in $TapMap.Keys) {
        $rhsName = $TapMap[$tapName]
        $count = 0
        for ($index = 0; $index -le $Tokens.Count - 5; $index++) {
            if ($Tokens[$index] -ceq 'assign' -and
                $Tokens[$index + 1] -ceq $tapName -and
                $Tokens[$index + 2] -ceq '=' -and
                $Tokens[$index + 3] -ceq $rhsName -and
                $Tokens[$index + 4] -ceq ';') {
                $count++
                foreach ($offset in 0..4) {
                    [void]$removeAt.Add($index + $offset)
                }
            }
        }
        $counts[$tapName] = $count
        $expected = if ($ExpectTaps) { 1 } else { 0 }
        if ($count -ne $expected) {
            throw "Assignment 'assign $tapName = $rhsName;' count $count; expected $expected."
        }
    }

    $remaining = [System.Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt $Tokens.Count; $index++) {
        if (-not $removeAt.Contains($index)) {
            $remaining.Add($Tokens[$index])
        }
    }

    [pscustomobject]@{
        Tokens = $remaining.ToArray()
        RemovedAssignments = $counts
    }
}

function Get-CanonicalByteStream {
    param([string[]]$Tokens)
    $builder = [System.Text.StringBuilder]::new()
    foreach ($token in $Tokens) {
        [void]$builder.Append($token.Length.ToString([System.Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.Append(':')
        [void]$builder.Append($token)
    }
    [System.Text.UTF8Encoding]::new($false).GetBytes($builder.ToString())
}

function Get-BlobEvidence {
    param(
        [string]$Commit,
        [bool]$ExpectTaps
    )

    $revision = "$Commit`:$SourcePath"
    $blobIdRaw = Invoke-GitRaw -GitArguments @('rev-parse', $revision)
    $blobId = (Convert-BytesToStrictUtf8 -Bytes $blobIdRaw.Bytes).Trim()
    if ($blobId -notmatch '^[0-9a-f]{40}$') {
        throw "Unexpected blob id '$blobId' for $revision."
    }

    $blobRaw = Invoke-GitRaw -GitArguments @('show', $revision)
    $blobBytes = [byte[]]$blobRaw.Bytes
    $blobText = Convert-BytesToStrictUtf8 -Bytes $blobBytes
    $comments = Remove-SystemVerilogComments -Text $blobText
    $rawTokens = @(ConvertTo-SystemVerilogTokens -Text $comments.Text)
    $ports = Remove-AllowlistedTapPorts -Text $comments.Text -ExpectTaps $ExpectTaps
    $portCanonicalTokens = @(ConvertTo-SystemVerilogTokens -Text $ports.Text)
    $assignments = Remove-AllowlistedTapAssignments -Tokens $portCanonicalTokens -ExpectTaps $ExpectTaps
    $canonicalTokens = @($assignments.Tokens)

    $tapOccurrenceCounts = [ordered]@{}
    $remainingTapCounts = [ordered]@{}
    foreach ($tapName in $TapMap.Keys) {
        $tapOccurrenceCounts[$tapName] = Count-Token -Tokens $rawTokens -Needle $tapName
        $remainingTapCounts[$tapName] = Count-Token -Tokens $canonicalTokens -Needle $tapName
        $expectedRaw = if ($ExpectTaps) { 2 } else { 0 }
        if ($tapOccurrenceCounts[$tapName] -ne $expectedRaw) {
            throw "Identifier $tapName occurs $($tapOccurrenceCounts[$tapName]) times; expected $expectedRaw."
        }
        if ($remainingTapCounts[$tapName] -ne 0) {
            throw "Identifier $tapName remains after allowlisted exclusions."
        }
    }

    $canonicalBytes = Get-CanonicalByteStream -Tokens $canonicalTokens
    [pscustomobject]@{
        Commit = $Commit
        SourcePath = $SourcePath
        GitBlobId = $blobId
        RawByteCount = $blobBytes.Count
        RawSha256 = Get-Sha256Hex -Bytes $blobBytes
        LineCommentCount = $comments.LineCommentCount
        BlockCommentCount = $comments.BlockCommentCount
        RawTokenCountAfterCommentRemoval = $rawTokens.Count
        OriginalPortCount = $ports.OriginalPortCount
        RetainedPortCount = $ports.RetainedPortCount
        RemovedPorts = $ports.RemovedPorts
        RemovedAssignments = $assignments.RemovedAssignments
        TapIdentifierOccurrencesBeforeExclusion = $tapOccurrenceCounts
        TapIdentifierOccurrencesAfterExclusion = $remainingTapCounts
        CanonicalTokenCount = $canonicalTokens.Count
        CanonicalByteCount = $canonicalBytes.Count
        CanonicalSha256 = Get-Sha256Hex -Bytes $canonicalBytes
        CanonicalTokens = $canonicalTokens
    }
}

$repositoryItem = Get-Item -LiteralPath $Repository
if (-not $repositoryItem.PSIsContainer) {
    throw "Repository path is not a directory: $Repository"
}

$product = Get-BlobEvidence -Commit $ProductCommit -ExpectTaps $false
$diagnostic = Get-BlobEvidence -Commit $DiagnosticCommit -ExpectTaps $true

$firstMismatch = $null
if ($product.CanonicalTokens.Count -ne $diagnostic.CanonicalTokens.Count) {
    $firstMismatch = "token-count:$($product.CanonicalTokens.Count):$($diagnostic.CanonicalTokens.Count)"
}
else {
    for ($index = 0; $index -lt $product.CanonicalTokens.Count; $index++) {
        if ($product.CanonicalTokens[$index] -cne $diagnostic.CanonicalTokens[$index]) {
            $firstMismatch = "token-index:$index product='$($product.CanonicalTokens[$index])' diagnostic='$($diagnostic.CanonicalTokens[$index])'"
            break
        }
    }
}

$functionalIdentity = ($null -eq $firstMismatch) -and
    ($product.CanonicalSha256 -ceq $diagnostic.CanonicalSha256)

$result = [ordered]@{
    Schema = 'AHD_V41_G2B_FUNCTIONAL_BODY_COMPARISON_V1'
    Method = 'COMMENT_STRIP_THEN_EXACT_PORT_ITEM_EXCLUSION_THEN_EXACT_ASSIGN_TOKEN_EXCLUSION_THEN_LENGTH_PREFIXED_TOKEN_STREAM'
    Repository = $repositoryItem.FullName
    Product = [ordered]@{
        Commit = $product.Commit
        GitBlobId = $product.GitBlobId
        RawByteCount = $product.RawByteCount
        RawSha256 = $product.RawSha256
        OriginalPortCount = $product.OriginalPortCount
        RetainedPortCount = $product.RetainedPortCount
        RawTokenCountAfterCommentRemoval = $product.RawTokenCountAfterCommentRemoval
        CanonicalTokenCount = $product.CanonicalTokenCount
        CanonicalByteCount = $product.CanonicalByteCount
        CanonicalSha256 = $product.CanonicalSha256
        TapIdentifierOccurrences = $product.TapIdentifierOccurrencesBeforeExclusion
    }
    Diagnostic = [ordered]@{
        Commit = $diagnostic.Commit
        GitBlobId = $diagnostic.GitBlobId
        RawByteCount = $diagnostic.RawByteCount
        RawSha256 = $diagnostic.RawSha256
        OriginalPortCount = $diagnostic.OriginalPortCount
        RetainedPortCount = $diagnostic.RetainedPortCount
        RawTokenCountAfterCommentRemoval = $diagnostic.RawTokenCountAfterCommentRemoval
        CanonicalTokenCount = $diagnostic.CanonicalTokenCount
        CanonicalByteCount = $diagnostic.CanonicalByteCount
        CanonicalSha256 = $diagnostic.CanonicalSha256
        RemovedPorts = $diagnostic.RemovedPorts
        RemovedAssignments = $diagnostic.RemovedAssignments
        TapIdentifierOccurrencesBeforeExclusion = $diagnostic.TapIdentifierOccurrencesBeforeExclusion
        TapIdentifierOccurrencesAfterExclusion = $diagnostic.TapIdentifierOccurrencesAfterExclusion
    }
    ExactTapMappings = $TapMap
    FirstCanonicalMismatch = $firstMismatch
    G2B_FUNCTIONAL_BODY_IDENTITY = if ($functionalIdentity) { 'PASS' } else { 'FAIL' }
    DIAGNOSTIC_TAPS_ONLY = if ($functionalIdentity) { 'YES' } else { 'NO' }
    SOURCE_LEVEL_TAP_FEEDBACK = if ($functionalIdentity) { 'NONE' } else { 'UNPROVEN' }
    FUNCTIONAL_OWNERSHIP_LOGIC_CHANGED = if ($functionalIdentity) { 'NO' } else { 'UNPROVEN' }
    FUNCTIONAL_RELEASE_LOGIC_CHANGED = if ($functionalIdentity) { 'NO' } else { 'UNPROVEN' }
    FUNCTIONAL_RESET_LOGIC_CHANGED = if ($functionalIdentity) { 'NO' } else { 'UNPROVEN' }
    DCP_LEVEL_TAP_NONINTERFERENCE = 'NOT_REACHED_NO_VIVADO_IN_THIS_SOURCE_ONLY_STEP'
}

$result | ConvertTo-Json -Depth 8
if (-not $functionalIdentity) {
    exit 2
}
