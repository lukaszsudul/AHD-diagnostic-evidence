param([ValidateSet('acquire','release')][string]$Mode)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$path='C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
if($Mode -eq 'acquire'){
 if(Test-Path -LiteralPath $path){throw 'CONTROLLER_LOCK_EXISTS'}
 $conflicts=@(Get-Process | Where-Object ProcessName -match '^(vivado|vivado_lab|hw_server|xsdb|cs_server|xicom|plink)$')
 if($conflicts.Count){throw 'CONTROLLER_PROCESS_CONFLICT'}
 New-Item -ItemType Directory -Path $path -ErrorAction Stop | Out-Null
 $receipt=[ordered]@{schema='AHD_DUT_EXCLUSIVE_LOCK_V1';task='G2B-HW0-PRODUCT-R3R3';state='HELD';thread='01a0784d-110e-7f60-b752-6220966e6c6c';root=$root;utc=[DateTime]::UtcNow.ToString('o');linux_lock_state='NOT_YET_ACQUIRED';sram_programming_attempts=0;warm_reboot_delivery_attempts=0;warm_reboot_budget_remaining=1}
 $json=$receipt | ConvertTo-Json
 $json|Set-Content -LiteralPath (Join-Path $path 'receipt.json')
 $json|Set-Content -LiteralPath (Join-Path $root 'logs\controller-lock-acquired.json')
}else{
 $receipt=Get-Content -Raw (Join-Path $path 'receipt.json') | ConvertFrom-Json
 if($receipt.task -cne 'G2B-HW0-PRODUCT-R3R3' -or $receipt.root -cne $root){throw 'CONTROLLER_LOCK_OWNER_MISMATCH'}
 $receipt.state='RELEASED';$receipt.utc=[DateTime]::UtcNow.ToString('o')
 $receipt|ConvertTo-Json|Set-Content (Join-Path $root 'logs\controller-lock-released.json')
 Remove-Item -LiteralPath (Join-Path $path 'receipt.json')
 Remove-Item -LiteralPath $path
}
"CONTROLLER_LOCK_$Mode=PASS"
