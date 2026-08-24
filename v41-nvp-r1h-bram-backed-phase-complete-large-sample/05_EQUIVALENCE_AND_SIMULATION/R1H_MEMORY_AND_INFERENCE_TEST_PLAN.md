# R1h — niezależny plan testów pamięci, latencji i inference

```text
TASK=V41_NVP_R1H_BRAM_BACKED_PHASE_COMPLETE_OBSERVABILITY_AND_LARGE_SAMPLE_AB
DOCUMENT_SCOPE=PRECOMMIT_AND_POSTSYNTH_TEST_PLAN
REFERENCE_SOURCE_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
REFERENCE_SOURCE_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
VIVADO_TARGET=2025.2_BUILD_6299465
PART=xc7a35tcsg325-2
PLAN_ONLY=YES
SOURCE_MUTATIONS_BY_THIS_AUDIT=0
SYNTHESIS_RUNS_BY_THIS_AUDIT=0
```

## 1. Existing R1g tests — exact audit

| Test | Existing coverage | R1h gap |
|---|---|---|
| `tests/v41/tb_r1f_failed_txn_logger.sv` | unused zero; records 0..63; overflow at 65; no overwrite; reset | assumes combinational `#1` read; does not test six-bank atomicity, XPM latency, simultaneous read/write or AXI-reset-only pipeline |
| `tests/v41/tb_nvp_i2c_tri_phase_probe.sv` | packed indices, unused zero, three phases, block counts, full scheduler | assumes combinational index/block read; small index capacity in non-production mode |
| `tests/v41/tb_nvp_i2c_tri_phase_probe_index_overflow.sv` | per-phase overflow and no data past capacity | capacity parameter 4, combinational reads; needs production-depth companion |
| `tests/v41/tb_r1f_measurement_regs.sv` | exact range endpoints, phase/index/record decode, 1368-DWORD formal-zero fixture | treats memory data as combinational; must become request/response transaction fixture |
| `tb/v41/tb_control_status_regs.sv` | local/forwarded behavior and response backpressure | no R1f port value in current named instantiation; no pending-before-response interval test |
| `tb/v41/tb_axi_lite_host_bridge.sv` | delayed response and AXI R-channel backpressure | retain unchanged; add end-to-end R1h service test above bridge |

Reference hashes:

```text
68CF158817FA45E732986CE5399F5D324289B579D1571B0E563F625E19201934 tb_r1f_failed_txn_logger.sv
71523794924E8AB03F2A6F02C2C7998791E14A474088F44850AC0286BD40A38D tb_nvp_i2c_tri_phase_probe.sv
2B62A9E6FAD827DAC5B13AE2CA3B850C9F7AC30D98FB6C906A87711B59261065 tb_nvp_i2c_tri_phase_probe_index_overflow.sv
79B9CFC834FE7D6910D48DD46EBA3AA881D071DC9777CE7579908E68A4B1E50E tb_r1f_measurement_regs.sv
8F0755B85A40732210EA28FEF0D3CA3BB2DE5FD0C560D68D932B87471A513A28 tb_control_status_regs.sv
6F2C02211BDEFCADDA33E94F0B70397D2186AAF3714E9F39070CFCCED090B138 tb_axi_lite_host_bridge.sv
```

## 2. Gate order

```text
G0 static source/parameter audit
 -> G1 XPM compile and RTL elaboration
 -> G2 record-store unit scoreboard
 -> G3 index-store unit scoreboards
 -> G4 block-statistics scoreboard
 -> G5 MMIO latency/backpressure protocol
 -> G6 R1g/R1h event and transaction equivalence
 -> G7 complete inherited R1g matrix and host/stat fixtures
 -> G8 bounded wrapper-only inference preflight
 -> source commit
 -> G9 exact full-build post-synthesis primitive/resource gate
```

Nie wolno zastąpić G9 wynikiem wrapper-only. OOC preflight wykrywa tylko błąd
modelu/inference przed zużyciem jedynego full build.

## 3. G0 — static contract audit

Maszynowo sprawdzić:

- dokładnie sześć record XPM `64x32`, trzy index XPM `512x16`;
- `MEMORY_PRIMITIVE="block"`, `READ_LATENCY_B=1`, `WRITE_MODE_B="read_first"`;
- brak pętli resetującej payload record/index/block RAM;
- brak nowej tablicy `logic [15:0] ... [0:511]` lub `logic [191:0] ...[0:63]`;
- capacities 64/192/6/512/10000/10/1000/12000 unchanged;
- adresy `0x20A0..0x35FF` i field encodings unchanged;
- `autonomous_clk == axi_aclk`, brak nowego clock/domain crossing;
- XDC/XCI/table/functional FSM/filter hashes exact R1g.

## 4. G2 — failed-record store

Nowy test nie odczytuje danych przez `#1`. Używa `read_req/read_rsp` i timeoutu
większego od zamrożonej maksymalnej latencji.

Obowiązkowe przypadki:

1. Po power/reset metadata=0; wszystkie 64x6 odczytów zwracają zero.
2. Wypełnij BRAM niezerowymi danymi, wykonaj reset metadanych bez physical RAM
   clear, ponownie sprawdź 64x6 zero.
3. Zapisz record 0, sprawdź wszystkie sześć różnych słów i wszystkie pola.
4. Zapisz records 0..63 pseudolosowym wzorcem; po każdym append sprawdź poprzedni
   i nowy rekord.
5. Record ordinal 64 jest przechowany bez overflow; ordinal 65 ustawia overflow,
   nie zmienia rekordu 0 ani 63; dalsze failures zwiększają total i last index.
6. W cyklu append nowego row odczytaj inny stary row — data exact.
7. W cyklu append zażądaj właśnie tworzonego row — odpowiedź zero; następne
   żądanie zwraca wszystkie sześć słów, nigdy record częściowy.
8. Invalid word 6/7 oraz index>=stored_count zwracają zero.
9. Malformed-record flag, total saturation i first/last validity zachowują exact
   R1g zachowanie; malformed rekord nadal jest liczony/przechowywany jak dawniej.
10. AXI pipeline reset przy read pending usuwa pending response; NVP metadata
    reset osobno maskuje payload; po samym AXI reset dane eksperymentu pozostają.

Assertions/coverage:

```text
one append event -> six WE in one cycle
six write addresses equal
no payload WE after stored_count==64
no response without accepted request
response data stable while valid && !ready
accepted valid read -> exactly one bounded response
```

## 5. G3 — index stores

Osobny production-depth test `DEPTH=512` dla każdej fazy:

1. Reset/stale-payload mask: wszystkie 256 packed words zero.
2. Zapisz zero-based values 0..511; sprawdź każdy packed word
   `{16'(2w+1),16'(2w)}`.
3. Ordinalny entry 512 (slot 511) jest stored; ordinalny event 513 ustawia
   overflow bez WE/no-overwrite.
4. Count=1: word0 ma lower=value0, upper=0. Count=3: word1 ma lower=value2,
   upper=0. Count=512: word255 zawiera entries510/511.
5. Wszystkie trzy phase RAM mają rozłączne dane i niezależny overflow.
6. Concurrent append i odczyt starego indeksu działa.
7. Request packed word obejmujący właśnie dopisywany odd element używa frozen
   count: górna połowa pozostaje zero; ponowne żądanie widzi nową wartość.
8. Read word `8'hff` jest legalnym ostatnim słowem; nie ma słowa poza zakresem
   w prawidłowo zdekodowanej 1-KiB fazie.
9. Reset request w stanach EVEN_WAIT i ODD_WAIT nie generuje późnej odpowiedzi.

Zachować mały `DEPTH=4` test jako szybki logiczny regression, lecz nie używać go
do wnioskowania o prymitywie produkcyjnym.

## 6. G4 — block statistics

Scoreboard przechowuje referencyjne 30 liczników R1g. Dla każdego target outcome
porównuje visible wartość wszystkich bloków po zboczu.

Obowiązkowe wzorce:

- all ACK: wszystkie 30 wartości zero;
- NACK na pierwszej i ostatniej opportunity każdego bloku;
- granice 998/999/1000/1001 i 9998/9999;
- wielokrotne NACK w jednym bloku;
- niezależne, interleaved trzy fazy;
- abort w środku bloku: completed blocks i live block exact;
- reset po niezerowym payload: completed-valid i live maskują stale RAM;
- request zaakceptowany dokładnie na zboczu NACK/update i na zboczu commit;
- simultaneous completed-RAM read i commit innego blocku;
- assertion, że najwyżej jeden block-commit/write-enable występuje w cyklu;
- block phase 3 lub index>=10 zwraca zero.

Gate: każdy observable odczyt po normalizacji latencji równa się referencyjnemu
R1g, a suma dziesięciu bloków fazy po completion równa się target NACK count.
W każdym cyklu każdej fazy dodatkowo wymagać
`target_opportunities == live_block_index*1000 + opportunities_in_block`, bez
implementowania mnożenia w sprzęcie (assertion/testbench only).

## 7. G5 — MMIO one-outstanding protocol

Test powinien sterować exact `host_req_*` i `host_rsp_*`, nie wewnętrznym
`read_data`.

Minimalna macierz:

- ordinary register, block RAM, każdy record word i każda index phase;
- exhaustive wszystkie 1368 aligned DWORD addresses `0x20A0..0x35FF`;
- unaligned addresses w każdej klasie zwracają zero;
- arbitrary `host_rsp_ready` low przez 0,1,2,17 cykli: valid/data stable;
- host utrzymuje drugi request, gdy pierwszy pending: `host_req_ready=0`, brak
  drugiej akceptacji;
- request w każdym WAIT/CAPTURE/RESP state;
- reset w każdym stanie; po reset brak ghost response;
- forwarded app request przed i po R1h read bez zmiany order/value;
- write do diagnostycznego range zachowuje exact wcześniejszy invalid/forwarded
  behavior i nie aktywuje żadnego RAM WE;
- response count == accepted-read count, order exact, brak duplikatów;
- zamrożona maksymalna latencja osobno dla REG, RECORD, INDEX i BLOCK.

Reference-versus-candidate comparator ignoruje liczbę cykli, lecz porównuje
ordered tuple `(address,status,rdata)` dla identycznego request streamu i
losowego backpressure.

## 8. G6/G7 — pełna równoważność naukowa

Pozostają obowiązkowe wszystkie R1g scenariusze:

```text
all ACK
isolated WADDR/REGADDR/DATA/RADDR NACK
multi-phase NACK in one transaction
13/15/36 historical patterns
64 failures and overflow at 65
transaction index 300
all 13 transaction kinds
operation-86 bank transition
bank selector/verify success, NACK and mismatch
tri-phase all-ACK/error/cluster/prerequisite/timeout/attempt-limit
safe-target setup/readback/restore
formal complete-range zero
host parser/statistics fixtures
```

Cycle-by-cycle porównuje funkcjonalne I2C/FSM/OEN oraz creation events:
record-valid+192b payload, phase counters, index-append phase/address/data,
block-update phase/block/value. MMIO porównuje się transaction-level.

## 9. G8 — bounded wrapper-only inference preflight

Prompt jawnie autoryzuje memory-inference check przed committem. Zalecany jest
jeden disposable OOC/in-memory synth wyłącznie wrapperów produkcyjnej wielkości,
bez `opt_design`, `place_design`, checkpointu i bitstreamu. Top preflightu musi
utrzymać wszystkie wejścia/wyjścia observable, by narzędzie nie usunęło RAM.

Wymagane raporty:

```text
report_utilization -hierarchical -hierarchical_depth 20
report_ram_utilization -include_lutram
primitive inventory by REF_NAME
full synthesis log extract for XPM/memory inference warnings
```

Fail-closed oczekiwanie:

```text
record RAMB18E1=6; RAMB36E1=0; RAM64M=0; RAMD64E=0
WADDR RAMB18E1=1
REGADDR RAMB18E1=1
DATA RAMB18E1=1
large payload FDRE=0
block store=small LUTRAM only
```

Każde `attribute ignored`, `register array`, unexpected replication, extra read
port lub niepełna liczba BRAM zatrzymuje commit.

## 10. G9 — exact post-synthesis full-build gate

Po jedynym full synthesis policzyć rzeczywiste leaf primitives w exact rebuilt
hierarchy i skorelować je z pinami/adresami, nie tylko nazwą instancji.

Przykładowe kontrole Tcl (nazwy należy zamrozić po implementacji):

```tcl
set rec_b18 [get_cells -hier -filter {REF_NAME == RAMB18E1 && NAME =~ *R1H_FAILED_RECORD*}]
set idx_w_b18 [get_cells -hier -filter {REF_NAME == RAMB18E1 && NAME =~ *R1H_INDEX_WADDR*}]
set idx_r_b18 [get_cells -hier -filter {REF_NAME == RAMB18E1 && NAME =~ *R1H_INDEX_REGADDR*}]
set idx_d_b18 [get_cells -hier -filter {REF_NAME == RAMB18E1 && NAME =~ *R1H_INDEX_DATA*}]
set rec_lutram [get_cells -hier -filter {(REF_NAME =~ RAM* || REF_NAME == RAMD64E) && NAME =~ *R1H_FAILED_RECORD*}]
```

Wymagać `llength` 6/1/1/1 oraz zero large-payload LUTRAM/FDRE. Dodatkowo
sprawdzić write-data/address/WE connectivity każdego B18 i brak wspólnej
zduplikowanej kopii.

Globalne hard gates przed place:

```text
POST_SYNTH_SLICE_LUTS<=18720
POST_SYNTH_SLICE_REGISTERS<=37440
FAILED_RECORD_PAYLOAD_RAMB18=6
TOTAL_INDEX_PAYLOAD_RAMB18=3
COMBINATIONAL_512_TO_1_INDEX_MUX=ABSENT
COMBINATIONAL_64_X_192_RECORD_MUX=ABSENT
```

W raporcie complexity/fanin należy wykazać, że response cone nie ma startpointów
w 24576 index FDRE ani odpowiednika dawnych szerokich drzew. Dopiero pełne PASS
G0–G9 zezwala jedynemu build flow przejść do `opt_design/place_design`.

## 11. Kryterium zakończenia pre-commit

```text
BRAM_WRAPPER_ELABORATION=PASS
RECORD_STORAGE_SCOREBOARD=PASS_64_AND_65
INDEX_STORAGE_SCOREBOARD=PASS_3_X_512_AND_513
BLOCK_STATISTICS_SCOREBOARD=PASS_ALL_30
MMIO_LATENCY_AND_BACKPRESSURE=PASS
MMIO_TRANSACTION_LEVEL_EQUIVALENCE=PASS_ALL_ADDRESSES
DIAGNOSTIC_EVENT_STREAM_IDENTICAL=YES
FUNCTIONAL_I2C_STREAM_IDENTICAL=YES
WRAPPER_ONLY_PRIMITIVE_MAPPING=PASS_6_PLUS_3_RAMB18
SCIENTIFIC_SCOPE_CHANGE=NO
```
