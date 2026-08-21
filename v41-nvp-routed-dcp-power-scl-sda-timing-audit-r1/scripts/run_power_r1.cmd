@echo off
setlocal
call "C:\AMDDesignTools\2025.2\Vivado\settings64.bat"
if errorlevel 1 exit /b %errorlevel%
call "C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -nojournal -log "C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1\raw\R1_POWER_AUDIT_VIVADO.log" -source "C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1\scripts\audit_power.tcl" -tclargs "C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1\01_INPUT_IDENTITY\R1_PACKAGE_EXTRACTED\PHASE3_routed.dcp" "C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1\04_R1_POWER" "R1"
exit /b %errorlevel%
