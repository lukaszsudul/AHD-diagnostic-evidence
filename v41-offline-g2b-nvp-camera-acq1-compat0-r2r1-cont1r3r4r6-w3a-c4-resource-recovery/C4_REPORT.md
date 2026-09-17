# AHD v41 W3a C4 — wynik jednej czwartej rewizji offline

**Task:** `CONT1R3R4R6-W3A-C4-RESOURCE-RECOVERY`. Przed wznowieniem wykorzystano 3/4 kandydatów; po tej jednej autoryzowanej próbie wykorzystano **4/4**. Źródło C4 jest przypięte do commitu `9ce74cd76ac33b3d37cde0bced7326a2c31fa0f1`, tree `f7da5163e29477e5c773fce43d657e2a6726cb6e`, na prywatnej gałęzi `codex/v41-w3a-c4-resource-recovery-20260917T205032Z`. Zamrożony manifest 40 wejść budowy ma SHA-256 `0C112E2004EE15B30BD3E4B33092D81B8791C76B61030DCB848FA32B0A30A729`. Niezależny, commit-pinned odczyt opublikowanej gałęzi potwierdził **47/47** plików bajt w bajt.

## Korekta i pomiar

C4 usunął dodatkowy 32-bitowy rejestr danych odczytu oraz cykl `w3_read_pending`; istniejący rejestr odpowiedzi skanera przechwytuje słowo W3a przy przyjęciu odczytu. Dekodowanie 16 rejestrów ograniczono do wyrównanego 64-bajtowego okna, a stronę W3a do dwóch bloków 2 KiB. To była jedna spójna korekta reprezentacji odczytu, bez zmiany formatu rekordu, retencji lub warunku `safe_idle`.

Pomiary **post-opt całego projektu**: C3 20 456 LUT, C4 **20 540 LUT**; zmiana **+84 LUT**, czyli oszczędności globalnej nie uzyskano. Limit wynosi 20 384, zatem C4 przekracza go o **156 LUT**. LUT logic 19 216 (+84), LUT memory 1324 (bez zmiany), FF 21 812 (-21), RAMB36E1 26 i RAMB18E1 4 (bez zmiany). Blok W3a zmalał z 184 do 156 LUT i z 289 do 257 FF, lecz skaner lokalny wzrósł o 25 LUT. W hierarchii najwyższego poziomu bridge AXI-Lite ma +77 LUT, capture +15, a wrapper skaner/ACQ -8; te przypisania są wynikiem mapowania i **nie dowodzą** przyczyny funkcjonalnej w niezmienionych modułach. Wierszy zagnieżdżonych nie sumuje się ponownie. Surowe raporty post-opt i [zestawienie zmian](RESOURCE_DELTA.csv) zachowują liczby.

Status bit 1 ma teraz nazwę **`SCAN_IN_PROGRESS`** w kontrakcie i dekoderze. Jego sprzętowy predykat stanów 1–9 nie został zmieniony; zero tego bitu nie oznacza `SAFE_IDLE`. Sprzętowy warunek `safe_idle` pozostał bez zmian i obejmuje IDLE, przyjęcie skanu, executor/I2C/magistralę, trwającą transakcję, snapshot i pending response. Host nadal sprawdza licznik odrzuconych zapisów. Hash nowego kontraktu: `FAFF9B7638474BFD43E77A7866A337F49B869B36014A3677685E00CACF546424`. Jest to korekta semantycznej etykiety, nie nowa funkcja ani źródło oszczędności LUT.

## Bramki i granice dowodu

Składnia/importy hosta, dokładny kontrakt, statyczna mapa adresów i `git diff --check` przeszły. Synteza ukończyła się z 0 błędów i 0 ostrzeżeń krytycznych; w zmienionym W3a nie pojawiło się ostrzeżenie o szerokości portu, implicit net, obcięciu lub wielokrotnym sterowniku. `opt_design` ukończył się, po czym recepta zatrzymała się dokładnie na `POST_OPT_LUT_GATE_FAILED:20540` (exit code 1). Nie wykonano place, route, pomiarów routed, timing/DRC/methodology/CDC/bus-skew, niezależnego reopen DCP ani bitgen. **Routed DCP: NONE; SHA-256 DCP: NONE; `.bit`: NONE (path/size/SHA-256: NONE).** Wyniki wcześniejszego DCP nie są wynikami C4.

`XSIM_NEW_RUNS=0`; `NEW_RTL_SIMULATION=NOT_RUN_OWNER_REQUESTED_SPEEDUP`; `BEHAVIORAL_ASSURANCE=LIMITED_STATIC_REVIEW_AND_IDENTIFIED_HISTORY`. Kontrola zmienionych ścieżek jest statyczna, nie stanowi dowodu równoważności RTL. Starsze 3755/22505 cykli należą do wcześniejszego źródła; dla C4 wymaganie pauzy 18 750 cykli ma status `STATIC_REVIEW_ONLY`, bez nowego pomiaru. Zamknięty [pakiet hosta](HOST_BUNDLE_MANIFEST.json) obejmuje 7 plików, przeszedł self-test offline z `device_opened=false`, lecz nie jest kwalifikacją sprzętową.

## Dyspozycja

- **Engineering gate: FAIL** — pierwszy blocker `POST_OPT_LUT_GATE_FAILED:20540` wobec limitu 20 384. Budżet 4/4 wykorzystany; piąty kandydat nie jest autoryzowany.
- **Evidence publication:** `PENDING` w tym niezmiennym raporcie do czasu osobnego commit-pinned odczytu bajtów dowodów. Sukces push sam nie jest PASS.
- **Hardware qualification: NOT_RUN.** `DUT_CONTACT=NONE`, `PROGRAMMING=0`, `NEW_HARDWARE_SCANS=0`, `CAMERA_FRAMES=0`; W4 nie rozpoczęto.

Następny krok wymaga nowej jawnej decyzji Ownera o budżecie i zakresie źródłowym, zanim powstanie kolejna rewizja. Nie wolno używać C4 do programowania ani przedstawiać go jako gotowego obrazu diagnostycznego.
