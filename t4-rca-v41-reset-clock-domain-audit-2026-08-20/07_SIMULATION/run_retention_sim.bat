@echo off
setlocal
set OUT=C:\Users\%USERNAME%\Documents\ChatGPT\AHD_20260807\T4_RCA_V41_RESET_CLOCK_AUDIT_20260820\07_SIMULATION\retention
if not exist "%OUT%" mkdir "%OUT%"
cd /d "%OUT%"
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat -sv "C:\FPGA\T4_RCA_V41_RESET_CLOCK_AUDIT_20260820\07_SIMULATION\tb_clock_reset_retention.sv" > compile.log 2>&1 || exit /b 1
call C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat tb_clock_reset_retention -s t4_retention > elaborate.log 2>&1 || exit /b 1
call C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat t4_retention -runall > simulation.log 2>&1 || exit /b 1
endlocal
