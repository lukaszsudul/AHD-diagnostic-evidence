# Transaction-Stream Differential

```text
TRANSACTION_STREAM_BYTE_IDENTICAL=YES
OPERATION_ORDER_IDENTICAL=YES
TRANSACTION_COUNT_50K=275
TRANSACTION_COUNT_25K=275
WRITE_COUNT=220
READ_COUNT=55
TRANSACTION_STREAM_SHA256=B49B240205FE523E30C04875A0565E28FFF7C7133AD4E6F18B3104539FB3A571
SOURCE_OPERATION_DUMP=C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\03_SIMULATION\OP_DUMP\simulation.log
```

I2C_HZ is not an argument to the exact package function that selects table
operations. Both CSVs are generated from the same 214 effective package
operations and the sequencer's exact verified-bank and post-readback rules.
Only state-tick spacing differs; address, register, data, operation order,
bank-selection order, diagnostic/error semantics, and retry behavior are
unchanged.
