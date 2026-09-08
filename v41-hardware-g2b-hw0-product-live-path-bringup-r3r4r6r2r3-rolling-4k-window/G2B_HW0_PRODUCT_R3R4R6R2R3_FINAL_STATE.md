# Final state

CONTROL was last observed as zero, but physical DMA quiescence was not proven:
STATUS remained `0x000004FA` for all bounded samples. The
task-owned helper remains active, the exact XDMA module remains loaded, expected
nodes remain present, and both fresh locks remain held. Private primary data is
preserved. No automatic recovery action was authorized or taken.
