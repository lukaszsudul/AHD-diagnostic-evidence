param([Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$Commit)
$ErrorActionPreference='Stop'
$run='C:\FPGA\G2B_HW0_PRODUCT_R3R3_20260906T200624Z'
$repo='C:\FPGA\V41_G2B_EVIDENCE'
$rel='v41-hardware-g2b-hw0-product-live-path-bringup-r3r3-cold-start-first-record'
$directory=Join-Path $repo $rel
$utf=[Text.UTF8Encoding]::new($false)

$tree=gh api "repos/lukaszsudul/AHD-diagnostic-evidence/git/trees/${Commit}?recursive=1" | ConvertFrom-Json
if($LASTEXITCODE -or $tree.truncated){throw 'R3R3_REMOTE_TREE_FAILED'}
$entries=@($tree.tree | Where-Object {$_.type -eq 'blob' -and $_.path.StartsWith($rel+'/')})
$localFiles=@(Get-ChildItem -LiteralPath $directory -File -Recurse)
if($entries.Count -ne $localFiles.Count){throw 'R3R3_REMOTE_FILE_SET_COUNT_MISMATCH'}

$results=@($entries | ForEach-Object -Parallel {
 $ErrorActionPreference='Stop'
 $entry=$_
 $localPath=Join-Path $using:repo $entry.path
 if(-not(Test-Path -LiteralPath $localPath -PathType Leaf)){throw ('R3R3_REMOTE_ONLY_PATH '+$entry.path)}
 $encoded=gh api ('repos/lukaszsudul/AHD-diagnostic-evidence/git/blobs/'+$entry.sha) --jq '.content'
 if($LASTEXITCODE){throw ('R3R3_REMOTE_BLOB_FETCH_FAILED '+$entry.path)}
 $remoteBytes=[Convert]::FromBase64String(($encoded-join ''))
 $localBytes=[IO.File]::ReadAllBytes($localPath)
 $remoteSha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($remoteBytes))
 $localSha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($localBytes))
 $prefix=[Text.Encoding]::ASCII.GetBytes("blob $($remoteBytes.Length)"+[char]0)
 $blobSha=[Convert]::ToHexString([Security.Cryptography.SHA1]::HashData(
   [byte[]]($prefix+$remoteBytes))).ToLowerInvariant()
 if($remoteSha -cne $localSha -or $blobSha -cne $entry.sha -or
    $remoteBytes.Length -ne $localBytes.Length){
   throw ('R3R3_REMOTE_IDENTITY_MISMATCH '+$entry.path)
 }
 [pscustomobject]@{path=$entry.path;bytes=$remoteBytes.Length;sha256=$remoteSha;
                   git_blob=$blobSha;result='PASS'}
} -ThrottleLimit 5)
if($results.Count -ne $entries.Count){throw 'R3R3_INCOMPLETE_REMOTE_VERIFICATION'}

$receipt=[ordered]@{
 task='G2B-HW0-PRODUCT-R3R3'
 commit=$Commit
 repository='lukaszsudul/AHD-diagnostic-evidence'
 directory=$rel
 result='PASS'
 files=$results.Count
 utc=[DateTime]::UtcNow.ToString('o')
 method='Commit-pinned Git tree and API blob content; exact bytes by length/SHA256 plus Git blob SHA1'
 entries=$results
}
[IO.File]::WriteAllText((Join-Path $run 'artifacts\REMOTE_READBACK_RECEIPT.json'),
  ($receipt|ConvertTo-Json -Depth 6)+"`n",$utf)
"REMOTE_READBACK_PASS $Commit FILES=$($results.Count)"
