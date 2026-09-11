# No Capture Ack Semantics

Session 2 used firmware response `(2 << 16) | 0x9 = 0x00020009` only after proving no AIO, no stream enable, pending AIO zero, and physical quiescence. Host result remained `NOT_RUN`; it was not a capture pass.
