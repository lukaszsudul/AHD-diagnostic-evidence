
# Host/DMA Accounting

- Classification: `FAIL`
- Primary positive completion: `643072` bytes
- Guard positive completion: `N/A` (no completion event)
- Host returned bytes observed: `643072`
- Host complete-record bytes observed: `643072`
- Host partial bytes observed: `0`
- Host returned beats observed: `80384`
- FPGA streamed beats: `83456`
- FPGA streamed bytes: `667648`
- Unreaped or unavailable shutdown bytes relative to observed completions: `24576`
- Unreaped or unavailable shutdown beats: `3072`

Equation: `667648 = 643072 + 24576`.
This is not the permitted bounded guard-timeout result because the primary
request itself was incomplete and the guard supplied no completion result.
