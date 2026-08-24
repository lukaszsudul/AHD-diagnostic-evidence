# R1h planned production source order

STATUS: `STATIC_LIST_NOT_QUERIED_FROM_VIVADO`

The build Tcl adds all SystemVerilog files in this order; Vivado's queried synthesis compile order is captured and checked during the sole build.

```text
000 rtl/v41/axi_lite_host_bridge.sv
001 rtl/v41/axi_clock_lifecycle_monitor.sv
002 rtl/v41/axi_clock_measurement_regs.sv
003 rtl/v41/r1e_measurement_regs.sv
004 rtl/v41/nvp_i2c_address_probe.sv
005 rtl/v41/r1h_probe_index_bram_store.sv
006 rtl/v41/nvp_i2c_tri_phase_probe.sv
007 rtl/v41/r1f_failed_txn_logger.sv
008 rtl/v41/r1f_measurement_regs.sv
009 rtl/v41/r1h_mmio_read_service.sv
010 rtl/v41/control_status_regs.sv
011 rtl/pio/pio_slot_adapter.sv
012 rtl/pio/pio_bar_target.sv
013 rtl/record/bt656_record_producer.sv
014 rtl/record/capture_mailbox.sv
015 rtl/video/video_capture.sv
016 rtl/video/physical_frontend.sv
017 rtl/top/ahd_capture_top_xdma.sv
```

VHDL analysis order is unchanged from frozen R1g:

```text
000 rtl/nvp/nvp6134c_diagnostics_pkg.vhd
001 rtl/nvp/r1f_transaction_serial_counter.vhd
002 rtl/nvp/nvp6134c_i2c_bringup.vhd
003 rtl/nvp/nvp6134c_autoinit.vhd
```

The two new modules precede their consumers: the index BRAM wrapper precedes the tri-phase probe, and the MMIO read service precedes the top. The runtime queried-order gate additionally requires all R1h dependencies before `ahd_capture_top_xdma.sv` and explicitly checks the index wrapper before the probe.

The XCI and XDC lists, hashes and processing-order policy remain exact frozen R1g.
