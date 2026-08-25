# R1h-R2 — niezależny audyt terminalnego post-synthesis

## Zakres i metoda

AUDIT_MODE=READ_ONLY_EXISTING_ARTIFACTS

VIVADO_INVOKED_BY_THIS_AUDIT=NO

SYNTHESIS_OR_IMPLEMENTATION_INVOKED_BY_THIS_AUDIT=NO

SOURCE_OR_GIT_MUTATION_BY_THIS_AUDIT=NO

Analiza korzysta wyłącznie z istniejącego checkpointu i istniejących raportów
terminalnej sesji R1h-R2. Checkpoint nie był otwierany; Vivado nie został
uruchomiony. Jedynym nowym artefaktem jest niniejszy task-local raport.

## 1. Tożsamość

FACT:

- R1H_SOURCE_COMMIT=`c4f4bfcf577c92c3021d1fe83c05878dd12e001c`
- R1H_SOURCE_TREE=`161e561f007912d73dba93c5ecd78e3cc3a6955b`
- bieżący exact worktree zwrócił te same HEAD/tree oraz `SOURCE_TREE_CLEAN=YES`
- R1H_EVIDENCE_COMMIT=`7dc8b8fb07033148e7c232c235da012d8b14b621`
- R1H_AUTHORITATIVE_REPORT_SHA256=`E7B41C0DD5CF21499BE55D8C4019F07694B1255252AB7539A1A376E7839B6468`
- R1H_EVIDENCE_PACKAGE_SHA256=`C56FE89CE24403FE7BD4702B53778BA4C2B5403536185BCC66EB32B8118CBC78`
- tool/session: Vivado `2025.2`, build `6299465`; part `xc7a35tcsg325-2`; top `ahd_capture_top_xdma`
- corrected task-local build harness SHA-256: `5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F`
- bound prebuild manifest SHA-256: `9926A439A41967304202D77A669F2F6A8F976F3A239D9D602F2AD4D4857644A1`

HASH-VERIFIED terminal inputs:

| Artefakt | SHA-256 |
|---|---|
| `R1H_synth.dcp` | `807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E` |
| `R1H_POST_SYNTH_RESOURCE_GATE.txt` | `92F3779DD14BDFFA05C551EB6728393FC1A1AE5715716D01628842CDC48EFC42` |
| `R1H_POST_SYNTH_PAYLOAD_PRIMITIVE_INVENTORY.txt` | `229F375D81DDAD6443C0711F56FA33226DF7199CAEC76B97CF6DF255666A1EBE` |
| `R1H_utilization_post_synth.rpt` | `D30D5EC33C500FB8F0AAA5414F01914FCFF0F70A4E7DCB696339FE3768242185` |
| `R1H_utilization_hierarchical_post_synth.rpt` | `64F9F58F5F584260B07BD1EF6D5C201A5177ED032C4CE18C4647504D6ECDBA5D` |
| `R1H_BUILD_PROVENANCE.txt` | `47CE5160D0B2741CA83B9DA311B0C683E4CD968CB747D370869CA7AB1FD27F52` |
| `R1H_ONE_CLEAN_BUILD_CONSUMED.marker` | `092D2C0048C1DC51057AA041DF4D5E514C875F07BB97287F3B58CDE2F7CC8621` |
| `R1H_BUILD_TERMINAL_FAILURE.txt` | `FD5CFEBCC50836FE16B7C64AACE0BEBB9603C06F2DB1D631451D28008BD78B28` |
| pełny log Vivado | `F1FD8ED7702F0FC3F2C014D9EADB2EE578FFB1D28CB4F1E72F6CC6AFF8780795` |
| journal Vivado | `4B7BC21B401E3D6C49B0ADBC691473BE9C3E9DD8043A4A7351B7D9B30D06B7FC` |

SOURCE-DERIVED FACT: `R1H_BUILD_PROVENANCE.txt` wiąże sesję z exact commit/tree,
czystym drzewem, właściwym part/top, `BUILD_FLAGS=0x00000002`, niezmienionym XCI
(`EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C`) oraz
zamrożonymi parametrami naukowymi. DCP SHA zapisany przez flow i niezależnie
obliczony z pliku jest identyczny.

## 2. Dowód mapowania payloadów

NETLIST-DERIVED FACT, z istniejącego `get_cells` inventory zapisanego przed
terminalnym stopem:

| Logiczny store | RAMB18E1 | RAMB36E1 | RAM64M | RAMD64E | FF w objętym regionie |
|---|---:|---:|---:|---:|---:|
| failed-record payload, 6 banków | 6 | 0 | 0 | 0 | 81 |
| WADDR index payload | 1 | 0 | 0 | 0 | część łącznego 3 |
| REGADDR index payload | 1 | 0 | 0 | 0 | część łącznego 3 |
| DATA index payload | 1 | 0 | 0 | 0 | część łącznego 3 |
| trzy index payloads łącznie | 3 | 0 | 0 | 0 | 3 |
| nowe payloady łącznie | **9** | **0** | **0** | **0** | 84 region-wide |

Sześć dokładnych komórek failed-record to:

`R1F_FAILED_TXN_LOGGER/GEN_R1H_RECORD_BANK[0..5].R1H_RECORD_PAYLOAD_RAM/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg`

Trzy dokładne komórki index store to:

`POST_INIT_TRI_PHASE_PROBE/INDEX_PAYLOAD_STORE/GEN_INDEX_BRAM[0..2].INDEX_PAYLOAD_RAM/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg`

NETLIST-DERIVED FACT: 81 FF w regionie loggera to policzone, nazwane rejestry
metadanych/pipeline (`first/last_failed_txn_index`, counts, overflow,
`read_word_q`, valid/status); trzy FF w regionie index store to
`read_phase_q_reg[1:0]` i `read_valid_reg`. Jest to wielokrotnie mniej niż
payloady logiczne 12 288 bitów i 24 576 bitów oraz mieści się w dwóch limitach
`<=192`. Nie ma podstaw, aby klasyfikować te 84 rejestry jako payload bank.

NETLIST-DERIVED FACT:

- `FAILED_RECORD_PAYLOAD_RAM64M=0`
- `FAILED_RECORD_PAYLOAD_RAMD64E=0`
- `INDEX_PAYLOAD_RAM64M=0`
- `INDEX_PAYLOAD_RAMD64E=0`
- `FAILED_RECORD_PAYLOAD_RAMB18=6`
- `WADDR/REGADDR/DATA_INDEX_PAYLOAD_RAMB18=1/1/1`
- `POST_SYNTH_MEMORY_MAPPING_GATE=PASS`

INTERPRETATION: wymagane mapowanie **6+1+1+1 RAMB18 zostało udowodnione**.
Duże payloady nie wróciły do FDRE ani LUTRAM. Cały projekt nadal zawiera 1 147
LUTRAM/SRL LUT (1 133 distributed-RAM + 14 SRL), ale raport hierarchiczny
przypisuje całe 1 133 LUTRAM i 14 SRL do odziedziczonego XDMA, nie do czterech
payload stores. Stwierdzenie „LUTRAM absence” dotyczy payloadów R1h, a nie całego
projektu.

LIMITATION: `report_utilization -hierarchical` pokazuje przebudowany, częściowo
spłaszczony wiersz `(R1F_FAILED_TXN_LOGGER)` bez RAMB18. Nie wykorzystano tego
wiersza do zanegowania mapowania: dokładne leaf names i `REF_NAME==RAMB18E1`
pochodzą z istniejącego inventory DCP. Łączny raport potwierdza wzrost z 3 do 12
RAMB18E1, dokładnie o dziewięć.

## 3. Całkowite zasoby i arytmetyka gate

NETLIST-DERIVED FACT:

| Zasób post-synth | R1h-R2 | Dostępne / limit | Wynik |
|---|---:|---:|---|
| Slice LUTs | **19 255** | device 20 800; hard gate 18 720 | **FAIL hard gate** |
| LUT as Logic | 18 108 | device 20 800; expected target 18 000 | target przekroczony o 108; nie jest osobnym hard gate |
| LUT as Memory | 1 147 | 9 600 | PASS capacity |
| Slice Registers / FF | **20 395** | device 41 600; hard gate 37 440 | **PASS hard gate** |
| Latches | 0 | 41 600 | PASS |
| MUXF7 | 432 | 16 300 | PASS capacity |
| MUXF8 | 77 | 8 150 | PASS capacity |
| RAMB18E1 | 12 | 100 | PASS capacity |
| RAMB36E1 | 21 | 50 | PASS capacity |
| BRAM tiles | 27 | 50 | 54.00% |
| DSP | 0 | 90 | PASS |

ARITHMETIC FACT:

- Slice LUT utilization = `19255 / 20800 = 92.5721%`.
- Raw Slice LUT headroom = `20800 - 19255 = 1545`, czyli `7.4279%`.
- Wymagany 10% headroom odpowiada limitowi 18 720; wynik przekracza go o
  **535 Slice LUT**, czyli o 2.5721 punktu procentowego pojemności urządzenia.
- Register utilization = `20395 / 41600 = 49.0264%`.
- Raw register headroom = `21205` (`50.9736%`).
- Wynik FF jest o `37440 - 20395 = 17045` poniżej hard limitu oraz o 4 605
  poniżej oczekiwanego targetu 25 000.
- Łączny BRAM tile count jest spójny: `21 RAMB36 + 12/2 RAMB18 = 27 tiles`.

CLASSIFICATION: **POST_SYNTH_MEMORY_MAPPING_GATE=PASS**, ale
**POST_SYNTH_RESOURCE_MARGIN_GATE=FAIL_LUT_ONLY**. FF nie spowodowały stopu.
Kombinowany gate musiał zakończyć flow mimo pełnego sukcesu mapowania BRAM.

## 4. Exact same-stage delta względem R1g i R1e

Porównanie korzysta z publikowanego audytu zasobów R1g:

- `R1G_RESOURCE_ATTRIBUTION_REPORT.md` SHA-256
  `45A5E7BE82D94BFB781BA6726F3FBD47236CD551703542EE4964C6C392C2ACB6`
- jego `SHA256_MANIFEST.txt` SHA-256
  `776A900D108880230CFFA4CC0BC1AF989858E3A2C0298C5F0B38B0DC310A691F`
- R1g post-synth utilization SHA-256
  `46EAB048CD1FAFBC0D071C443BDFC067E5DC4160F0E2B54245AB3B91AEC76B37`
- R1e post-synth utilization SHA-256
  `46E2AC00D0D8F8B14CECC0E2DD5F45984A68F176171948B96D989F2B8A994FE0`

Wszystkie trzy punkty są `Design State: Synthesized`, ten sam part/top i Vivado
2025.2 build 6299465. Nie mieszano post-opt ani routed figures.

| Zasób | R1e post-synth | R1g post-synth | R1h-R2 post-synth | R1h-R2 − R1g | R1h-R2 − R1e |
|---|---:|---:|---:|---:|---:|
| Slice LUTs | 15 101 | 33 982 | 19 255 | **−14 727** | +4 154 |
| Logic LUTs | 13 954 | 32 615 | 18 108 | **−14 507** | +4 154 |
| LUT as Memory | 1 147 | 1 367 | 1 147 | **−220** | 0 |
| FF | 17 036 | 45 262 | 20 395 | **−24 867** | +3 359 |
| MUXF7 | 326 | 1 570 | 432 | **−1 138** | +106 |
| MUXF8 | 10 | 619 | 77 | **−542** | +67 |
| RAMB36E1 | 21 | 21 | 21 | 0 | 0 |
| RAMB18E1 | 3 | 3 | 12 | **+9** | +9 |
| BRAM tiles | 22.5 | 22.5 | 27.0 | +4.5 | +4.5 |

INTERPRETATION: architektura BRAM/synchronicznego read service usunęła
zdecydowaną większość przyrostu R1g i przywróciła pełną zgodność LUTRAM z bazą
R1e. Redukcja względem R1g wyniosła 14 507 Logic LUT i 24 867 FF. To nie jest
jednak wystarczające do zadeklarowanego hard gate 10% dla **Slice LUTs**:
pozostało 1 545 wolnych zamiast wymaganych 2 080.

## 5. Hierarchiczna atrybucja delty

NETLIST-DERIVED FACT, exact same-stage top-level hierarchy rows:

| Hierarchia | R1g Logic LUT | R1h-R2 Logic LUT | Delta LUT | R1g FF | R1h-R2 FF | Delta FF | Istotny memory delta |
|---|---:|---:|---:|---:|---:|---:|---|
| `POST_INIT_TRI_PHASE_PROBE` | 14 207 | 2 093 | **−12 114** | 27 812 | 2 934 | **−24 878** | +3 RAMB18 |
| `AXI_LITE_HOST_BRIDGE` | 4 174 | 1 845 | **−2 329** | 110 | 110 | 0 | 0 |
| `R1F_FAILED_TXN_LOGGER` | 186 | 151 | −35 | 140 | 81 | −59 | −220 LUTRAM, +6 RAMB18 |
| `R1H_MMIO_READ_SERVICE` | 0 | 93 | +93 | 0 | 71 | +71 | 0 |
| `NVP_AUTOINIT` | 2 143 | 2 166 | +23 | 1 546 | 1 545 | −1 | 0 |
| `CAPTURE_SUBSYSTEM` | 1 239 | 1 097 | −142 | 2 617 | 2 617 | 0 | 0 |
| `CONTROL_STATUS_REGS` | 38 | 27 | −11 | 65 | 65 | 0 | 0 |
| `LIFECYCLE_MONITOR` | 86 | 89 | +3 | 311 | 311 | 0 | 0 |
| `XDMA` | 10 509 | 10 509 | 0 | 11 970 | 11 970 | 0 | unchanged 1 133 LUTRAM, 14 SRL, 19 RAMB36, 3 RAMB18 |

ARITHMETIC FACT: FF deltas powyżej rekoncyliują całkowite `−24 867` dokładnie.
Logic-LUT deltas rekoncyliują `−14 512`; różnica +5 do exact total `−14 507`
jest skutkiem zmiany nieprzypisanego residual w hierarchicznym raporcie (R1g:
7 LUT, R1h-R2: 12 LUT). Nie przypisuje się tych pięciu LUT arbitralnie.

Same-stage R1e context:

- R1e zawierał `POST_INIT_ADDRESS_PROBE`: 317 Logic LUT / 523 FF; R1h-R2 go nie
  zawiera i ma rozszerzony `POST_INIT_TRI_PHASE_PROBE`: 2 093 / 2 934.
- `NVP_AUTOINIT` wzrósł z 819 / 749 do 2 166 / 1 545.
- `AXI_LITE_HOST_BRIDGE` wzrósł z 886 do 1 845 Logic LUT, a nowy
  `R1H_MMIO_READ_SERVICE` kosztuje dodatkowo 93 / 71.
- Logger kosztuje 151 Logic LUT / 81 FF i sześć RAMB18; jego payload LUTRAM jest
  nieobecny.
- Exact R1h-R2 total pozostaje względem R1e większy o 4 154 Logic/Slice LUT i
  3 359 FF. Baseline XDMA jest bit-for-bit/resource-identical w tych raportach.

INTERPRETATION: terminalny brak 535 LUT do gate nie jest skutkiem nieudanego
mapowania pamięci. Pozostały koszt R1f/R1h obserwacji i kontroli, głównie
tri-phase probe, rozszerzony autoinit oraz host/MMIO, zużywa więcej niż
dozwolonych 90% Slice LUT mimo zasadniczej korekty storage/read mux.

## 6. Terminalny stan i fail-closed decyzja

FACT z `R1H_BUILD_TERMINAL_FAILURE.txt`:

```text
R1H_ONE_CLEAN_BUILD_CONSUMED=YES
TERMINAL_BUILD_STAGE=POST_SYNTH_RESOURCE_GATE
SYNTHESIS_RUNS=1
OPT_DESIGN_RUNS=0
PLACE_DESIGN_RUNS=0
ROUTE_DESIGN_RUNS=0
BITSTREAM_RUNS=0
TERMINAL_ERROR=BLOCKED_R1H_POST_SYNTH_RESOURCE_MARGIN_OR_MEMORY_MAPPING
```

Ten terminal token jest nazwą wspólnego exception w task-local harness. Pełna
przyczyna po rozdzieleniu jego składowych jest dokładnie:

```text
POST_SYNTH_MEMORY_MAPPING_GATE=PASS
POST_SYNTH_RESOURCE_MARGIN_GATE=FAIL_LUT_ONLY
POST_SYNTH_COMBINED_GATE=FAIL
POST_SYNTH_SLICE_LUT_GATE_EXCESS=535
POST_SYNTH_FF_GATE=PASS
```

R1H_R2_TASK_SPEC_HARD_STOP_CLASS=
`BLOCKED_R1H_R2_POST_SYNTH_RESOURCE_OR_MAPPING_GATE`

CAUSE_DISAMBIGUATION=`POST_SYNTH_RESOURCE_MARGIN_GATE=FAIL_LUT_ONLY`

Nie wolno skracać tej klasyfikacji do „memory mapping failed”: byłoby to
sprzeczne z inventory i receipt. Nie wolno także traktować `SYNTHESIS=PASS` jako
zgody na dalszy flow: mandat 10% Slice-LUT headroom nie przeszedł.

NEXT_ACTION=
`HARD_STOP_PRESERVE_AND_PUBLISH_EVIDENCE_OWNER_AND_AUDITOR_REVIEW_OF_R1H_R2_POST_SYNTH_LUT_MARGIN_FAILURE`

W szczególności: brak `opt_design`, `place_design`, `route_design`, routed DCP,
bitstreamu i hardware campaign. Jedyny build został zużyty. Każda kolejna
korekta RTL/harness albo build wymaga osobnej autoryzacji; ten audyt ich nie
wykonuje ani nie rekomenduje obejścia istniejącego gate.

## Końcowy blok audytu

```text
AUDIT=
    R1H_R2_INDEPENDENT_POST_SYNTH_RESOURCE_AUDIT

SOURCE_GIT_COMMIT=
    c4f4bfcf577c92c3021d1fe83c05878dd12e001c

SOURCE_GIT_TREE=
    161e561f007912d73dba93c5ecd78e3cc3a6955b

VIVADO_VERSION=
    2025.2_BUILD_6299465

SYNTH_DCP_SHA256=
    807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E

FAILED_RECORD_PAYLOAD_RAMB18=
    6

WADDR_INDEX_PAYLOAD_RAMB18=
    1

REGADDR_INDEX_PAYLOAD_RAMB18=
    1

DATA_INDEX_PAYLOAD_RAMB18=
    1

R1H_NEW_PAYLOAD_RAMB18_TOTAL=
    9

FAILED_RECORD_PAYLOAD_RAM64M=
    0

FAILED_RECORD_PAYLOAD_RAMD64E=
    0

INDEX_PAYLOAD_RAM64M=
    0

INDEX_PAYLOAD_RAMD64E=
    0

FAILED_RECORD_REGION_ALL_FF=
    81_METADATA_AND_PIPELINE_ONLY

INDEX_PAYLOAD_REGION_ALL_FF=
    3_READ_PIPELINE_ONLY

POST_SYNTH_MEMORY_MAPPING_GATE=
    PASS

POST_SYNTH_SLICE_LUTS=
    19255

POST_SYNTH_SLICE_LUTS_LIMIT=
    18720

POST_SYNTH_SLICE_LUT_GATE_EXCESS=
    535

POST_SYNTH_SLICE_REGISTERS=
    20395

POST_SYNTH_SLICE_REGISTERS_LIMIT=
    37440

POST_SYNTH_FF_GATE=
    PASS

POST_SYNTH_RESOURCE_MARGIN_GATE=
    FAIL_LUT_ONLY

EXACT_HARNESS_TERMINAL_ERROR=
    BLOCKED_R1H_POST_SYNTH_RESOURCE_MARGIN_OR_MEMORY_MAPPING

TASK_SPEC_HARD_STOP_CLASS=
    BLOCKED_R1H_R2_POST_SYNTH_RESOURCE_OR_MAPPING_GATE

CAUSE_DISAMBIGUATION=
    POST_SYNTH_RESOURCE_MARGIN_GATE_FAIL_LUT_ONLY

OPT_DESIGN_RUNS=
    0

PLACE_DESIGN_RUNS=
    0

ROUTE_DESIGN_RUNS=
    0

BITSTREAMS=
    0

HARDWARE_ACTIONS=
    0

NEXT_ACTION=
    HARD_STOP_PRESERVE_AND_PUBLISH_EVIDENCE_OWNER_AND_AUDITOR_REVIEW_OF_R1H_R2_POST_SYNTH_LUT_MARGIN_FAILURE
```
