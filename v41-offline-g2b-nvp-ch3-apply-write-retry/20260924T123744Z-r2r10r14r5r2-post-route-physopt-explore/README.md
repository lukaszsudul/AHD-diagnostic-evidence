# AHD v41 — R2R10R14R5R2 post-route phys-opt Explore

## Wynik

`PASS_POST_ROUTE_PHYSOPT_SETUP_HOLD_CLOSED_BITSTREAM_READY`

Jedno `phys_opt_design -directive Explore` wykonane na niezależnej kopii dokładnego routed DCP R14R5 zamknęło setup i zachowało dodatni hold w istniejącym modelu ograniczeń. Wszystkie bramki zadania przeszły, a jeden bitgen zakończył się z obowiązkowym DRC: 0 błędów.

## Tożsamość i niezmienność

- Source commit/tree: `c05f62d204853f36263b5fd486596abd517f5e92` / `9d35c25b09718057bb100314309006baae8409c5`.
- Oryginał i niezależna kopia wejściowego DCP przed i po: 64 022 029 B, `B1AE995CD19BEFA562C7427F9A8DA183CAA0014FBAF1397F218D127519552AF8`; różne identyfikatory plików, brak hardlinku.
- Zmiany źródeł produktu i constraints: 0. Tracked worktree nadal ma wskazany commit/tree i brak różnic.
- Vivado: 2025.2, SW Build 6299465; part `xc7a35tcsg325-2`, top `ahd_capture_top_xdma`.

## Jedyna modyfikacja implementacji

- `phys_opt_design -directive Explore`: 1 próba, post-route, PASS, 203,734 s.
- `synth_design` / `opt_design` / `place_design` / osobne `route_design`: 0 / 0 / 0 / 0.
- Podsumowanie phys-opt: 0 dodanych i 0 usuniętych komórek, 9 zoptymalizowanych komórek/sieci, 1 iteracja; log wskazuje przemieszczenia wybranych rejestrów i poprawę krytycznych ścieżek.
- Nowy checkpoint zapisano przed parserami i bitgenem.

## Bramki końcowe

| Bramka | Wejście | Po phys-opt | Wynik |
|---|---:|---:|---|
| WNS / TNS | -0,149 ns / -1,362 ns | +0,057 ns / 0,000 ns | PASS |
| WHS / THS | +0,036 ns / 0,000 ns | +0,036 ns / 0,000 ns | PASS |
| Setup / hold failing endpoints | 17 / 0 | 0 / 0 | PASS |
| Pulse width failing endpoints | — | 0 (WPWS/TPWS 0) | PASS |
| Slice LUT | 19 927 | 19 929 / 20 800 | PASS, zapas 871 |
| Routing | 40 037 / 40 037 | 40 045 / 40 045; partial/unrouted/error 0/0/0 | PASS |

Końcowy `report_timing_summary -delay_type min_max` objął cały zachowany model: 66 831 endpointów setup, 66 142 hold i 24 787 pulse width. Raport stwierdza spełnienie wszystkich zadanych ograniczeń czasowych w tym modelu.

## Rodziny SRC_COMMIT

- `F1_DROP_CE`: rozliczono 16/16 endpointów. Najgorszy endpoint-wide setup/hold: +0,057/+1,756 ns; dla zachowanego historycznego startpointu: +0,060/+2,687 ns.
- `F2_DESC_EPOCH_CE`: rozliczono 1/1 endpoint. Najgorszy endpoint-wide setup/hold: +0,377/+1,108 ns; dla zachowanego historycznego startpointu: +0,377/+2,771 ns.
- Migawki 11 zegarów przed/po są identyczne, ręczne zmiany modelu: 0. Endpoint-wide najgorsza ścieżka może po optymalizacji należeć do innej prawidłowej relacji zegarowej; źródłowo wskazane pary pozostają `nvp_vclk1 -> nvp_vclk1`, requirement 6,734 ns.

## Bitgen i artefakty

- Bitgen: 1 próba, PASS, 79,768 s; wewnętrzny DRC 0 błędów; 0 warning/critical/error w oknie bitgenu.
- Post-physopt DCP: `17788949` B, `E5130AF6AF7338B9D7D53C2395163F72D8936DFC76DD8B8E3E268BCEE12CBA3C`.
- Nowy bitstream: `2192144` B, `989079972C3051E05FC497E98B41A9CFFD1A9B58329338D682C6E98019D29AA1`.

## Komunikaty i granice

Phys-opt zgłosił 0 warning/critical/error. W pełnym logu sesji pozostało 40 zwykłych ostrzeżeń: 34 pochodziły z pierwszego celowanego raportu z niezgodnymi opcjami prezentacji; raport naprawiono na tym samym zachowanym stanie, bez ponowienia phys-opt ani globalnego STA. Pozostałe obejmują przypomnienie `set_bus_skew`, dwie informacje o wielu zegarach, konflikt nazwy strategii i dwa poprawne wyniki „no negative paths”. Nie było ERROR/FATAL/CRITICAL WARNING.

To jest zamknięcie setup/hold w istniejącym modelu ograniczeń. Nie wykonano pełnego CDC, bus-skew, methodology, testów funkcjonalnych ani formalnej równoważności. Znane granice zewnętrznych opóźnień I/O pozostają widoczne. Skuteczność eksperymentalnego retry zapisu, zachowanie prywatnych rejestrów NVP, fizyczna przyczyna NACK i działanie kamery nie zostały sprawdzone. DUT pozostał nietknięty.

## Publikacja

Docelowy katalog append-only: `v41-offline-g2b-nvp-ch3-apply-write-retry/20260924T123744Z-r2r10r14r5r2-post-route-physopt-explore/`. Commit i commit-pinned readback są zapisywane w lokalnym `reports/PUBLICATION_RECEIPT.json`, aby nie tworzyć samoodwołania w opublikowanych bajtach.
