# R1f standalone architecture-component tests

## Scope and result

This evidence covers only the standalone R1f failed-transaction logger and
read-only measurement-map decoder. It does not claim top-level integration,
pre-init functional equivalence, synthesis, implementation, bitstream
generation, or hardware qualification.

```text
R1F_FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD=PASS
R1F_LOG_64_EXACT_OVERFLOW_65=PASS
R1F_LOG_UNUSED_ZERO_IMMUTABLE=PASS

R1F_REGISTER_MAP_DECODE=PASS
R1F_RECORD_RANGE_LAST_WORD_0X29FC=PASS
R1F_INDEX_LOG_512_PER_PHASE=PASS
FORMAL_R1F_RANGE_ZERO_FIXTURE=PASS_ALL_1368_DWORDS
```

## Tool identity

```text
TOOL=AMD Vivado Simulator
VERSION=2025.2
SW_BUILD=6299465
IP_BUILD=6300035
SHARED_DATA_BUILD=6298862
```

The focused tests were compiled, elaborated, and run with the Vivado 2025.2
`xvlog`, `xelab`, and `xsim` executables. The final clean logger evidence is
under `architecture_components/logger_clean/`; the current register-map
evidence is under `architecture_components/map_final/`.

Representative command forms were:

```text
xvlog --sv <module.sv> <testbench.sv>
xelab <testbench-top> -s <snapshot>
xsim <snapshot> -runall
```

The preserved raw logs contain the exact absolute input paths, snapshot names,
tool/build identity, timestamps, and PASS markers.

## Implemented interfaces

### `v41_r1f_failed_txn_logger`

Producer interface:

```text
r1f_failed_txn_valid                 one-cycle finalized-record pulse
r1f_failed_txn_record[191:0]         complete record-v1 payload
```

Narrow read interface:

```text
record_read_index[5:0]               entry 0..63
record_read_word[2:0]                word 0..5
record_read_data[31:0]               little-word-order read result
```

Status outputs expose total/stored counts, overflow, first/last failed
transaction index with validity, total-count saturation, and malformed-input
protocol error. Payload storage is not flattened. A reset validity bitmap
masks every unused entry to deterministic zero while retaining inference of the
192-bit x 64 storage array.

The focused scoreboard proves:

- chronological append at entries 0..63;
- immutability of previously stored entries;
- unused entries read zero;
- exactly 64 failures do not assert overflow;
- the 65th failure asserts overflow;
- the 65th failure increments total count and updates the last index but does
  not overwrite an entry;
- stored count remains exactly 64 after overflow;
- out-of-range record words 6 and 7 read zero;
- malformed records set the sticky protocol-error diagnostic.

### `v41_r1f_measurement_regs`

The module accepts a 14-bit byte offset and returns one 32-bit read word. Large
storage remains behind narrow read ports:

```text
probe_detail_read_word[6:0]          0x2200..0x23ff backing word
record_read_index[5:0]               0x2400..0x29ff record entry
record_read_word[2:0]                record word 0..5
probe_index_read_phase[1:0]          WADDR/REGADDR/DATA
probe_index_read_word[7:0]           two packed 16-bit indices per word
```

The test exhaustively checks the complete record window and all three 1024-byte
probe-index windows. In particular, record 63 word 5 maps to `0x29fc`; each
index range contains 256 DWORDs, hence 512 packed 16-bit indices.

The map is read-only by construction: it has no write input and no output that
mutates an R1f field. Top-level integration must intercept only aligned reads in
the R1f window. Writes must continue through the pre-existing path so the prior
invalid-write event counter and last-invalid-address accounting remain
unchanged. “Read-only” therefore means no R1f state mutation, not silent
suppression of existing invalid-write diagnostics.

### `v41_r1f_formal_zero_model`

This is a fixture-only model and must never be instantiated in the R1f image.
The exact formal Phase-2 design has `SLOT_COUNT=2`; R1f addresses use reserved
slot-2/slot-3 space and therefore reach the existing deterministic-zero read
branch. The test enumerates every aligned DWORD from `0x20a0` through `0x35fc`
inclusive (1368 DWORDs) and proves zero for each.

## Address/collision conclusion

```text
R1F_RECORD_WIDTH_BITS=192
R1F_RECORD_WORDS=6
R1F_REQUIRED_FIELDS_FIT=YES
R1F_USED_BITS=174
R1F_RESERVED_ZERO_BITS=18

R1F_RECORD_CAPACITY=64
R1F_RECORD_BASE=0x2400
R1F_RECORD_LAST_WORD=0x29FC

R1F_REGISTER_MAP_COLLISION=NONE_PROVEN
FORMAL_PHASE2_R1F_RANGE_READBACK=DETERMINISTIC_ZERO
R1F_WRITE_MUTATION=NONE
EXISTING_INVALID_WRITE_ACCOUNTING=PRESERVED_BY_FORWARDING_WRITES
```

The detailed field allocation, bank invariant definitions, map inventory, and
source-level collision/formal-zero proof are in the assigned
`04_R1F_RECORD_FORMAT` and `05_R1F_REGISTER_MAP` evidence directories.

## File identities

```text
EFAF862E4267A8AE9A042FFB6B5F074B217CD8D0AD2DD3E4E783BA6F6B7B6C71  rtl/v41/r1f_failed_txn_logger.sv
BB77188A3A28F34DB3BBC195129A58620D11ECFE4F617528D68002DC1F1FDBFF  rtl/v41/r1f_measurement_regs.sv
68CF158817FA45E732986CE5399F5D324289B579D1571B0E563F625E19201934  tests/v41/tb_r1f_failed_txn_logger.sv
79B9CFC834FE7D6910D48DD46EBA3AA881D071DC9777CE7579908E68A4B1E50E  tests/v41/tb_r1f_measurement_regs.sv

F3D4B598C019432FB58CC2574D529F1051888BE166A2C55DA0AE1C569052E5A6  04_R1F_RECORD_FORMAT/R1F_FAILED_TRANSACTION_RECORD_V1.md
0088A8F90ED88E53DFCD300494BE369258D6E1B8C5C90525D297FA0B72BD948F  04_R1F_RECORD_FORMAT/R1F_FAILED_TXN_RECORD_V1.csv
E3254621D904D7E52E702BE87AF2A691621661070F106758152F12CD9D6C1EE8  04_R1F_RECORD_FORMAT/R1F_LOG_AND_BANK_INVARIANT_SEMANTICS.md
B78F9BE11ABCD5294BEC204489769206BA449387BA251BDF6849D40644E68CB5  05_R1F_REGISTER_MAP/R1F_READ_ONLY_REGISTER_MAP.md
F49999F6E7254999F6CF7D62683DADF58FD3F52A038C058AFA1427A5C727ED91  05_R1F_REGISTER_MAP/R1F_REGISTER_MAP.csv
528DCB84DA6DFE353A0EC5810C573D2D73A44057F019B84317FAF74C4A817DB1  05_R1F_REGISTER_MAP/ADDRESS_COLLISION_AND_FORMAL_ZERO_PROOF.md

B5C2DEF3A0B43B4929F06E012250FE9D8EE7048C89FC1715F8FC657B8C75CA59  architecture_components/map_final/xvlog.log
11B5ACE9D2C80187886B9974F1365002D9E3AB855B185E5CB7345593BE128AEB  architecture_components/map_final/xelab.log
02D4A9605063D83883930E1E73793740111EF8FDE5E8F203379120845B7A03F9  architecture_components/map_final/xsim.log
```

## Audit trail note

The first logger compile exposed only a testbench expression-form warning from
slicing a function-call result directly. The RTL already passed. The testbench
was mechanically changed to compare through an intermediate expected-record
variable, and the final `logger_clean` compile/elaboration/run is warning-free.
Both raw runs remain preserved; no RTL behavior changed between them.

```text
FULL_BUILD_PERFORMED_BY_THIS_SUBTASK=NO
SOURCE_INTEGRATION_PERFORMED_BY_THIS_SUBTASK=NO
FPGA_PROGRAM_PERFORMED_BY_THIS_SUBTASK=NO
JTAG_OR_SSH_PERFORMED_BY_THIS_SUBTASK=NO
```
