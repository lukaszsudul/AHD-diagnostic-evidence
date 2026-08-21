@echo off
setlocal
set "VIVADO_BAT=C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat"
set "SCRIPT=C:\FPGA\V41_RCA_PHASE2_POWER_BREAKDOWN_NO_BUILD_R1\scripts\capture_vivado_2025_2_help.tcl"
set "OUTPUT=C:\FPGA\V41_RCA_PHASE2_POWER_BREAKDOWN_NO_BUILD_R1\02_VIVADO_HELP"
call "%VIVADO_BAT%" -mode batch -nolog -nojournal -notrace -source "%SCRIPT%" -tclargs "%OUTPUT%"
exit /b %ERRORLEVEL%
