# Baseline and rollback contract

- Touched functional registers in the complete reference NOVID slice branch: `2`
- Authorized touched functional registers: `1`
- Unauthorized inseparable touched functional registers: `1` (`Bank5/0x05`)
- All touched functional registers readable: `NO — not proven under current authority`
- All touched functional registers restorable: `NO — not proven under current authority`
- Known write-only touched registers: `0`
- Known read-side-effect touched registers: `0`
- Symbolic unresolved rollback fields: `1` (`Bank5/0x05`)
- Runtime functional baseline acquired: `NO`
- Functional writes executed: `0`

The authorized `Bank5/0x08` baseline design cannot make the complete reference action safe because the same branch necessarily writes `Bank5/0x05=0xA4`, for which write authorization and complete runtime-derived rollback authority are absent. The contract therefore stops before source implementation and hardware access with `ACQ1_COMPAT0_SLICE_ACTION_EXCEEDS_AUTHORIZED_WRITE_SET`.
