# R1 measurement register map

Base: `0x02000`, length `0x40`, aligned read-only overlay.

Formal proof is supplied by `tb_end_to_end_tlp.sv` and `tb_slot_count.sv`, both
of which require `0x02000 == 0` with `SLOT_COUNT=2`. The preserved target maps
addresses below `0x10000` by `host_req_addr[15:12]`; index 2 is unavailable.
The existing local block remains `0x00000..0x000ff`, legacy registers remain
`0x10000..0x100ff`, slot/mirror behavior remains unchanged, and writes in the
new range continue down the original application path. Only aligned reads in
`0x02000..0x0203f` are intercepted.

Offsets: magic 00, version 04, status 08, freerun low/high 0c/10, init-done
14/18, first-link 1c/20, first-reset-high 24/28, first-reset-low 2c/30,
link/reset transition counts 34/38, event flags 3c.
