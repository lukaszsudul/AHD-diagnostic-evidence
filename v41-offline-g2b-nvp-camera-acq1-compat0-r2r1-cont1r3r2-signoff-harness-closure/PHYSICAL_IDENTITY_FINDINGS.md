# Physical/configuration identity on two as-open DCPs

Two fresh Vivado 2025.2 build 6299465 sessions opened immutable DCP copies,
without `reset_timing`, `read_xdc`, source constraints, implementation or
checkpoint writing. The candidate copy SHA-256 was
`C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2`;
the earlier routed reference copy SHA-256 was
`804CB25D89DF3729A65D2771B892738AC2D580E2921AF48CAE1C5C28D76BC208`.

The as-open clock signature was
`115E8E2C23866C2330514771F9E55C8FD7D067324484ECCBE7A9238D9083DE08`,
the cell/net/LOC/BEL netlist signature was
`AB68085CE12A2292EE3CB43ABC4D89079A90826125638AD05D2B1985C6ADE5E5`,
and route-status signature was
`14ED8C5F584FED4392894F46935B8FBC9309E05F15D58884F984A19A255F6C04`
for both. Each was fully routed, 38,667/38,667 routable nets.

The full read-only per-net route-property export contains 119,180 ordered
hierarchical net records (all with nonempty route property), exactly
3,555,828,099 bytes in each private file. Both complete files have SHA-256
`02B912E829DFA2502D99F650E7533AD0A2EE543B20B0CA373DA99F8E0CB7FBFD`.
This directly verifies the route-property sequence rather than inferring
route equality from a routed-net count. These large raw files remain private
and are not published.

The complete raw physical+timing XDC exports are not byte-identical; their
constraint-file comment provenance and timing-command block layout differ
after the historical in-memory replay. They are not sorted or treated as
interchangeable raw files. Targeted inspection found 49 `set_property`
commands per file, identical with active `current_instance` scope and in
the same order; eight `create_waiver` commands are likewise identical with
scope and order. The separately exported as-open timing XDC is B on both
DCPs, with all 97 ordered executable commands identical after generated
selector-alias expansion. No changed package pin, LOC, I/O property or
waiver was found in these audited exports.

The raw physical+timing XDC files include vendor IP comments and are kept
private. Only this summary, hashes and the project-owned collector are
eligible for publication.
