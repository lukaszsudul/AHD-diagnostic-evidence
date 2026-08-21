@echo off
setlocal
call "C:\AMDDesignTools\2025.2\Vivado\settings64.bat"
if errorlevel 1 exit /b %errorlevel%
call "C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -nojournal -log "C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1\raw\R1_DIRECT_NET_DELAY_PROBE_VIVADO.log" -source "C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1\scripts\probe_direct_net_delays.tcl" -tclargs "C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1\01_INPUT_IDENTITY\R1_PACKAGE_EXTRACTED\PHASE3_routed.dcp" "C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1\05_R1_SCL_SDA_TIMING\R1_DIRECT_NET_DELAY_PROBE.txt" "R1"
exit /b %errorlevel%
