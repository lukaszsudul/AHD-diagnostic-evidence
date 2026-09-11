
# Current R3 route sequence

require transport_quiescent -> write Bank0 0xFF=0x01 -> read Bank1 0xC2 -> write C2={old[7:4],0,channel-1} -> read C2 and require low nibble -> write Bank0 0xFF=0x00 -> wait >=200 ms -> five stable NVP status samples -> host RESET_STREAM_STATE after snapshot, if VCLK active -> host source readiness measurement.

`RESET_STREAM_STATE` is a later FPGA transport reset, not an NVP VDO1/formatter re-arm. The NVP route itself remains a C2 low-nibble read-modify-write followed by readback and settle/status sampling.
