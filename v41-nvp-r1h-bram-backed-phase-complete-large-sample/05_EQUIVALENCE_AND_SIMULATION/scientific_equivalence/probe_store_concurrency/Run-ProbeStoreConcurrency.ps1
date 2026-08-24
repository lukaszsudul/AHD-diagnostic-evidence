$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$Root='C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\05_EQUIVALENCE_AND_SIMULATION\scientific_equivalence\probe_store_concurrency'
$SourceRoot='C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$Run=Join-Path $Root 'run_01';if(Test-Path $Run){throw 'sealed run exists'};[void](New-Item -ItemType Directory $Run)
$xvlog='C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat';$xelab='C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat';$xsim='C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat'
function Invoke-Captured([string]$Tool,[string[]]$Arguments,[string]$Stem){
  [IO.File]::WriteAllLines("$Stem.command.txt",@("TOOL=$Tool")+(0..($Arguments.Count-1)|%{"ARG_$_=$($Arguments[$_])"}),[Text.UTF8Encoding]::new($false))
  Push-Location $Run;try{$o=@(& $Tool @Arguments 2>&1);$c=$LASTEXITCODE}finally{Pop-Location}
  [IO.File]::WriteAllLines("$Stem.log",@($o|% ToString),[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText("$Stem.exit.txt","PROCESS_EXIT_CODE=$c`n",[Text.UTF8Encoding]::new($false));if($c){throw "failed $Tool"}
}
$rtl=Join-Path $SourceRoot 'rtl\v41\r1h_probe_index_bram_store.sv';$tb=Join-Path $Root 'tb_r1h_probe_store_concurrency.sv'
Invoke-Captured $xvlog @('--sv','--work','work',$rtl,$tb) (Join-Path $Run 'xvlog')
Invoke-Captured $xelab @('tb_r1h_probe_store_concurrency','-L','xpm','-debug','typical','-s','probe_store_concurrency_snapshot') (Join-Path $Run 'xelab')
[IO.File]::WriteAllLines((Join-Path $Run 'run.tcl'),@('run all','quit'),[Text.UTF8Encoding]::new($false));Invoke-Captured $xsim @('probe_store_concurrency_snapshot','-tclbatch',(Join-Path $Run 'run.tcl').Replace('\','/')) (Join-Path $Run 'xsim')
$l=Get-Content (Join-Path $Run 'xsim.log') -Raw;if(!$l.Contains('R1H_INDEX_STORE_BACK_TO_BACK_SAME_BANK_WRITES=PASS') -or !$l.Contains('R1H_INDEX_STORE_SAME_BANK_DIFFERENT_ADDRESS_CONCURRENT_RW=PASS') -or $l -match '(?im)^Error:|^Fatal:|\$fatal'){throw 'concurrency markers fail'}
[IO.File]::WriteAllLines((Join-Path $Run 'RESULT.txt'),@('RESULT=PASS','BACK_TO_BACK_SAME_BANK_WRITES=PASS','SAME_BANK_DIFFERENT_ADDRESS_CONCURRENT_RW=PASS',"RTL_SHA256=$((Get-FileHash $rtl -Algorithm SHA256).Hash)","TB_SHA256=$((Get-FileHash $tb -Algorithm SHA256).Hash)","XSIM_LOG_SHA256=$((Get-FileHash (Join-Path $Run 'xsim.log') -Algorithm SHA256).Hash)"),[Text.UTF8Encoding]::new($false));Get-Content (Join-Path $Run 'RESULT.txt')
