@echo off
setlocal EnableExtensions

set "TASK=C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1"
set "DCP=%TASK%\04_BUILD\FULL_BUILD_EVIDENCE\PHASE3_routed.dcp"
set "GATE=%TASK%\04_BUILD\FULL_BUILD_EVIDENCE\I25_POST_BUILD_GATE_RESULT.txt"
set "OUT=%TASK%\04_BUILD\ROUTED_DCP_REPORT_ONLY"
set "SCRIPT=%TASK%\scripts\run_routed_dcp_report_only_after_pass.tcl"
set "SETTINGS=C:\AMDDesignTools\2025.2\Vivado\settings64.bat"
set "VIVADO=C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat"

if not exist "%DCP%" exit /b 91
if not exist "%GATE%" exit /b 92
findstr /x /c:"POST_BUILD_GATE=PASS" "%GATE%" >nul
if errorlevel 1 exit /b 93
findstr /x /c:"SOURCE_HEAD=f007dc172d43d30b02729755e60382f8ce3dbff4" "%GATE%" >nul
if errorlevel 1 exit /b 94
if exist "%OUT%" exit /b 95
if not exist "%SCRIPT%" exit /b 96
if not exist "%SETTINGS%" exit /b 97
if not exist "%VIVADO%" exit /b 98

mkdir "%OUT%"
if errorlevel 1 exit /b 99

call "%SETTINGS%"
if errorlevel 1 exit /b 100

call "%VIVADO%" -mode batch ^
  -source "%SCRIPT%" ^
  -log "%OUT%\REPORT_ONLY.log" ^
  -journal "%OUT%\REPORT_ONLY.jou" ^
  -notrace ^
  -tclargs "%DCP%" "%OUT%" "%GATE%"
set "RC=%ERRORLEVEL%"
exit /b %RC%
