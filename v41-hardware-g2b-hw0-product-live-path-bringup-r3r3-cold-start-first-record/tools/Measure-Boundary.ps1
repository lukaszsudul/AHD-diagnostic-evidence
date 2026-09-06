param([ValidateSet('before','after')][string]$Phase='before')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$roots=@(Get-ChildItem C:\FPGA -Directory | Where-Object {$_.Name -match '^(G2B_HW0_PRODUCT_R[123]|G2B_HW0_DRV1|G2B_LUT1_SIGNOFF_RECOVERY4)' -and $_.FullName -cne $root} | Select-Object -ExpandProperty FullName)
if(Test-Path C:\FPGA\V41_G2B_HW_EVIDENCE){$roots+=@(Get-ChildItem C:\FPGA\V41_G2B_HW_EVIDENCE -Directory | Where-Object Name -like 'G2B_HW0_PRODUCT_R3*' | Select-Object -ExpandProperty FullName)}
$roots+=@(Get-ChildItem C:\FPGA\V41_G2B_EVIDENCE -Directory | Where-Object {$_.Name -match '^(project-current-state|v41-)' -and $_.Name -ne 'v41-hardware-g2b-hw0-product-live-path-bringup-r3r3-cold-start-first-record'} | Select-Object -ExpandProperty FullName)
$rows=@(foreach($r in $roots){foreach($f in @((Get-Item -LiteralPath $r)) + @(Get-ChildItem -LiteralPath $r -Force -Recurse)){
 [pscustomobject]@{path=$f.FullName;directory=$f.PSIsContainer;size=if($f.PSIsContainer){0}else{$f.Length};created=if($f.PSIsContainer){'DIRECTORY_ENTRY_ONLY'}else{$f.CreationTimeUtc.ToString('o')};modified=if($f.PSIsContainer){'DIRECTORY_ENTRY_ONLY'}else{$f.LastWriteTimeUtc.ToString('o')};sha256=if(-not $f.PSIsContainer -and $f.FullName -notmatch '[\\/]secret[\\/]|[\\/]private[\\/]' -and $f.Name -match '(manifest|receipt|index)' -and $f.Length -lt 1000000){(Get-FileHash -LiteralPath $f.FullName).Hash}else{'METADATA_ONLY'}}
}})
$out=Join-Path $root "logs\boundary-$Phase.json"
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $out -Encoding utf8
if($Phase -eq 'after'){
 $before=Get-Content -Raw (Join-Path $root 'logs\boundary-before.json') | ConvertFrom-Json -DateKind String
 $a=@($before | ConvertTo-Csv -NoTypeInformation);$b=@($rows | ConvertTo-Csv -NoTypeInformation)
 $delta=@(Compare-Object $a $b)
 [pscustomobject]@{rows=$rows.Count;difference_count=$delta.Count;result=if($delta.Count){'FAIL'}else{'PASS'}} | ConvertTo-Json
 if($delta.Count){throw 'PRIOR_IMMUTABLE_BOUNDARY_CHANGED'}
}else{[pscustomobject]@{roots=$roots.Count;rows=$rows.Count;phase=$Phase} | ConvertTo-Json}
