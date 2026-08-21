@echo off
setlocal EnableExtensions

set "TASK=C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1"
set "SRC=%TASK%\worktree"
set "SIM=%TASK%\03_SIMULATION"
set "BIN=C:\AMDDesignTools\2025.2\Vivado\bin"

if not exist "%BIN%\xvhdl.bat" exit /b 80
if not exist "%BIN%\xelab.bat" exit /b 81
if not exist "%BIN%\xsim.bat" exit /b 82

call :run_regression 50KHZ_REGRESSION "%SRC%\tests\nvp\tb_nvp_autoinit.vhd" i25_reg50
if errorlevel 1 exit /b %errorlevel%

call :run_regression 25KHZ_REGRESSION "%TASK%\scripts\tb_nvp_autoinit_25khz.vhd" i25_reg25
if errorlevel 1 exit /b %errorlevel%

set "OUT=%SIM%\OP_DUMP"
if not exist "%OUT%" mkdir "%OUT%"
pushd "%OUT%"
call "%BIN%\xvhdl.bat" --2008 "%SRC%\rtl\nvp\nvp6134c_diagnostics_pkg.vhd" "%TASK%\scripts\tb_dump_effective_ops.vhd" > compile.log 2>&1
if errorlevel 1 (popd & exit /b 90)
call "%BIN%\xelab.bat" tb_i25_dump_effective_ops -s i25_op_dump > elaborate.log 2>&1
if errorlevel 1 (popd & exit /b 91)
call "%BIN%\xsim.bat" i25_op_dump -runall > simulation.log 2>&1
if errorlevel 1 (popd & exit /b 92)
findstr /c:"PASS_I25_EFFECTIVE_OPERATION_DUMP" simulation.log >nul
if errorlevel 1 (popd & exit /b 93)
popd

echo SIMULATION_GROUP=PASS
exit /b 0

:run_regression
set "LABEL=%~1"
set "TB=%~2"
set "SNAP=%~3"
set "OUT=%SIM%\%LABEL%"
if not exist "%OUT%" mkdir "%OUT%"
pushd "%OUT%"
call "%BIN%\xvhdl.bat" --2008 "%SRC%\rtl\nvp\nvp6134c_diagnostics_pkg.vhd" "%SRC%\rtl\nvp\nvp6134c_i2c_bringup.vhd" "%TB%" > compile.log 2>&1
if errorlevel 1 (popd & exit /b 100)
call "%BIN%\xelab.bat" tb_g0p8c5d_autoinit -s %SNAP% > elaborate.log 2>&1
if errorlevel 1 (popd & exit /b 101)
call "%BIN%\xsim.bat" %SNAP% -runall > simulation.log 2>&1
if errorlevel 1 (popd & exit /b 102)
findstr /c:"PASS_STAGE6_G0P8C5D_AUTOINIT_SIMULATION" simulation.log >nul
if errorlevel 1 (popd & exit /b 103)
popd
exit /b 0
