# R1h — niezależny projekt i audyt architektury pamięci P1–P3

```text
TASK=V41_NVP_R1H_BRAM_BACKED_PHASE_COMPLETE_OBSERVABILITY_AND_LARGE_SAMPLE_AB
DOCUMENT_SCOPE=READ_ONLY_P1_P2_P3_ARCHITECTURE_AUDIT
R1G_SOURCE_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1G_SOURCE_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
R1G_PARENT_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
VIVADO_TARGET=2025.2_BUILD_6299465
PART=xc7a35tcsg325-2
SOURCE_MUTATIONS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
HARDWARE_ACTIONS=0
```

## 1. Zakres dowodowy

Ten dokument opisuje syntetyzowalną architekturę SystemVerilog dla R1h. Nie
jest łatą źródłową ani wynikiem syntezy. Oczekiwane mapowanie na prymitywy jest
kontraktem fail-closed, który musi zostać potwierdzony najpierw ograniczonym
preflightem inference, a następnie exact pełnym checkpointem post-synthesis.

Przeanalizowano exact R1g:

| Plik | SHA-256 |
|---|---|
| `rtl/v41/r1f_failed_txn_logger.sv` | `EFAF862E4267A8AE9A042FFB6B5F074B217CD8D0AD2DD3E4E783BA6F6B7B6C71` |
| `rtl/v41/nvp_i2c_tri_phase_probe.sv` | `4AA823B5896D9C11DB9837D1F30E4E077557FE367942B032B404ACBA92E03552` |
| `rtl/v41/r1f_measurement_regs.sv` | `BB77188A3A28F34DB3BBC195129A58620D11ECFE4F617528D68002DC1F1FDBFF` |
| `rtl/v41/control_status_regs.sv` | `BE70C2707EDAFE075008F9592E474AF1E1658D75A75D5053A1F2FFBD072E44B5` |
| `rtl/top/ahd_capture_top_xdma.sv` | `CD8E2BB50D89273857168722EDA06F83AE08FA059FCA266522E6D2E3CD2CB77F` |
| `rtl/pio/pio_bar_target.sv` | `E6BED9C57D5A79E4D2AD2C5E3CEEFCD4AEDCCC9CEA77A61C6A84F350FE6FF833` |
| `scripts/v41/r1f_build.tcl` | `53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B` |

## 2. Najważniejsze fakty źródłowe

- **SOURCE-DERIVED FACT:** `autonomous_clk` jest dokładnie aliasem `axi_aclk`
  (`ahd_capture_top_xdma.sv:36-39`). Pamięci obserwacyjne i serwis MMIO działają
  więc w jednej domenie zegarowej 62,5 MHz. R1h nie potrzebuje nowego CDC.
- **SOURCE-DERIVED FACT:** reset danych naukowych to `nvp_por_reset`, natomiast
  pipeline odpowiedzi hosta używa `~axi_aresetn`. Oba resety należy zachować
  jako rozłączne funkcje: pierwszy zeruje metadane eksperymentu, drugi wyłącznie
  stan transakcji/pipeline MMIO.
- **SOURCE-DERIVED FACT:** existing build już używa `xpm_memory_sdpram` oraz
  ustawia `XPM_LIBRARIES {XPM_CDC XPM_MEMORY}`. Dodanie wrapperów SystemVerilog
  nie wymaga VHDL-2008 ani zmiany globalnego standardu języka.
- **SOURCE-DERIVED FACT:** `record_mem` ma jeden synchroniczny append i jeden
  kombinacyjny random-read (`r1f_failed_txn_logger.sv:33,58-70,101-104`).
- **SOURCE-DERIVED FACT:** każda faza index log ma jeden zapis 16-bitowy, ale
  istniejący odczyt wystawia równolegle dwa dowolne elementy
  (`nvp_i2c_tri_phase_probe.sv:653,740-745,1176-1191`).
- **SOURCE-DERIVED FACT:** `block_nack_count` ma 30 słów po 32 bity, pełny reset
  i dynamiczny read-modify-write (`...probe.sv:652,711,737-739,823-825`).
- **SOURCE-DERIVED FACT:** żaden z trzech payloadów nie wpływa na scheduler ani
  funkcjonalny I2C. Ich odczyty są używane wyłącznie przez stronę diagnostyczną
  MMIO w topie.

## 3. Wspólny wrapper XPM

Zalecany element bazowy to mały wrapper SystemVerilog nad
`xpm_memory_sdpram`. Użycie jawnego XPM jest bardziej deterministyczne niż sam
atrybut `ram_style`, a identyczny typ XPM jest już zaakceptowany w exact source.

Wspólne parametry produkcyjne:

```systemverilog
.AUTO_SLEEP_TIME(0),
.CLOCKING_MODE("common_clock"),
.ECC_MODE("no_ecc"),
.MEMORY_INIT_FILE("none"),
.MEMORY_INIT_PARAM("0"),
.MEMORY_OPTIMIZATION("false"),
.MEMORY_PRIMITIVE("block"),
.MESSAGE_CONTROL(0),
.READ_LATENCY_B(1),
.READ_RESET_VALUE_B("0"),
.RST_MODE_B("SYNC"),
.SIM_ASSERT_CHK(1),
.USE_EMBEDDED_CONSTRAINT(0),
.USE_MEM_INIT(0),
.WAKEUP_TIME("disable_sleep"),
.WRITE_MODE_B("read_first")
```

Oba porty dostają ten sam `axi_aclk`. Port A jest write-only, port B read-only.
`rstb` zeruje jedynie `doutb`/pipeline; nie czyści payloadu. `read_first` jest
zamrożoną semantyką kolizji, lecz architektura maskowania sprawia, że wynik
kolizji z jeszcze niewidocznym wpisem nigdy nie jest host-visible.

`MEMORY_OPTIMIZATION="false"` jest zalecane, ponieważ rekord ma pola stałe i
R1g wcześniej zredukował 192 bity do 174 bitów dynamicznych. Finalna akceptacja
nie może polegać na parametrze: wymaga rzeczywistych `RAMB18E1` w netliście.

Minimalny, syntetyzowalny kształt wrappera (szablon, nie patch source) jest
następujący:

```systemverilog
module v41_r1h_sdp_block_ram #(
  parameter int ADDR_W = 6,
  parameter int DATA_W = 32,
  parameter int DEPTH  = 64
) (
  input  logic              clk,
  input  logic              rd_reset,
  input  logic              wr_en,
  input  logic [ADDR_W-1:0] wr_addr,
  input  logic [DATA_W-1:0] wr_data,
  input  logic              rd_en,
  input  logic [ADDR_W-1:0] rd_addr,
  output logic [DATA_W-1:0] rd_data
);
  logic [0:0] wea;
  assign wea[0] = wr_en;

  xpm_memory_sdpram #(
    .ADDR_WIDTH_A(ADDR_W), .ADDR_WIDTH_B(ADDR_W),
    .AUTO_SLEEP_TIME(0), .BYTE_WRITE_WIDTH_A(DATA_W),
    .CLOCKING_MODE("common_clock"), .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("none"), .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("false"), .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(DEPTH*DATA_W), .MESSAGE_CONTROL(0),
    .READ_DATA_WIDTH_B(DATA_W), .READ_LATENCY_B(1),
    .READ_RESET_VALUE_B("0"), .RST_MODE_B("SYNC"),
    .SIM_ASSERT_CHK(1), .USE_EMBEDDED_CONSTRAINT(0),
    .USE_MEM_INIT(0), .WAKEUP_TIME("disable_sleep"),
    .WRITE_DATA_WIDTH_A(DATA_W), .WRITE_MODE_B("read_first")
  ) PAYLOAD_RAM (
    .clka(clk), .ena(wr_en), .wea(wea),
    .addra(wr_addr), .dina(wr_data),
    .clkb(clk), .enb(rd_en), .addrb(rd_addr), .doutb(rd_data),
    .rstb(rd_reset), .regceb(1'b1), .sleep(1'b0),
    .injectsbiterra(1'b0), .injectdbiterra(1'b0),
    .sbiterrb(), .dbiterrb()
  );
endmodule
```

Profil record używa `ADDR_W=6, DATA_W=32, DEPTH=64`; profil index
`ADDR_W=9, DATA_W=16, DEPTH=512`. Wrapper nie ma resetu write portu/payloadu;
`wr_en` jest blokowane przez reset metadanych w logice nadrzędnej. Ostateczny
kod powinien mieć statyczne assertions dozwalające tylko te dwa produkcyjne
profile, aby przypadkowa zmiana wymiarów nie przeszła cicho.

## 4. P1 — failed-transaction payload

### 4.1 Organizacja fizyczna

Sześć niezależnych instancji, nazwanych stabilnie przykładowo
`R1H_FAILED_RECORD_WORD0` … `WORD5`:

| Parametr XPM | Wartość per bank |
|---|---:|
| `MEMORY_SIZE` | `2048` |
| `ADDR_WIDTH_A/B` | `6 / 6` |
| `WRITE_DATA_WIDTH_A` | `32` |
| `READ_DATA_WIDTH_B` | `32` |
| `BYTE_WRITE_WIDTH_A` | `32` |
| oczekiwany primitive | dokładnie `1 RAMB18E1` |

Każdy event `r1f_failed_txn_valid` przy `stored_count < 64` aktywuje w tym
samym zboczu wszystkie sześć WE, ten sam row `stored_count[5:0]` i słowa
`record[32*g +: 32]`. To zachowuje jednocykliczne przyjęcie i atomowy zapis
pełnych 192 bitów bez serializera.

### 4.2 Metadane i deterministic zero

Payload nie ma resetu. Resetowane pozostają exact R1g:

- `total_count`, `stored_count`, `overflow`;
- first/last index i ich valid bits;
- saturation i input-protocol-error;
- stan pipeline odczytu.

`entry_valid[63:0]` nie jest potrzebne, bo append-only gwarantuje ciągły prefiks
ważnych rekordów. Przy akceptacji żądania serwis zamraża:

```text
record_visible = aligned && word < 6 && record_index < stored_count
```

Jeżeli `record_visible=0`, odpowiedź wynosi zero i nie jest interpretowany
`doutb`. Reset `stored_count=0` maskuje stare, niezerowe bity BRAM. Ten sam
mechanizm gwarantuje zero dla wszystkich nieużywanych rekordów po częściowym
ponownym zapełnieniu.

### 4.3 Kolizje i atomowość

Przy appendzie `write_row == stored_count_before`. Ważny read spełnia
`read_row < stored_count_before`. Zatem ważny host read i append nie mogą w tym
samym cyklu dotyczyć tego samego row. Read starego rekordu podczas appendu
innego rekordu jest legalny. Read nowego row zaakceptowany w cyklu appendu
zostaje zamaskowany do zera; następne żądanie widzi wszystkie sześć słów.

Wymagane assertions:

```text
append_accept -> all_six_we && all_six_waddr_equal
append_accept -> write_row == $past(stored_count)
stored_count <= 64
stored_count == 64 -> !any_payload_we
valid_read && append_accept -> read_row != write_row
failed_event_65 -> overflow && !any_payload_we
```

### 4.4 Exact target

```text
FAILED_RECORD_PAYLOAD_RAMB18=6
FAILED_RECORD_PAYLOAD_RAMB36=0
FAILED_RECORD_PAYLOAD_RAM64M=0
FAILED_RECORD_PAYLOAD_RAMD64E=0
FAILED_RECORD_PAYLOAD_FDRE=0
```

FDRE pipeline i metadanych należy raportować osobno od payloadu.

## 5. P2 — trzy probe-index payloads

### 5.1 Organizacja fizyczna

Zgodnie z aktualnym promptem R1h należy użyć trzech niezależnych logicznych
`512x16` RAM, a nie wcześniejszego wariantu audytowego `256x32` z half-word WE.
Każda faza ma osobną instancję XPM:

| Parametr XPM | Wartość per phase |
|---|---:|
| `MEMORY_SIZE` | `8192` |
| `ADDR_WIDTH_A/B` | `9 / 9` |
| `WRITE_DATA_WIDTH_A` | `16` |
| `READ_DATA_WIDTH_B` | `16` |
| `BYTE_WRITE_WIDTH_A` | `16` |
| oczekiwany primitive | dokładnie `1 RAMB18E1` |

Phase-local WE jest aktywne tylko dla target NACK tej fazy oraz
`stored_count < 512`. Write address to stary `stored_count[8:0]`, a write data
to exact zero-based `target_opportunities[15:0]` sprzed inkrementacji.

### 5.2 Odczyt `{odd, even}`

Jedyny port odczytu wykonuje dwa odczyty sekwencyjne. Przy akceptacji MMIO
zamraża się `phase`, `word`, `stored_count_snapshot` oraz:

```text
even_address = {word,1'b0}
odd_address  = {word,1'b0} + 1
even_visible = even_address < stored_count_snapshot
odd_visible  = odd_address  < stored_count_snapshot
```

FSM odczytu wydaje najpierw even, następnie odd, i składa:

```text
RDATA[15:0]  = even_visible ? even_dout : 16'h0000
RDATA[31:16] = odd_visible  ? odd_dout  : 16'h0000
```

Nie wolno ponownie sprawdzać żywego `stored_count` przy składaniu odpowiedzi;
snapshot zapobiega „dopisaniu” górnej połowy w trakcie jednej transakcji.

### 5.3 Kolizje, overflow i reset

Jak dla rekordów, ważny odczyt dotyczy tylko prefiksu przed write pointerem.
Fizyczny same-address read może zostać całkowicie pominięty, gdy odpowiednia
połowa jest nieważna. `read_first` jest dodatkowym zabezpieczeniem symulacyjnym.

Ordinalny 512. NACK zapisuje slot 511. Ordinalny 513. NACK ustawia overflow,
nie aktywuje WE i nie zmienia żadnego slotu. `stored_count` pozostaje 512.
Payload nie jest czyszczony; count=0 po `nvp_por_reset` maskuje go do zera.

Exact target:

```text
WADDR_INDEX_PAYLOAD_RAMB18=1
REGADDR_INDEX_PAYLOAD_RAMB18=1
DATA_INDEX_PAYLOAD_RAMB18=1
TOTAL_INDEX_PAYLOAD_RAMB18=3
INDEX_PAYLOAD_RAMB36=0
INDEX_PAYLOAD_FDRE=0
```

Do limitu `INDEX_PAYLOAD_FDRE_TOTAL<=192` można zaliczyć wyłącznie liczniki,
overflow, phase/word snapshot, pack register i pipeline valid — nigdy 8192-bitowy
payload.

## 6. P3 — block statistics 30x32

### 6.1 Rekomendowana implementacja

Ze względu na wąski margines LUT prognozowany przez poprzedni audyt rekomenduję
mały LUTRAM z trzema phase-local accumulatorami, a nie zachowanie 960 FF.

Struktury:

```text
completed_block_ram: 30 x 32, ram_style="distributed"
completed_valid:     30 bits, resetowane
live_block_count:     3 x 32 bits, resetowane
live_block_index:     3 x 4 bits, resetowane
opportunities_in_block: 3 x 10 bits, resetowane
```

`completed_block_ram` ma jeden synchroniczny write i jeden wąski read. Nie ma
physical clear. Może być jawnym `xpm_memory_sdpram` z
`MEMORY_PRIMITIVE="distributed"`, `MEMORY_SIZE=960`, `ADDR_WIDTH=5`,
`DATA_WIDTH=32`, `READ_LATENCY_B=1`, albo równoważnym, osobno potwierdzonym
RAM32M/LUTRAM. Jeden write port wystarcza: exact high-level FSM wykonuje co
najwyżej jedno wywołanie `record_target_outcome(current_phase, ...)` w jednym
cyklu `H_PROBE_WAIT` (`...probe.sv:941-978`), więc dwa bloki nie mogą zamknąć
się na tym samym zboczu.

Nie należy implementować nowego dzielenia ani modulo przez 1000 w ścieżce
update. Phase-local `opportunities_in_block` zlicza `0..999`, a
`live_block_index` zlicza `0..10`. Na każdym target outcome fazy `p`:

```text
next_live = live_block_count[p] + (outcome_nack ? 1 : 0)
closing   = opportunities_in_block[p] == 999
```

Jeżeli `closing=0`, zapisz `next_live` do phase-local live accumulatora. Jeżeli
`closing=1`, zapisz `next_live` do row `p*10 + live_block_index[p]`, ustaw jego
valid, wyzeruj live accumulator i licznik pozycji, po czym zwiększ block index.
Commit następuje również dla bloku z zerem NACK. Assertion w symulacji ma
potwierdzać w każdym cyklu
`target_opportunities == live_block_index*1000 + opportunities_in_block`; jest
to dowód równoważności, a nie logika sprzętowa dzieląca przez stałą.

Odczyt trwającego bloku pochodzi z właściwego `live_block_count[p]`; blok
zakończony z RAM, a przyszły/invalid z zera. Po osiągnięciu 10000 wszystkie
dziesięć bloków fazy jest zakończone, więc cały końcowy dataset pochodzi z RAM.
Po abort zachowany jest również częściowy bieżący blok.

### 6.2 Semantyka jednoczesnego update/read

R1g przyjmuje host request na zboczu i rejestruje wartość sprzed NBA update.
R1h musi zamrozić klasyfikację i live value w tym samym zboczu. Dla kolizji z
commitem completed RAM `WRITE_MODE_B="read_first"` zachowuje tę samą wartość
sprzed update. Następna transakcja widzi wartość nową.

### 6.3 Alternatywa minimalnego ryzyka

Zachowanie istniejącego banku 960 FF jest naukowo poprawne i nadal powinno
pozostawić duży margines FF po usunięciu 24576 payload FDRE. Jest dopuszczalne
przez prompt, lecz powinno zostać wybrane tylko wtedy, gdy przed committem
policzony model/resource preflight dowodzi `POST_SYNTH_SLICE_LUTS<=18720`.
Nie jest to preferowana ścieżka, ponieważ obecny block-update cone obejmuje
`960 FDRE + 237 CARRY4` i znaczną logikę wyboru.

## 7. Integracja z synchronicznym serwisem MMIO

Wrappery powinny wystawiać wyłącznie wąskie porty request/data, nigdy pełne
tablice. Zalecany podział klas żądania:

```text
REG_FAST       0x20A0..0x21FF i non-block words 0x2200..0x23FF
BLOCK_RAM      phase detail words 19..28
RECORD_RAM     0x2400..0x29FF
INDEX_WADDR    0x2A00..0x2DFF
INDEX_REGADDR  0x2E00..0x31FF
INDEX_DATA     0x3200..0x35FF
ZERO           unaligned/reserved/invalid
```

`v41_control_status_regs` już ma jeden `local_rsp_valid`, lecz obecne
`host_req_ready = !local_rsp_valid` nie blokuje requestów w okresie oczekiwania
na BRAM, gdy response-valid jeszcze wynosi zero. R1h musi dodać jawny
`r1h_read_pending`; dla strony R1h ready jest prawdziwe tylko w IDLE.

Przykładowe stany:

```text
IDLE
REG_RESP
RECORD_ISSUE -> RECORD_WAIT -> RECORD_CAPTURE
INDEX_EVEN_ISSUE -> INDEX_EVEN_WAIT -> INDEX_EVEN_CAPTURE
                 -> INDEX_ODD_ISSUE -> INDEX_ODD_WAIT -> INDEX_ODD_CAPTURE
RESP_HOLD
```

Stan może być zredukowany po symulacyjnym potwierdzeniu dokładnej latencji XPM,
ale nie wolno próbować capture w tym samym zboczu, w którym dopiero rejestrowane
są `enb/addrb`. Accepted `pio_bar_target.sv:396-405` używa osobnych WAIT i
CAPTURE dokładnie z tego powodu.

W `RESP_HOLD` data/status pozostają stabilne do `host_rsp_ready`. W tym czasie
`host_req_ready=0`. Reset AXI kasuje pending/response, lecz nie count/payload
eksperymentu. Writes do zakresu R1h nadal idą dotychczasową invalid/forwarded
ścieżką i nie mogą dostać nowego side effect.

## 8. Tabela reset/collision/read-during-write

| Struktura | Reset fizyczny payloadu | Metadata reset | Legalny równoległy read/write | Same address | Host-visible wynik |
|---|---|---|---|---|---|
| record 6x64x32 | nie | count/pointers/status | stary row + append nowego row | ważny read: niemożliwy | exact stare słowo; nowy row zero do następnego requestu |
| index 3x512x16 | nie | per-phase count/overflow | stored index + append nowego | nieważna połowa może być pominięta | snapshot `{odd,even}`, nieważna połowa zero |
| completed blocks | nie | valid + live accumulators | host read + rzadki block commit | `read_first` | wartość sprzed update dla requestu zaakceptowanego na tym zboczu |
| MMIO response | pipeline reset przez AXI | pending/valid/data | brak drugiego outstanding | nie dotyczy | stabilne do ready |

## 9. Oczekiwane prymitywy i hard stops

| Hierarchia | RAMB18E1 | RAMB36E1 | payload FDRE | RAM64M/RAMD64E |
|---|---:|---:|---:|---:|
| six failed words | 6 | 0 | 0 | 0 |
| WADDR index | 1 | 0 | 0 | 0 |
| REGADDR index | 1 | 0 | 0 | 0 |
| DATA index | 1 | 0 | 0 | 0 |
| completed blocks | 0 | 0 | 0 | small RAM32M/LUTRAM allowed |
| **new payload total** | **9** | **0** | **0** | **0 for large payloads** |

Hard stop przed source commit lub full build, jeśli:

- XPM produkcyjny wrapper nie elaboruje się w exact source order;
- jakikolwiek index payload pozostaje tablicą FDRE;
- record payload zawiera RAM64M/RAMD64E albo mniej/więcej niż sześć B18 bez
  wcześniej zatwierdzonego exact packing equivalent;
- odczyt wymaga drugiego portu lub eksportu całej tablicy;
- snapshot mask nie gwarantuje zera dla unused/stale payload;
- test kolizji lub resetu wskazuje rekord/indeks częściowy;
- block accumulator różni się od starego scoreboardu na dowolnym outcome.

## 10. Rekomendacja końcowa

```text
FAILED_RECORD_ARCHITECTURE=6_X_64_X_32_XPM_SDPRAM_BLOCK_COMMON_CLOCK
INDEX_ARCHITECTURE=3_X_512_X_16_XPM_SDPRAM_BLOCK_COMMON_CLOCK
BLOCK_STATS_ARCHITECTURE=30_X_32_DISTRIBUTED_COMPLETED_PLUS_3_LIVE_ACCUMULATORS
MMIO_VISIBILITY=STORED_COUNT_SNAPSHOT_AND_VALID_MASK
COLLISION_MODE=READ_FIRST_WITH_PREFIX_VISIBILITY_PROOF
PAYLOAD_PHYSICAL_RESET=NO
NEW_CDC=NO
SCIENTIFIC_SCOPE_CHANGE=NO
```

To jest wariant zgodny z exact targetem `+9 RAMB18`, zachowuje jednocykliczne
przyjęcie pełnego rekordu, usuwa oba szerokie random-read muxy i nie wymaga
serializera ani dowodu minimalnego odstępu między failed transactions.
