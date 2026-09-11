# Root cause

The diagnostic responder asserted `mmio_rsp_valid` for writes although `v41_axi_lite_host_bridge` consumes downstream responses only for reads. A write therefore left a sticky response and blocked the next read. R3 made writes side-effect-only and reads the sole producer of downstream responses. The shared bridge was not changed.
