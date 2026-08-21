# Tool command ledger

All Vivado commands will be recorded after validation against Vivado 2025.2 command help. Design-changing and hardware-manager commands are prohibited.
## FINAL_REPORT_ADAPTATIONS

- The prompt's duplicated launcher path `C:\AMDDesignTools\2025.2\Vivado\2025.2\bin\vivado.bat` was absent. The verified supported AMD wrapper installed with Vivado 2025.2 was `C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat`, with `C:\AMDDesignTools\2025.2\Vivado\settings64.bat`.
- Vivado 2025.2 does not provide `report_delay_calculation`; captured help identified `get_net_delays` as the report-only physical-delay equivalent. `get_net_delays` supplied direct OEN-Q→OBUFT-T and IBUF-O→sync0-D delay evidence in picoseconds without altering timing exceptions or the checkpoint.
- The initial help-capture attempt used unavailable Tcl `redirect`; it failed before opening a checkpoint and was preserved under `raw\FAILED_HELP_CAPTURE_REDIRECT_UNAVAILABLE`. The corrected capture used documented `help -output`.
- The initial timing script failed on a typed-collection conversion before completing; partial output was quarantined under `raw\FAILED_R1_TIMING_TYPED_COLLECTION_1`. The corrected report-only script completed with an explicit success marker.
- Every Vivado invocation used batch mode, opened a routed checkpoint read-only, issued only queries/reports, and closed without saving.
