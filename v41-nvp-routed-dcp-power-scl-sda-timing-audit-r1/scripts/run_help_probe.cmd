@echo off
setlocal
call "C:\AMDDesignTools\2025.2\Vivado\settings64.bat"
if errorlevel 1 exit /b %errorlevel%
call "C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -source "C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1\scripts\probe_help_api.tcl" -nojournal -nolog
exit /b %errorlevel%
