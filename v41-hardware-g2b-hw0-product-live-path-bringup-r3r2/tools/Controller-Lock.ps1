param([ValidateSet('acquire','release')][string]$Mode)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$path='C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
if($Mode -eq 'acquire'){
 if(Test-Path -LiteralPath $path){throw 'CONTROLLER_LOCK_EXISTS'}
 $conflicts=@(Get-Process | Where-Object ProcessName -match '^(vivado|vivado_lab|hw_server|xsdb|cs_server|xicom|plink)$')
 if($conflicts.Count){throw 'CONTROLLER_PROCESS_CONFLICT'}
 New-Item -ItemType Directory -Path $path -ErrorAction Stop | Out-Null
 $receipt=[ordered]@{schema='AHD_DUT_EXCLUSIVE_LOCK_V1';task='G2B-HW0-PRODUCT-R3R2';state='HELD';thread='01a077b1-9416-75b3-a5f0-4bdc760c3da8';root=$root;utc=[DateTime]::UtcNow.ToString('o');linux_lock_state='NOT_YET_ACQUIRED'}
 $json=$receipt | ConvertTo-Json
 $json|Set-Content -LiteralPath (Join-Path $path 'receipt.json')
 $json|Set-Content -LiteralPath (Join-Path $root 'logs\controller-lock-acquired.json')
}else{
 $receipt=Get-Content -Raw (Join-Path $path 'receipt.json') | ConvertFrom-Json
 if($receipt.task -cne 'G2B-HW0-PRODUCT-R3R2' -or $receipt.root -cne $root){throw 'CONTROLLER_LOCK_OWNER_MISMATCH'}
 $receipt.state='RELEASED';$receipt.utc=[DateTime]::UtcNow.ToString('o')
 $receipt|ConvertTo-Json|Set-Content (Join-Path $root 'logs\controller-lock-released.json')
 Remove-Item -LiteralPath (Join-Path $path 'receipt.json')
 Remove-Item -LiteralPath $path
}
"CONTROLLER_LOCK_$Mode=PASS"
