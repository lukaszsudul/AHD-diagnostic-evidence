
# Cleanup Receipt

- Stream disabled: `YES` (authorized safety disable)
- Five-sample physical quiescence: `PASS`
- Quiescence span: `401.405` ms
- Native process: PID `25287`, still in kernel `read_events`
- Open task descriptor: `/dev/xdma0_c2h_0`
- Module refcount: `1`
- Native helper signal-interrupted or killed: `NO`
- Driver unload attempted: `NO`
- Driver unloaded: `NO`
- XDMA nodes removed: `NO`
- Linux task lock released: `NO`
- Controller task lock released: `NO`
- Secondary blocker: `R3R4R6R1_ROLLBACK_UNSAFE_ACTIVE_DMA:GUARD_AIO_STILL_PENDING`

Forced cancellation and forced unload were prohibited. The locks remain held
to protect the unresolved task-owned AIO request.
