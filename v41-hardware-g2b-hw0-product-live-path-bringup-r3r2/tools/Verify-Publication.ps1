param([ValidateSet('seal','remote')][string]$Mode='seal',[string]$Commit)
$ErrorActionPreference='Stop'
$r=Split-Path $PSScriptRoot -Parent
$repo='C:\FPGA\V41_G2B_EVIDENCE'
$rel='v41-hardware-g2b-hw0-product-live-path-bringup-r3r2'
$d=Join-Path $repo $rel
$manifest='G2B_HW0_PRODUCT_R3R2_SHA256_MANIFEST.txt'
$utf=[Text.UTF8Encoding]::new($false)
if($Mode -eq 'seal'){
 foreach($f in Get-ChildItem $PSScriptRoot -File){Copy-Item $f.FullName "$d\tools\$($f.Name)" -Force}
 foreach($n in @('first-identity','prelock','linux-lock-baseline')){
  $j=Get-Content -Raw "$r\logs\connection-$n.json"|ConvertFrom-Json
  [IO.File]::WriteAllText("$d\raw\$n-sanitized.txt",$j.stdout,$utf)
 }
 $a=Get-FileHash "$r\logs\boundary-before.json"; $b=Get-FileHash "$r\logs\boundary-after.json"
 if($a.Hash -cne $b.Hash){throw 'BOUNDARY_HASH_DRIFT'}
 [IO.File]::WriteAllText("$d\raw\boundary-comparison.json",([ordered]@{rows=10814;differences=0;before_sha256=$a.Hash;after_sha256=$b.Hash;result='PASS'}|ConvertTo-Json)+"`n",$utf)
 $files=Get-ChildItem $d -Recurse -File | Where-Object Name -ne $manifest | Sort-Object FullName
 if(@($files|Where-Object Extension -in @('.ko','.bin','.bit','.dcp','.uyvy','.png','.jpg','.tmp')).Count){throw 'PROHIBITED_PUBLIC_ARTIFACT'}
 $index="# R3R2 evidence index`n`nEngineering BLOCKED; publication independently verified. Relative paths, including full task sources and sanitized receipts:`n`n"+(($files | ForEach-Object {'- '+[IO.Path]::GetRelativePath($d,$_.FullName).Replace('\','/')})-join "`n")+"`n"
 [IO.File]::WriteAllText("$d\G2B_HW0_PRODUCT_R3R2_EVIDENCE_INDEX.md",$index,$utf)
 $lines=$files|ForEach-Object {(Get-FileHash $_.FullName).Hash+'  '+[IO.Path]::GetRelativePath($d,$_.FullName).Replace('\','/')}
 [IO.File]::WriteAllText("$d\$manifest",($lines-join "`n")+"`n",$utf)
 foreach($line in Get-Content "$d\$manifest"){
  if($line -notmatch '^([A-F0-9]{64})  (.+)$'){throw 'MANIFEST_FORMAT'}
  if((Get-FileHash (Join-Path $d $Matches[2])).Hash -cne $Matches[1]){throw 'MANIFEST_SHA'}
 }
 "SEALED_FILES=$(@(Get-ChildItem $d -Recurse -File).Count)"
 exit
}
if($Commit -notmatch '^[a-f0-9]{40}$'){throw 'COMMIT_REQUIRED'}
$tree=gh api "repos/lukaszsudul/AHD-diagnostic-evidence/git/trees/${Commit}?recursive=1" | ConvertFrom-Json
if($LASTEXITCODE -or $tree.truncated){throw 'REMOTE_TREE_FAILED'}
$entries=@($tree.tree | Where-Object {$_.type -eq 'blob' -and $_.path.StartsWith($rel+'/')})
if($entries.Count -ne @(Get-ChildItem $d -File -Recurse).Count){throw 'REMOTE_FILE_SET_COUNT'}
$results=@($entries | ForEach-Object -Parallel {
 $ErrorActionPreference='Stop'
 $entry=$_;$base=$using:repo
 $path=Join-Path $base $entry.path
 $b64=gh api ('repos/lukaszsudul/AHD-diagnostic-evidence/git/blobs/'+$entry.sha) --jq '.content'
 if($LASTEXITCODE){throw 'REMOTE_BLOB_FETCH'}
 $remote=[Convert]::FromBase64String(($b64-join ''))
 $local=[IO.File]::ReadAllBytes($path)
 $rh=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($remote))
 $lh=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($local))
 $prefix=[Text.Encoding]::ASCII.GetBytes("blob $($remote.Length)"+[char]0)
 $blob=[Convert]::ToHexString([Security.Cryptography.SHA1]::HashData([byte[]]($prefix+$remote))).ToLowerInvariant()
 if($rh -cne $lh -or $blob -cne $entry.sha -or $local.Length -ne $remote.Length){throw ('REMOTE_IDENTITY_FAIL '+$entry.path)}
 [pscustomobject]@{path=$entry.path;bytes=$remote.Length;sha256=$rh;git_blob=$blob;result='PASS'}
} -ThrottleLimit 5)
if($results.Count -ne $entries.Count){throw 'INCOMPLETE_REMOTE_VERIFICATION'}
$receipt=[ordered]@{commit=$Commit;repository='lukaszsudul/AHD-diagnostic-evidence';directory=$rel;result='PASS';files=$results.Count;utc=[DateTime]::UtcNow.ToString('o');method='Commit-pinned Git tree and API blob content; exact bytes by length/SHA256 plus Git blob SHA1';entries=$results}
[IO.File]::WriteAllText("$r\artifacts\REMOTE_READBACK_RECEIPT.json",($receipt|ConvertTo-Json -Depth 6)+"`n",$utf)
"REMOTE_READBACK_PASS $Commit FILES=$($results.Count)"
