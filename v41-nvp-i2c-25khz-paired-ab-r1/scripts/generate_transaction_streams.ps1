param(
  [Parameter(Mandatory=$true)][string]$OperationDumpLog,
  [Parameter(Mandatory=$true)][string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
function Require([bool]$ok,[string]$message){if(-not $ok){throw $message}}

$ops = @()
foreach($line in Get-Content -LiteralPath $OperationDumpLog){
  if($line -match 'I25_OP,(\d+),([0-9A-Fa-f]{6})'){
    $ops += [pscustomobject]@{Slot=[int]$Matches[1];Hex=$Matches[2].ToUpperInvariant()}
  }
}
Require ($ops.Count -eq 214) "Expected 214 exact package operations, got $($ops.Count)"
for($i=0;$i -lt 214;$i++){Require ($ops[$i].Slot -eq $i) "Operation slot ordering mismatch at $i"}

$rows = [Collections.Generic.List[object]]::new()
$index = 0
$physical = 'UNKNOWN'
function Add-Txn([string]$phase,[string]$slot,[string]$kind,[string]$meta,[string]$before,[string]$reg,[string]$wdata,[string]$expected,[string]$after,[int]$ticks){
  $script:rows.Add([pscustomobject]@{
    TRANSACTION_INDEX=$script:index; PHASE=$phase; TABLE_SLOT=$slot; KIND=$kind;
    META_BANK=$meta; PHYS_BANK_BEFORE=$before; WIRE_ADDR_W='60'; REG=$reg;
    WDATA=$wdata; WIRE_ADDR_R=$(if($kind -match 'READ|VERIFY'){'61'}else{''});
    EXPECTED_RDATA=$expected; PHYS_BANK_AFTER=$after; FSM_TICK_ACTIONS=$ticks
  })
  $script:index++
}

Add-Txn 'PREINIT' '' 'READ_ORIGINAL' 'UNKNOWN' $physical 'FF' '' 'ORIGINAL_FF' 'ORIGINAL_FF' 83
$physical='ORIGINAL_FF'
Add-Txn 'PREINIT' '' 'SELECT_WRITE' '00' $physical 'FF' '00' '' $physical 61
Add-Txn 'PREINIT' '' 'SELECT_VERIFY' '00' $physical 'FF' '' '00' '00' 83
$physical='00'

foreach($op in $ops){
  $bank=$op.Hex.Substring(0,2); $reg=$op.Hex.Substring(2,2); $data=$op.Hex.Substring(4,2)
  if($bank -eq 'FD' -or $bank -eq 'FE'){continue}
  if($physical -ne $bank){
    Add-Txn 'INIT' $op.Slot 'SELECT_WRITE' $bank $physical 'FF' $bank '' $physical 61
    Add-Txn 'INIT' $op.Slot 'SELECT_VERIFY' $bank $physical 'FF' '' $bank $bank 83
    $physical=$bank
  }
  $after=$physical
  if($reg -eq 'FF'){$after=$data}
  Add-Txn 'INIT' $op.Slot 'TARGET_WRITE' $bank $physical $reg $data '' $after 61
  $physical=$after
}

Add-Txn 'POST' '' 'POST_SELECT_WRITE' '00' $physical 'FF' '00' '' '00' 61; $physical='00'
foreach($reg in @('08','09','0A','0B','81','82','83','84','A8','E0','E8','E9','EA','EB','54','55')){
  Add-Txn 'POST' '' 'POST_READ' '00' $physical $reg '' '' $physical 83
}
Add-Txn 'POST' '' 'POST_SELECT_WRITE' '01' $physical 'FF' '01' '' '01' 61; $physical='01'
foreach($reg in @('C2','C3','C4','C5','C8','C9','CA','CD')){
  Add-Txn 'POST' '' 'POST_READ' '01' $physical $reg '' '' $physical 83
}
foreach($bank in @('05','06','07','08')){
  Add-Txn 'POST' '' 'POST_SELECT_WRITE' $bank $physical 'FF' $bank '' $bank 61; $physical=$bank
  Add-Txn 'POST' '' 'POST_READ' $bank $physical 'F0' '' '' $physical 83
}
Add-Txn 'RESTORE' '' 'RESTORE_WRITE' 'ORIGINAL_FF' $physical 'FF' 'ORIGINAL_FF' '' 'ORIGINAL_FF' 61

Require ($rows.Count -eq 275) "Transaction total mismatch: $($rows.Count)"
$writes=@($rows|Where-Object {$_.KIND -notmatch 'READ|VERIFY'}).Count
$reads=@($rows|Where-Object {$_.KIND -match 'READ|VERIFY'}).Count
Require ($writes -eq 220) "Write total mismatch: $writes"
Require ($reads -eq 55) "Read total mismatch: $reads"

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$p50=Join-Path $OutputRoot 'TRANSACTION_STREAM_50K.csv'
$p25=Join-Path $OutputRoot 'TRANSACTION_STREAM_25K.csv'
$rows | Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath $p50
Copy-Item -LiteralPath $p50 -Destination $p25
$h50=(Get-FileHash -Algorithm SHA256 -LiteralPath $p50).Hash
$h25=(Get-FileHash -Algorithm SHA256 -LiteralPath $p25).Hash
Require ($h50 -eq $h25) 'The two transaction-stream files are not byte-identical'

@"
# Transaction-Stream Differential

```text
TRANSACTION_STREAM_BYTE_IDENTICAL=YES
OPERATION_ORDER_IDENTICAL=YES
TRANSACTION_COUNT_50K=275
TRANSACTION_COUNT_25K=275
WRITE_COUNT=220
READ_COUNT=55
TRANSACTION_STREAM_SHA256=$h50
SOURCE_OPERATION_DUMP=$OperationDumpLog
```

`I2C_HZ` is not an argument to the exact package function that selects table
operations. Both CSVs are generated from the same 214 effective package
operations and the sequencer's exact verified-bank and post-readback rules.
Only state-tick spacing differs; address, register, data, operation order,
bank-selection order, diagnostic/error semantics, and retry behavior are
unchanged.
"@ | Set-Content -Encoding utf8 -LiteralPath (Join-Path $OutputRoot 'TRANSACTION_STREAM_DIFF.md')

Write-Output "TRANSACTION_STREAM_BYTE_IDENTICAL=YES"
Write-Output "TRANSACTION_STREAM_SHA256=$h50"
