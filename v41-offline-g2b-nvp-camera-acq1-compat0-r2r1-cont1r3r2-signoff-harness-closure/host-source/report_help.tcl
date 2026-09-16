if {[version -short] ne {2025.2}} { error {WRONG_VIVADO_VERSION} }
foreach command {report_timing_summary report_exceptions report_clocks report_clock_networks report_cdc report_bus_skew} {
  puts "=== $command ==="
  puts [help $command]
}
exit 0
