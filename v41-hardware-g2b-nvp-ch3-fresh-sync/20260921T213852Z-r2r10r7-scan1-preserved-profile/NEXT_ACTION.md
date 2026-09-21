# NEXT_CAPTURE_HANDOFF po R2R10R7

## Ostatni potwierdzony stan

- Obraz: `AHD_v41_CH3_DETECTOR_WINDOW_EXPERIMENTAL_UNTESTED.bit`, SHA-256 `B95F95C9392EE34DE6FDC969B1FF1266C55AA211C1F8523262170D14359389D9`.
- Source/tree: `bc20bfbde7b5eb9a6d9deec5796651ffa4be0886` / `cbf787a8ca3ba71a97fd2175e021fe05e6f61475`.
- Boot: `c26ece85-7c4b-447b-8719-6cd82fe5760e`.
- Loader: `0xC3CD0092`, `CAMP_A_DIRTY`, terminal 0, wariant A, route flag 1, CH2 impact 0.
- Rekord awarii: `EMPTY_VALID0`, header `0xF1100000`.
- Świeży CH3: generacje 1–3 były `VALID_CLEAN`; każda miała F0/F2/F3 `0x34/0xC0/0x03`, A8 PRE/POST `0x0B/0x0B`, NOVID03 `0/0`, T/R `105/0` i restore PASS.
- Trasa: `PARTIAL_CONFIRMED` przez flagę loadera i zgodny podzbiór profilu dostępny w SCAN1; pełny niezależny readback trasy nie jest wystawiony.
- Ostatni pomiar: `2026-09-21T21:23:35.993258+00:00`.
- Cleanup: dokładny driver odładowany, binding/węzły/FD/mapowania/AIO nieobecne, obie blokady zwolnione. Obraz i profil A pozostawiono bez resetu i rollbacku; stanu FPGA nie czytano po unloadzie.

## Następna czynność

Po osobnej autoryzacji zaplanować jedną rzeczywistą klatkę CH3 istniejącym torem AHD/C2H, rozpoczynając od sprawdzenia ciągłości bootu, runtime i bezpiecznego mapowania. Nie wykonywać ponownego APPLY tylko dla odtworzenia tego wyniku. Jeśli boot lub obraz uległy zmianie, nie dziedziczyć profilu A bez ponownej właściwej procedury admission.

Plan capture musi osobno rozliczyć pełną gotowość trasy, stan transportu, kontrakt C2H, granice bufora i zapis danych przed rekonstrukcją PNG. R2R10R7 nie otwierał C2H i nie kwalifikował pikseli.

## Ograniczenia

- Obraz pozostaje `EXPERIMENTAL_UNTESTED`; timing/CDC/bus-skew sign-off nie wykonano.
- Trzy sekwencyjne skany nie dowodzą ciągłego locku między próbkami ani jakości obrazu.
- SCAN1 i loader współdzielą master I2C oraz linie; „świeże” oznacza odczyt niezależny od cache statusu loadera, nie niezależny przyrząd.
- Przyczyna historycznego `REGADDR_NACK` pozostaje nieudowodniona.
- `CAPTURE_ADMISSION=NOT_GRANTED`; następny etap wymaga osobnej zgody Ownera.
