# R1f independent map and write-forwarding audit

## Exact source binding

~~~text
TOP_SHA256=
    CD8E2BB50D89273857168722EDA06F83AE08FA059FCA266522E6D2E3CD2CB77F
CONTROL_STATUS_REGS_SHA256=
    BE70C2707EDAFE075008F9592E474AF1E1658D75A75D5053A1F2FFBD072E44B5
R1F_MEASUREMENT_REGS_SHA256=
    BB77188A3A28F34DB3BBC195129A58620D11ECFE4F617528D68002DC1F1FDBFF
R1E_MEASUREMENT_REGS_SHA256=
    034F8C63258CA6436817CFFE1605CDF23EF04030047CCE36146E115F3C374939
~~~

## Read and write selection

Static inspection proves that local R1e and R1f selections are read-qualified.
R1e occupies 0x2000..0x209F and R1f occupies 0x20A0..0x35FF. A host write in
either range does not assert a local read select and is forwarded unchanged
through app_req_write/address/data/byte-enable into the exact inherited PIO
target. Consequently no R1f field can be written, while the pre-existing bad-
MMIO accounting remains observable exactly as before.

The R1f measurement module has no write input. It returns zero for every
unaligned or unlisted read, maps all 64 records as six 32-bit words, and maps
all three 512-entry 16-bit index windows without crossing their frozen ranges.

~~~text
R1F_READ_OVERLAY=PASS
R1F_LOCAL_WRITE_SELECT=NO
R1F_FIELD_MUTATION_FROM_WRITE=NONE
PRIOR_INVALID_WRITE_ACCOUNTING=PRESERVED_BY_FORWARDING
UNALIGNED_AND_UNLISTED_READS=ZERO
~~~

## Packed-status wiring

The final top wiring matches the normative R1f map:

- started uses the sticky guard-complete/setup-entry event;
- setup-status bus-idle-qualified uses the sticky initial qualification;
- detail word 0x23AC distinguishes current original-master releases/current
  raw pins from the sticky initial qualification;
- timeout total is consistently the low-level setup/probe/restoration
  transaction-timeout total, while high-level final-idle failure is carried by
  the abort code;
- post-probe validation/restoration/final-idle failure fields use the same
  scope in RTL and documentation;
- every bank/data field remains validity-gated.

The compatibility page at 0x2000..0x2094 preserves addresses and decode, not
dynamic identity with the old address-only engine. It is explicitly documented
as WADDR counters plus full-tri-lifecycle status. Scientific R1f analysis uses
the versioned R1f page.

## Evidence

~~~text
MAP_XSIM_SHA256=
    02D4A9605063D83883930E1E73793740111EF8FDE5E8F203379120845B7A03F9
MAP_XSIM_RESULT=PASS_ALL_DEFINED_RANGES_AND_1368_FORMAL_ZERO_DWORDS
TOP_XELAB_SHA256=
    9E88A0277C3F550AFA317BEF23D805508766C2EFF370C84BD8CE47D08933C893
TOP_ELABORATION=PASS_CURRENT_SHA
FORMAL_PHASE2_R1F_RANGE_ZERO=PASS_EXACT_SOURCE_DECODE_PROOF
~~~

The map fixture exercises the decoder with prepacked values; top packing is a
static wiring conclusion supplemented by focused source-module tests and final
top elaboration. No prompt-required dynamic map case is missing.

~~~text
R1F_INDEPENDENT_MAP_AND_WRITE_FORWARDING_AUDIT=PASS
MAP_OR_WRITE_SEMANTICS_BLOCKER=NONE
~~~
