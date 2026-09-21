# AHD v41 CH3 R2R10R1 — APPLY18 context review

## Scope

Offline-only six-point review of the retained R2R10 APPLY_A failure. No DUT access, live read, driver operation, reset, programming, FPGA build, PREPARE, APPLY, DMA or capture was performed.

`OWNER_EXCLUSIVITY_AND_CONTINUITY=ATTESTED`

`DUT_LIVE_SURVEY=NOT_RUN_OFFLINE_SCOPE`

The Owner attestation supports continuity from the last R2R10 measurement. It is not a current hardware measurement.

## Result

`PASS_OFFLINE_REVIEW_CONTEXT_NOT_RETAINED_ROOT_CAUSE_NOT_PROVEN`

| Review point | Result |
|---|---|
| Retained runtime/source chain | `CONFIRMED` |
| Host decoder | `PASS_14_OF_14`; historical R2R10 APPLY remains FAIL |
| Retained terminal | `0x12`, `I2C_TRANSPORT`, cause 2, `I2C_REGADDR_NACK` |
| Failed command context | `NOT_RETAINED` |
| W2 cross-reference | `NOT_EVALUABLE_NO_CONTEXT` |
| Released I2C master path | `PASS_STATIC_CODE_REVIEW` |
| Physical root cause | `NOT_PROVEN` |
| Return from `CAMP_RECOVERED` | `PLAN_ONLY_NOT_AUTHORIZED_FOR_EXECUTION` |

The retained status does not expose the loader PC, failed bank/register, direction or I2C transaction ID. Host operation 67 is the single MMIO APPLY command and cannot be mapped to one internal I2C operation. The measured end latency cannot locate the failure because automatic recovery is included.

The planned first APPLY operation in the released source is separate from the unknown failed operation. Detailed profile and microcode material remains private.

W2 covered a different scoped mode/channel. Without the exact failed-operation key, no intersection or causal claim can be made.

The released RTL contains SCL-high waiting and filtered ACK sampling. The current master differs from the historical 214-case input only by retained observability logic, with no sampling, FSM or parameter change. The finite digital grid does not prove analog rise time, device maximum clock stretch or every integration timing case. Terminal 18 is not the loader SCL-timeout code.

From `CAMP_RECOVERED=5`, PREPARE, APPLY_A, APPLY_B and host RECOVER are not legal in the released FSM. A return procedure was documented locally as a plan only and was not executed.

## Identity

- FPGA source commit: `b2f80cf4fda1775ab34804a246cb7be61e0ecd62`
- FPGA source tree: `fd19d5e27923f69d16d2d8679db85d7813124c37`
- Bitstream: `2192144` bytes, SHA-256 `34DFC48E9CCEDD9E4F608624EE51D1D79767E8E74035393576B69C21C07E8CB8`
- DCP provenance SHA-256: `F589B7C6151EC2EAB576B358837D0A331B02D69A11DF30F5BCF5910416EEBA64`
- Released microcode input SHA-256: `1A5E332E0C3C6E9C470AAAFD507B16E908B62A404CC3A58FA79CA5B93A6FB570`
- Released fixed master SHA-256: `EBDF32ED64E0682F25F4FA4398C870BC87FE9644AB7C22CE6692F09EA201381E`
- Private NVP reference identity SHA-256: `6D381DD8FCB6E844368F46EF48E9F6CC95895156B33EB1897CDC2E5523A733B5`
- Host decoder change: private branch, 2 files, 157 insertions, firmware identity unchanged

## Minimum missing observation

A sticky first-failure receipt captured before automatic recovery: loader PC, resolved bank/register/direction and raw master cause. If a transaction ID is included, its origin, owner and increment semantics must also be defined.

## Next action

Seek separate authorization for the existing bounded R2R9 recovery procedure through fresh `CAMP_VIRGIN` admission. Do not include PREPARE or another APPLY in the recovery authorization.

Historical R2R10 evidence remains append-only and its FAIL result is unchanged. This review makes no product, capture or physical-root-cause claim.
