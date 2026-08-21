@echo off
setlocal EnableExtensions

set "TASK=C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1"
set "REPO=%TASK%\worktree"
set "UNUSED_BUILD=%TASK%\04_BUILD\PROVENANCE_UNUSED_BUILD_ROOT"
set "EVIDENCE=%TASK%\04_BUILD\PROVENANCE_PREFLIGHT"
set "COMMIT=f007dc172d43d30b02729755e60382f8ce3dbff4"
set "BIT=ahd_capture_v41_i2c_25khz_r1.bit"
set "SETTINGS=C:\AMDDesignTools\2025.2\Vivado\settings64.bat"
set "VIVADO=C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat"

if exist "%UNUSED_BUILD%" exit /b 81
if exist "%EVIDENCE%" exit /b 82
if not exist "%SETTINGS%" exit /b 83
if not exist "%VIVADO%" exit /b 84

mkdir "%EVIDENCE%"
if errorlevel 1 exit /b 85

call "%SETTINGS%"
if errorlevel 1 exit /b 86

call "%VIVADO%" -mode batch ^
  -source "%REPO%\scripts\v41\phase3_build.tcl" ^
  -log "%EVIDENCE%\PROVENANCE_PREFLIGHT.log" ^
  -journal "%EVIDENCE%\PROVENANCE_PREFLIGHT.jou" ^
  -notrace ^
  -tclargs "%REPO%" "%UNUSED_BUILD%" "%EVIDENCE%" "%COMMIT%" "%BIT%" PROVENANCE_ONLY
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" exit /b %RC%

if exist "%UNUSED_BUILD%" exit /b 87
findstr /c:"PHASE3_PROVENANCE_PREFLIGHT=PASS" "%EVIDENCE%\PROVENANCE_PREFLIGHT.log" >nul
if errorlevel 1 exit /b 88
findstr /c:"PROVENANCE_ROUND_TRIP=PASS" "%EVIDENCE%\EXPECTED_RUNTIME_PROVENANCE.txt" >nul
if errorlevel 1 exit /b 89

echo PROVENANCE_PREFLIGHT_WRAPPER=PASS
exit /b 0
