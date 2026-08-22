# R1d probe runtime model

The final FSM uses 23 selected state ticks per completed address probe:

- BUS_FREE: 1
- START: 2
- eight address bits: 16
- ACK: 2
- STOP: 2

Each campaign has a two-tick stable-bus preamble.

- 50KHZ: 2.303700032 s, actual SCL 49920.1277955271565495207667732 Hz
- 25KHZ: 4.603720032 s, actual SCL 24980.0159872102318145483613110 Hz
