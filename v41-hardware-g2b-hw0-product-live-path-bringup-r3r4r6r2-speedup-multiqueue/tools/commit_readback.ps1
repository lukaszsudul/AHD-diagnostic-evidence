$ErrorActionPreference='Stop'
$r=Split-Path $PSScriptRoot -Parent
$repo='C:\FPGA\V41_G2B_EVIDENCE'
$rel='v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r6r2-speedup-multiqueue'
$dest=Join-Path $repo $rel
if(Test-Path $dest){throw 'NEW_PUBLICATION_DIRECTORY_EXISTS'}
Copy-Item -LiteralPath "$r\evidence-staging" -Destination $dest -Recurse
$manifest=Join-Path $dest 'G2B_HW0_PRODUCT_R3R4R6R2_SHA256_MANIFEST.txt'
foreach($line in Get-Content $manifest){
 if($line -notmatch '^([A-F0-9]{64})  (.+)$'){throw 'MANIFEST_FORMAT'}
 $expected=$Matches[1];$path=Join-Path $dest $Matches[2]
 if((Get-FileHash $path).Hash -cne $expected){throw 'MANIFEST_SHA'}
}
git -C $repo add --sparse -- $rel
if($LASTEXITCODE){throw 'STAGE_FAILED'}
$staged=@(git -C $repo diff --cached --name-only)
if(@($staged|Where-Object {-not $_.StartsWith($rel+'/')}).Count){throw 'UNRELATED_STAGED_FILES_STOP'}
git -C $repo -c core.whitespace=cr-at-eol diff --cached --check
if($LASTEXITCODE){throw 'DIFF_CHECK_FAILED'}
git -C $repo commit -m 'Run AHD v41 G2B-HW0 PRODUCT R3R4R6R2 speed-up multi-request finite qualification'
if($LASTEXITCODE){throw 'COMMIT_FAILED'}
$commit=(git -C $repo rev-parse HEAD).Trim()
git -C $repo push origin HEAD:main
if($LASTEXITCODE){throw 'PUSH_FAILED'}
$tree=gh api "repos/lukaszsudul/AHD-diagnostic-evidence/git/trees/${commit}?recursive=1"|ConvertFrom-Json
if($LASTEXITCODE -or $tree.truncated){throw 'NEW_COMMIT_REMOTE_TREE_FAILED'}
$entries=@($tree.tree|Where-Object {$_.type -eq 'blob' -and $_.path.StartsWith($rel+'/')})
if($entries.Count -ne @(Get-ChildItem $dest -Recurse -File).Count){throw 'REMOTE_FILE_SET_MISMATCH'}
$results=@($entries|ForEach-Object -Parallel {
 $ErrorActionPreference='Stop';$e=$_;$root=$using:repo
 $encoded=gh api ('repos/lukaszsudul/AHD-diagnostic-evidence/git/blobs/'+$e.sha) --jq '.content'
 if($LASTEXITCODE){throw 'REMOTE_BLOB_FAILED'}
 $bytes=[Convert]::FromBase64String(($encoded-join ''))
 $local=[IO.File]::ReadAllBytes((Join-Path $root $e.path))
 $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
 $lh=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($local))
 $prefix=[Text.Encoding]::ASCII.GetBytes("blob $($bytes.Length)"+[char]0)
 $blob=[Convert]::ToHexString([Security.Cryptography.SHA1]::HashData([byte[]]($prefix+$bytes))).ToLowerInvariant()
 if($hash -cne $lh -or $bytes.Length -ne $local.Length -or $blob -cne $e.sha){throw 'REMOTE_BYTES_OR_BLOB_MISMATCH'}
 [pscustomobject]@{path=$e.path;bytes=$bytes.Length;sha256=$hash;git_blob=$blob;result='PASS'}
} -ThrottleLimit 5)
if($results.Count -ne $entries.Count){throw 'REMOTE_READBACK_INCOMPLETE'}
$receipt=[ordered]@{commit=$commit;repository='lukaszsudul/AHD-diagnostic-evidence';directory=$rel;result='PASS';files=$results.Count;utc=[DateTime]::UtcNow.ToString('o');method='One commit-pinned readback; exact content SHA256,length and Git blob identity';entries=$results}
[IO.File]::WriteAllText("$r\artifacts\REMOTE_READBACK_RECEIPT.json",($receipt|ConvertTo-Json -Depth 5)+"`n",[Text.UTF8Encoding]::new($false))
"EVIDENCE_COMMIT=$commit REMOTE_READBACK=PASS FILES=$($results.Count)"
