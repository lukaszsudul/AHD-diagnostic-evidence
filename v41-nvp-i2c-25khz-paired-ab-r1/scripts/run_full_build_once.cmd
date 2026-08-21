@echo off
setlocal EnableExtensions

set "TASK=C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1"
set "REPO=%TASK%\worktree"
set "BUILD=%TASK%\04_BUILD\FULL_BUILD_ROOT"
set "EVIDENCE=%TASK%\04_BUILD\FULL_BUILD_EVIDENCE"
set "COMMIT=f007dc172d43d30b02729755e60382f8ce3dbff4"
set "BIT=ahd_capture_v41_i2c_25khz_r1.bit"
set "SETTINGS=C:\AMDDesignTools\2025.2\Vivado\settings64.bat"
set "VIVADO=C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat"
set "LOG=%TASK%\04_BUILD\FULL_BUILD_LAUNCH.log"
set "JOU=%TASK%\04_BUILD\FULL_BUILD_LAUNCH.jou"

if exist "%BUILD%" exit /b 81
if exist "%EVIDENCE%" exit /b 82
if exist "%LOG%" exit /b 83
if exist "%JOU%" exit /b 84
if not exist "%SETTINGS%" exit /b 85
if not exist "%VIVADO%" exit /b 86

call "%SETTINGS%"
if errorlevel 1 exit /b 87

echo FULL_BUILD_INVOCATION_CONSUMED=YES
echo FULL_BUILD_SOURCE_COMMIT=%COMMIT%
echo FULL_BUILD_START_UTC=%DATE%_%TIME%

call "%VIVADO%" -mode batch ^
  -source "%REPO%\scripts\v41\phase3_build.tcl" ^
  -log "%LOG%" ^
  -journal "%JOU%" ^
  -notrace ^
  -tclargs "%REPO%" "%BUILD%" "%EVIDENCE%" "%COMMIT%" "%BIT%"
set "RC=%ERRORLEVEL%"
echo FULL_BUILD_VIVADO_EXIT_CODE=%RC%
exit /b %RC%
