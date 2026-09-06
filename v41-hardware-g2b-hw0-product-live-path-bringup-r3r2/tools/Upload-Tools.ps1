$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$remoteRoot='/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r2/20260906T182010Z/scripts'
foreach($name in @('abi_v1.py','V41_C2H_TRANSPORT_ABI_V1.json','capture.py')){
 $bytes=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $name))
 $part=0
 for($offset=0;$offset -lt $bytes.Length;$offset+=7000){
  $n=[Math]::Min(7000,$bytes.Length-$offset);$chunk=[Convert]::ToBase64String($bytes,$offset,$n)
  $mode=if($offset -eq 0){'xb'}else{'ab'}
  $code="import base64; f=open('$remoteRoot/$name','$mode'); f.write(base64.b64decode('$chunk')); f.close()"
  $cmd="python3 - <<'UPLOAD'`n$code`nUPLOAD"
  & (Join-Path $PSScriptRoot 'Invoke-R3R2DutConnection.ps1') -ReceiptName ('upload-'+$name.Replace('.','-')+'-'+$part) -Sudo -RemoteCommand $cmd | Out-Null
  $part++
 }
 $sha=(Get-FileHash (Join-Path $PSScriptRoot $name)).Hash
 $code="import hashlib; p='$remoteRoot/$name'; s=hashlib.sha256(open(p,'rb').read()).hexdigest().upper(); print(s); assert s=='$sha'"
 & (Join-Path $PSScriptRoot 'Invoke-R3R2DutConnection.ps1') -ReceiptName ('verify-upload-'+$name.Replace('.','-')) -Sudo -RemoteCommand ("python3 - <<'VERIFY'`n$code`nVERIFY") | Out-Null
 Write-Output "$name $sha TRANSFER_PASS"
}
