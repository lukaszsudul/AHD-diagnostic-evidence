
# VDO timing disposition

- `VDO_TIMING_MODEL=EMPIRICALLY_QUALIFIED_SOURCE_SYNCHRONOUS`
- `set_input_delay -max 6.313 ns`
- `set_input_delay -min 2.104 ns`
- interface unconstrained: `NO`
- timing reopened: `NO`
- XDC changed: `NO`
- IDELAY, clock phase, and NVP clock-delay selector changed: `NO`

The accepted routed timing model and deterministic, structurally identical
`+21` events at consecutive frame boundaries do not currently support H5.
Timing remains a later fallback only if a raw-marker trace shows inconsistent
sampling after protocol/mode hypotheses are resolved.

`H5_TIMING_PHASE=NOT_SUPPORTED`
