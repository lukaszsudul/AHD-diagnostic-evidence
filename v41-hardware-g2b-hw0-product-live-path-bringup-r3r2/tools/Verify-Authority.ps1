$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$repo='C:\FPGA\V41_G2B_EVIDENCE'
$packages=@(
 @('project-current-state','38265d0ba692a6b66d58a74512b63469d341aa6c'),
 @('v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization','f92f4d8fcc0dc88d3dc5753c799e1d891846e392'),
 @('v41-development-g2b-lut1-signoff-recovery-4','6843d582fd367fbc0edc0b1d55a9617162c489b0'),
 @('v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot','9caa9c339966eda999219e4ed686c01654b9a87e'),
 @('v41-host-g2b-hw0-ahd-xdma-driver-build','9aacc157dab5fe604faf66501b0129613b98ae2d'),
 @('v41-hardware-g2b-hw0-product-live-path-bringup-r3','8c957106a82deeb9649211696177fa5f6529b051'),
 @('v41-hardware-g2b-hw0-product-live-path-bringup-r3r1','38265d0ba692a6b66d58a74512b63469d341aa6c'))
$results=@()
foreach($pkg in $packages){
 $dir=Join-Path $repo $pkg[0]
 $manifest=@(Get-ChildItem -LiteralPath $dir -File -Filter '*SHA256*MANIFEST*' | Where-Object Name -notmatch 'SEALED_ARTIFACT')
 if($manifest.Count -ne 1){throw "MANIFEST_SELECTION:$($pkg[0]):$($manifest.Count)"}
 $tree=@{}
 foreach($line in (git -C $repo ls-tree -r $pkg[1] -- $pkg[0])){if($line -match '^\d+ blob ([0-9a-f]{40})\t(.+)$'){$tree[$Matches[2]]=$Matches[1]}}
 $pass=0;$excluded=@();$issues=@()
 foreach($line in Get-Content -LiteralPath $manifest[0].FullName){
  if($line -notmatch '^([0-9A-Fa-f]{64})\s+\*?(.+)$'){continue}
  $expected=$Matches[1].ToUpperInvariant();$rel=$Matches[2].Trim().Replace('\','/');$path=Join-Path $dir $rel
  $key=$pkg[0]+'/'+$rel
  if(-not $tree.ContainsKey($key)){$excluded+=$rel;continue}
  if(-not(Test-Path -LiteralPath $path -PathType Leaf)){$issues+="MISSING:$rel";continue}
  $bytes=[IO.File]::ReadAllBytes($path)
  $sha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
  $prefix=[Text.Encoding]::ASCII.GetBytes("blob $($bytes.Length)"+[char]0)
  $blob=[Convert]::ToHexString([Security.Cryptography.SHA1]::HashData([byte[]]($prefix+$bytes))).ToLowerInvariant()
  if($sha -cne $expected -or $blob -cne $tree[$key]){$issues+="HASH_OR_BLOB:$rel"}else{$pass++}
 }
 $results += [pscustomobject]@{directory=$pkg[0];commit=$pkg[1];passed=$pass;excluded_unpublished=$excluded;issues=$issues}
}
$results | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'logs\authority.json') -Encoding utf8
$results | ConvertTo-Json -Depth 6
if(@($results | Where-Object {$_.issues.Count -gt 0 -or $_.passed -eq 0}).Count){throw 'AUTHORITY_MANIFEST_FAILED'}
