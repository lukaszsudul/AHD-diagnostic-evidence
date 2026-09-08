# Rolling 4-KiB receive-window design

The receive engine uses 2532 permanent logical 4096-byte regions: primary
indices `0..2499` and shutdown-guard indices `2500..2531`. It initially submits
exactly 1024 IOCBs and refills descriptor capacity after each completion batch,
never permitting more than 1024 outstanding requests. The AIO context capacity
is 1152 and the completion batch limit is 128.

Primary data placement is by permanent logical index, never completion order.
`PRIMARY_WINDOW_COMPLETE` is emitted as soon as all 2500 primary requests have
completed exactly. The parent disables the stream from that metadata event;
primary persistence proceeds independently. After five-sample physical
quiescence, cancellation is limited to pending guard IOCBs on the successful
path.

The guard is shutdown-tail evidence and is excluded from the primary count,
primary sequence requirement, and complete-frame qualification.
