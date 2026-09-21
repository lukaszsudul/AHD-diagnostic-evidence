# AHD v41 CH3 R2R10R6 — pojedyncza próba eksperymentalnego okna

## Wynik

Dokładny eksperymentalny obraz R2R10R5 został jednokrotnie zaprogramowany do SRAM i aktywowany przez jeden kontrolowany warm reboot. Runtime przeszedł admission. PREPARE oraz jedno APPLY_A zakończyły się powodzeniem.

APPLY_A zakończyło się statusem `0xC3CD0092`: engine done, `CAMP_A_DIRTY`, terminal `0`, wariant A, F0 `0x34`, NOVID `0`, route verified i brak flagi wpływu na CH2. Eksperymentalny loader zgłosił zaliczenie ograniczonego okna detektora. Nagłówek trwałego rekordu odczytany jako pierwszy dostęp po terminalu miał wartość `0xF1100000`, czyli `VALID=0`.

Jest to wynik jednej próby zgłoszony przez loader. Nie wykonano niezależnego SCAN1, odczytu F2/F3 przez host, DMA ani capture. Historia i liczba próbek okna oraz A8 na granicach nie są wystawione ani zachowane. Historyczny `REGADDR_NACK` nie został odtworzony; jego przyczyna pozostaje nieudowodniona.

## Tożsamość

- Source commit: `bc20bfbde7b5eb9a6d9deec5796651ffa4be0886`
- Source tree: `cbf787a8ca3ba71a97fd2175e021fe05e6f61475`
- Bitstream: 2 192 144 B; SHA-256 `B95F95C9392EE34DE6FDC969B1FF1266C55AA211C1F8523262170D14359389D9`
- Boot: `079faad8-c8ee-4c18-9463-b17c901f3235` → `c26ece85-7c4b-447b-8719-6cd82fe5760e`
- BDF: `0000:01:00.0`; user BAR0, długość `0x20000`

## Wykonanie

- SRAM program: 1; warm reboot: 1; pre-activation rmmod/unbind: 0/0.
- PREPARE: 1 zapis; pierwsza odpowiedź `0xC3C00001`; terminal `0xC3CD0042` po 100.458 ms; rekord `EMPTY_VALID0`.
- APPLY_A: 1 zapis; pierwsza odpowiedź `0xC3C00081`; terminal `0xC3CD0092` po 1.047136 s; rekord `EMPTY_VALID0`.
- Autoinit NACK count: 0.
- APPLY_B, host RECOVER, ONESHOT, ACK_CLEAR, dodatkowe skany: 0.
- C2H/H2C, DMA, capture, PNG: 0.
- Nowe testy offline, build i sign-off: 0.

## Cleanup

Ostatni pomiar przed unloadem potwierdził stream OFF, transport quiescent, scanner idle i ten sam terminal loadera. Dokładny własny moduł został normalnie odładowany. Po unloadzie nie było bindingu, węzłów, FD, mapowań ani AIO. Blokada DUT i blokada kontrolera zostały zwolnione. Profil A i obraz w SRAM pozostawiono; po unloadzie nie wykonywano kolejnego odczytu FPGA.

## Zakres dopuszczenia

`QUALIFICATION_SCOPE=SINGLE_EXPERIMENTAL_HARDWARE_ATTEMPT_NOT_PRODUCT`

`INDEPENDENT_CAMERA_SYNC_VERIFICATION=NOT_RUN`

`PRODUCT_QUALIFICATION=NOT_CLAIMED`

`CAPTURE_ADMISSION=NOT_GRANTED`

Następna czynność wymaga osobnej zgody: ograniczona świeża weryfikacja CH3 istniejącym SCAN1, bez ponownego PREPARE/APPLY i bez capture.
