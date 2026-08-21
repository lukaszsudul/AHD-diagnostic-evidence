# Odpowiedź audytora po zablokowaniu P2 (ODIV2)

**Data:** 2026-08-21
**Dotyczy:** `NOTATKA_DLA_AUDYTORA_PO_P2_ODIV2_BLOCKER_2026-08-21.md`,
`P2_ROUTE_FEASIBILITY_REPORT.md`, `vivado.log`
**Zawiera:** korektę diagnozy P2, nową propozycję eksperymentu, nową hipotezę,
odpowiedzi na pytania z §13

---

## 1. Streszczenie

```text
P2_DIAGNOZA_W_RAPORCIE     = BŁĘDNA — poprawka w §2
ODIV2_JAKO_ŚCIEŻKA         = NIE ZAMKNIĘTA, ale nie rekomendowana jako następny krok
REKOMENDOWANY_NASTĘPNY_KROK = BUILD POMIAROWY (licznik wolnobieżny), nie A1
A1_LATE_START              = DOBRY, ale jako krok drugi
NOWA_HIPOTEZA              = margines zasilania / Vcco przy 4,4x większej logice
```

Główna teza tej odpowiedzi: **spór o zegar trwa trzy dni wokół hipotezy, której
nikt nie zmierzył.** A1, A2, B, C i D to warianty zgadywania przez podmianę.
Zjawisko da się zmierzyć wprost, jednym buildem, bez zmiany zachowania.

---

## 2. Korekta diagnozy P2 — to nie ODIV2 się nie zaroutowało

### 2.1 Co mówi log

`vivado.log`, Phase 5 Initial Routing Verification, linie 2797–2805:

```text
CRITICAL WARNING: [Route 35-54] Net: pcie_refclk is not completely routed.

Unroutable connection Types:
----------------------------
Type 1 : IBUFDS_GTE2.O->BUFGCTRL.I0
-----Num Open nets: 1
-----Representative Net: Net[6649] pcie_refclk
-----IBUFDS_GTE2_X0Y0.O -> BUFGCTRL_X0Y18.I0
-----Driver Term: PCIE_REFCLK_IBUF/O
-----Load Term: XDMA/inst/xdma_v41_m1_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/
                inst/inst/gt_top_i/pipe_wrapper_i/cpllpd_refclk_inst/I
```

### 2.2 Co z tego wynika

Nieroutowalne połączenie to **wyjście `O`**, nie `ODIV2`.

Sieć `pcie_refclk` (czyli `O`) nie dotarła do **BUFGCTRL znajdującego się wewnątrz
XDMA** — `cpllpd_refclk_inst`, bufor refclk dla powerdown CPLL. Sieć ODIV2 **nie
figuruje wśród nieroutowalnych w ogóle**.

Wniosek:

```text
XDMA JUŻ używa ścieżki O -> BUFGCTRL.
Konflikt polega na tym, że O i ODIV2 nie mogą jednocześnie sięgnąć
do buforów zegarowych PRZY TYM PLACEMENCIE.
```

To jest ograniczenie zasobowo-placementowe, nie zakaz architektoniczny.

### 2.3 Poprawiona klasyfikacja

Zamiast:

```text
DIRECT_ODIV2_TO_BUFG_PATH = NOT_ROUTABLE_IN_CURRENT_EXACT_XDMA_TOPOLOGY
```

poprawnie:

```text
IBUFDS_GTE2_O_AND_ODIV2_BUFG_CONTENTION = UNRESOLVED_AT_DEFAULT_PLACEMENT
UNROUTABLE_NET                          = pcie_refclk (wyjście O), NIE ODIV2
BLOCKED_LOAD                            = XDMA/.../cpllpd_refclk_inst (BUFGCTRL_X0Y18)
ODIV2_NET_ROUTING                       = NIE ZGŁOSZONE JAKO NIEROUTOWALNE
```

Różnica jest istotna: pierwsza wersja zamyka drogę, druga mówi, że pozostaje
jeszcze jedno posunięcie.

### 2.4 Posunięcie, które pozostaje (ale go nie rekomenduję teraz)

`BUFGCTRL_X0Y18` leży w górnej połowie kolumny buforów. Wymuszenie nowego BUFG
w dolnej połowie (`BUFGCTRL_X0Y0`–`X0Y15`) to **jedna, uzasadniona merytorycznie
próba** z udokumentowanym powodem — nie szukanie po omacku.

To **nie jest** naruszenie zakazów z Waszej §3.3:

```text
to NIE jest CLOCK_DEDICATED_ROUTE=FALSE
to NIE jest ignorowanie DRC
to NIE jest ręczne wymuszanie trasy metodą prób i błędów
to NIE jest automatyczna zmiana LOC
```

To jest planowanie zasobów zegarowych na podstawie odczytanej przyczyny.

**Mimo to nie rekomenduję tego jako następnego kroku** — patrz §3.

---

## 3. Rekomendacja: najpierw zmierzyć, czy zegar pauzuje

### 3.1 Problem z obecnym planem

T4 zamknął pytanie o lifecycle zegara jako `UNKNOWN` dla obu obrazów i tak
zostało. Wszystkie opcje z notatki — A1, A2, B, C, D — testują hipotezę przez
podmianę i dają odpowiedź binarną. Żadna nie mierzy zjawiska.

To można zmierzyć wprost.

### 3.2 Build pomiarowy R1

**Zawartość:** exact formal Phase-2 + wolnobieżny licznik cykli w domenie
autoinit. **Zero zmian funkcjonalnych w stożku NVP.**

```systemverilog
// domena autoinit_clk (obecnie XDMA axi_aclk, 62,5 MHz)
logic [47:0] freerun_cnt = '0;
always_ff @(posedge autoinit_clk)
    freerun_cnt <= freerun_cnt + 1'b1;

logic [47:0] cnt_at_init_done;   // zatrzask na zboczu init_done
```

Oba pola wystawić w telemetrii (istnieją wolne bity w bloku diagnostycznym).

### 3.3 Metoda pomiaru

```text
host zna wall-clock momentu DONE=1   (timestamp z program_hw_devices)
host czyta freerun_cnt z timestampem T0

bez pauzy:   freerun_cnt ≈ (T0 − DONE) × 62 500 000
z pauzą:     deficyt = czas_pauzy × 62 500 000
```

Odstęp `DONE → odczyt` to ~60–90 s (przez warm reboot). **Pauza jednej sekundy
to deficyt 62,5 mln cykli.** Rozdzielczość pomiaru jest o rzędy wielkości lepsza
niż zjawisko, którego szukacie. Niepewność wall-clock rzędu setek milisekund nie
ma znaczenia.

Dodatkowo `cnt_at_init_done` daje drugą informację: ile cykli upłynęło od POR do
zakończenia autoinit. Wartość oczekiwana ≈ 1,81 s × 62,5 MHz. Odchylenie mówi,
czy sama sekwencja przebiegła zgodnie z modelem.

### 3.4 Dlaczego to bije A1

| | A1 late-start | Build pomiarowy R1 |
|---|---|---|
| Odpowiedź | tak / nie | **liczba** |
| Przy FAIL | nie wiadomo dlaczego | wiadomo, że zegar nie pauzuje → hipoteza martwa |
| Przy PASS | nie wiadomo, czy start czy placement | deficyt mówi wprost |
| Zamyka opcje B i C | nie | **tak, jeśli deficyt = 0** |
| Zmiana zachowania | tak | **nie** |
| Koszt | 1 build + 1 run | 1 build + 1 run |

### 3.5 Licznik zostaje jako stała aparatura

Licznik jest **czysto obserwacyjny**. Może zostać w każdym kolejnym buildzie.
Wtedy A1 wykonujecie z aparaturą już na miejscu i **licznik nie jest zmienną
między R1 a R2**.

```text
R1   Phase-2 + licznik                 -> deficyt = ?   (zero zmian zachowania)
R2   R1 + late start 5 s               -> jedna zmienna, z aparaturą w środku
R3   zależnie od wyniku R1/R2
```

Zastrzeżenie metodologiczne, które trzeba przyjąć świadomie: dodanie licznika
zmienia placement, a D1 pokazało, że sama zmiana placementu potrafi zmienić
liczbę NACK dwunastokrotnie. **Nie unieważnia to pomiaru** — deficyt licznika
jest ważny niezależnie od tego, jaki wyjdzie NACK w tym samym runie. Jeśli R1
zawiedzie funkcjonalnie, dostajecie pomiar pauzy podczas przebiegu FAIL, czyli
dokładnie w warunkach, które badacie.

---

## 4. Nowa hipoteza, której nie ma na Waszej liście

**Margines zasilania / Vcco przy 4,4-krotnie większej logice.**

```text
RC-A    2 850 LUT, transport PIO, GT Gen1 x1     -> NACK 0
v41    12 408 LUT + XDMA + GT                    -> NACK 9-36
```

Pull-upy I2C idą do `Vcco` (potwierdzone w T2: R20/R21 = 4,7 kΩ do Vcco 3,3 V).
Przy większym poborze prądu i większej aktywności przełączającej margines VIH się
kurczy.

Zgodność z materiałem dowodowym:

| Obserwacja | Zgodność |
|---|---|
| rozproszone błędy pojedynczych bitów | ✓ |
| brak timeoutów — magistrala działa, gubi bity | ✓ |
| zmienność z buildem: D1 44–67, D2 0, D3 R4 10–15 | ✓ aktywność zależy od implementacji |
| Z9 (synchronizator) nie pomógł | ✓ to margines analogowy, nie próbkowanie |
| zimny start nie pomógł | ✓ zjawisko stanu ustalonego |
| delayed reboot nie pomógł | ✓ |
| RC-A 3/3 PASS na tym samym sprzęcie | ✓ mniejsza logika, mniejszy pobór |

**Nie mam na to dowodu** i bez sprzętu pomiarowego nie da się tego rozstrzygnąć
bezpośrednio. Ale build pomiarowy z §3 daje test pośredni za darmo:

```text
deficyt licznika = 0  AND  NACK > 0
    -> hipoteza zegarowa odpada
    -> hipoteza zasilania/marginesu awansuje na czoło
```

Do dopisania w macierzy hipotez obok Opcji D i E.

---

## 5. Odpowiedzi na pytania z §13

**1. Czy P2 zamyka wyłącznie bezpośrednią realizację ODIV2→BUFG, a nie całą
hipotezę clock/startup?**

Tak, hipoteza clock/startup pozostaje otwarta. Ale P2 zamyka **mniej**, niż
napisaliście — nie ODIV2 okazało się nieroutowalne, tylko `O` przy jednoczesnym
użyciu obu wyjść. Patrz §2.

**2. Czy jako następny test rekomenduję A1 — fixed late-start?**

Jako **drugi** krok, nie pierwszy. Najpierw build pomiarowy z §3, potem A1 z
licznikiem już w środku.

**3. Jaki czas startu w A1: 3 s, 5 s, 10 s?**

5 s jest rozsądnym punktem wyjścia. **Ale z licznikiem będziecie wiedzieli
lepiej** — jeśli deficyt wskaże pauzę trwającą np. 2,4 s, dobierzecie start
ponad zmierzoną wartość zamiast zgadywać. To kolejny argument za kolejnością
R1 → R2.

**4. Czy A2 (link-qualified) jako test drugi, czy pominąć?**

Pominąć na tym etapie. Uzależnienie autoinit od `user_lnk_up` cofa zasadę
autonomii utrzymywaną od freeze v40 (*„NVP POR/autoinit independent of PCIe
user_reset"*). Jako czysty test diagnostyczny dopuszczalne, ale dopiero gdy
R1 i R2 nie dadzą odpowiedzi. Nigdy jako architektura docelowa.

**5. Czy najpierw audit STARTUPE2.CFGMCLK, czy po FAIL A1 od razu do D?**

Ani jedno, ani drugie. Po R1 będziecie już mieli odpowiedź o zegarze, więc
idziecie prosto do D (implementation / I/O margin) albo do hipotezy zasilania
z §4.

**Korekta do Waszej §7.3:** traktujecie tolerancję CFGMCLK jako blokadę. Żaden
z parametrów autoinit **nie jest precyzyjno-krytyczny**:

```text
500 ms reset   przy ±25 %  ->  375-625 ms   akceptowalne
1,5 s start    przy ±25 %  ->  1,13-1,88 s  akceptowalne
~50 kHz SCL    przy ±25 %  ->  38-63 kHz    w granicach trybu standard
```

To czyni Opcję C **bardziej realną, niż ją oceniacie**. Dodatkowo CFGMCLK **nie
konkuruje o zasoby z GT refclk**, więc problem z P2 tam nie występuje. Jeśli
kiedykolwiek wrócicie do niezależnego zegara, C jest technicznie czystsze niż
walka o ODIV2.

**6. Czy shared clocking XDMA jako osobny eksperyment ostatniego wyboru?**

Tak, bez zastrzeżeń. Warunki dopuszczenia z Waszej §6.4 są poprawne i nie mam
do nich uzupełnień.

**7. Czy publikować negatywny wynik P2 jako pełnoprawny artefakt?**

Tak — **z poprawioną klasyfikacją z §2.3**. Negatywny wynik z dokładnie
zidentyfikowaną przyczyną jest wart znacznie więcej niż negatywny wynik z
przyczyną opisaną błędnie. Do pakietu z Waszej §12 dołączyć fragment logu z
§2.1 jako dowód, na czym polegał konflikt.

---

## 6. Rekomendowana kolejność

```text
KROK 0   poprawić klasyfikację P2 (§2.3) i opublikować z fragmentem logu

KROK 1   R1 — build pomiarowy: Phase-2 + licznik wolnobieżny
           zero zmian zachowania
           mierzy deficyt cykli względem wall-clock

KROK 2   interpretacja R1:
           deficyt > 0    -> zegar pauzuje, znana wartość -> R2 z dobranym startem
           deficyt ≈ 0    -> hipoteza zegarowa zamknięta
                             -> D (implementation/IO) albo §4 (zasilanie)

KROK 3   R2 — A1 late start, z licznikiem już w środku (jedna zmienna)

KROK 4   D lub §4, zależnie od wyniku

KROK 5   B (shared clocking) tylko jako eksperyment ostatniego wyboru
KROK 6   E (analog/T3) gdy będzie sprzęt pomiarowy
```

Opcja C przesunięta: rozważyć dopiero, gdy niezależny zegar okaże się potrzebny
**i** R1 pokaże, że pauza istnieje.

---

## 7. Warunki bezpieczeństwa

Bez zmian względem Waszej §11. Podtrzymuję w całości:

```text
świeże ustalenie boot ID, JTAG part/IDCODE/DONE, endpointu, linku, BAR,
  drivera, runtime identity i active image przed jakimkolwiek runem
zero cold startów w zadaniu
zero czynności fizycznych
zero programming retry
zero PCIe remove/rescan/reset
exact pinned XDMA przez /usr/bin/bash
formal Phase-2 restoration na końcu
```

Dodatkowo dla R1:

```text
licznik jest WYŁĄCZNIE obserwacyjny — nie może wpływać na żaden sygnał
  sterujący, reset ani na stożek NVP
zapisać PRZED runem wall-clock DONE=1 oraz oczekiwaną wartość licznika
  przy odczycie, żeby porównanie nie było robione po fakcie
```

---

## 8. Podsumowanie

```text
P2_KLASYFIKACJA          = POPRAWIONA (konflikt O/ODIV2, nie zakaz ODIV2)
NASTĘPNY_KROK            = R1 BUILD POMIAROWY
POWÓD                    = mierzy zjawisko zamiast je podmieniać;
                           zamyka opcje B i C jeśli deficyt = 0
A1                       = krok drugi, z licznikiem w środku
NOWA_HIPOTEZA            = margines zasilania/Vcco przy 4,4x większej logice
NVP_ROOT_CAUSE           = NADAL NIEROZSTRZYGNIĘTA
```

Wynik P2 jest wartościowy i słusznie go zachowujecie. Wymaga wyłącznie
poprawnego opisu przyczyny — a ta jest w logu, w jednym akapicie fazy 5.
