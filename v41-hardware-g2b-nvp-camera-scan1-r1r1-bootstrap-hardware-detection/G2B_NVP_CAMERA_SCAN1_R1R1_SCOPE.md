
# Scope

This was a bounded read-only NVP6134C scanner qualification and physical OFF/ON/OFF campaign. The scanner used the frozen 82-entry, 10-group, 105-transaction manifest at 25 kHz. The only host MMIO writes during a scan were `ONESHOT` and `ACK/CLEAR`; the compiled scanner's only NVP write was the permitted bank selector.

No PRODUCT source, RTL, active XDC, SSOT, META state, NVP functional configuration, route, BGDCOL, `set_chnmode`, EQ, slice setting, Flash, DCP, bitstream, or reference driver source was changed. ACQ1 was not executed. Camera frames and pixels are excluded from this publication.
