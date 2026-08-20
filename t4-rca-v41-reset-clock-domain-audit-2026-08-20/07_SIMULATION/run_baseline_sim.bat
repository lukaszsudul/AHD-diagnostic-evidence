@echo off
setlocal
set SRC=C:\FPGA\T4_RCA_V41_RESET_CLOCK_AUDIT_20260820\01_SOURCE_EXPORTS\RCA_SOURCE
set OUT=C:\Users\%USERNAME%\Documents\ChatGPT\AHD_20260807\T4_RCA_V41_RESET_CLOCK_AUDIT_20260820\07_SIMULATION\baseline
if not exist "%OUT%" mkdir "%OUT%"
cd /d "%OUT%"
call C:\AMDDesignTools\2025.2\Vivado\bin\xvhdl.bat --2008 "%SRC%\rtl\nvp\nvp6134c_diagnostics_pkg.vhd" "%SRC%\rtl\nvp\nvp6134c_i2c_bringup.vhd" "%SRC%\tests\nvp\tb_nvp_autoinit.vhd" > compile.log 2>&1 || exit /b 1
call C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat tb_g0p8c5d_autoinit -s t4_baseline > elaborate.log 2>&1 || exit /b 1
call C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat t4_baseline -runall > simulation.log 2>&1 || exit /b 1
endlocal
