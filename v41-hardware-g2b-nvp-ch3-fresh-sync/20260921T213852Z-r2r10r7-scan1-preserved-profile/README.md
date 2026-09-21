# AHD v41 — CH3 R2R10R7 — świeży SCAN1 na zachowanym profilu A

## Wynik

`CH3_SYNC=CONFIRMED_IN_FRESH_BOUNDED_SCAN1`.

Na niezmienionym boocie `c26ece85-7c4b-447b-8719-6cd82fe5760e` i obrazie R5/R6 wykonano trzy kolejne, kompletne i czyste generacje SCAN1. Każda zwróciła dla CH3 `F0=0x34`, czyli TVI1080p25 według przypiętej referencji, oraz `NOVID03 PRE/POST=0/0`. Wszystkie trzy snapshoty miały `T=105`, `R=0`, 82 ważne wpisy, 10 grup i poprawne przywrócenie banku.

Owner poświadczył dwie podłączone kamery oraz fizyczny CH3 jako badane wejście. To poświadczenie nie zastępuje pomiaru; wynik niżej pochodzi z nowych odczytów CH3/indeksu 2/Bank7 oraz A8[2]. Nie ustalano numeru drugiego fizycznego wejścia.

## Obserwacje

| Skan | Generacja | UTC ONESHOT | T/R | F0 | F2 | F3 | A8 PRE/POST | NOVID03 PRE/POST | Ważność | Restore |
|---:|---:|---|---:|---:|---:|---:|---:|---:|---|---|
| 1 | 1 | 2026-09-21T21:09:10.036392Z | 105/0 | 0x34 | 0xC0 | 0x03 | 0x0B / 0x0B | 0 / 0 | VALID_CLEAN | PASS |
| 2 | 2 | 2026-09-21T21:23:24.433646Z | 105/0 | 0x34 | 0xC0 | 0x03 | 0x0B / 0x0B | 0 / 0 | VALID_CLEAN | PASS |
| 3 | 3 | 2026-09-21T21:23:30.316735Z | 105/0 | 0x34 | 0xC0 | 0x03 | 0x0B / 0x0B | 0 / 0 | VALID_CLEAN | PASS |

Raw i zwalidowane snapshoty zostały zapisane i odczytane bajtowo przed odpowiadającym im ACK. Ich hashe są zgodne z receiptami. Nie wystąpił odzyskany retry ani twardy błąd skanera.

## Korekta hosta bez powtórzenia eksperymentu

Pierwsza próba hostowa zatrzymała odczyt generacji 1 na `FIRST_ERROR_INDEX` pod `0x12028`, ponieważ ogólny logger błędnie uznał prawidłowy sentinel `0xFFFFFFFF` („brak pierwszego błędu”) za utratę BAR. W tym momencie zużyto jeden ONESHOT, nie wysłano ACK, a generacja 1 pozostała zamrożona.

Taskowy odczyt dopuszczono wyłącznie dla `0x12028`. Nie wydano zastępczego ONESHOT dla generacji 1. Ten sam snapshot został zapisany, zwalidowany i dopiero potem potwierdzony ACK. Kolejne ONESHOT utworzyły generacje 2 i 3. Łączny ledger zawiera dokładnie 3 ONESHOT i 3 ACK, zero innych zapisów MMIO. Odstępy ACK→następny ONESHOT wyniosły 240,739 ms i 236,178 ms, więc przekroczyły wymagane 200 ms.

Długa przerwa przed odczytem zamrożonej generacji 1 wynikała z korekty hosta. Nie utworzono w niej nowego pomiaru ani konfiguracji NVP. Trzy generacje są kolejnymi generacjami SCAN1, lecz próbki sekwencyjne nie dowodzą ciągłego locku między nimi.

## Zachowany obraz, profil i trasa

- Source: `bc20bfbde7b5eb9a6d9deec5796651ffa4be0886`, tree `cbf787a8ca3ba71a97fd2175e021fe05e6f61475`.
- Bitstream: `B95F95C9392EE34DE6FDC969B1FF1266C55AA211C1F8523262170D14359389D9`, 2 192 144 B, nadal `EXPERIMENTAL_UNTESTED`.
- Loader przed i po skanach: `0xC3CD0092`, `CAMP_A_DIRTY`, terminal 0, wariant A, F0 0x34, NOVID 0, route flag 1, CH2 impact 0.
- Rekord pierwszej twardej awarii pozostał pusty: `0xF1100000`, `VALID=0`.
- SCAN1 nie wykonał funkcjonalnych zapisów NVP; dozwolone wybory banku zostały przywrócone w każdym skanie.
- Trasa: flaga loadera pozostała prawdziwa, a skompilowany podzbiór profilu widoczny w SCAN1 był zgodny we wszystkich trzech skanach. SCAN1 nie wystawia pełnego niezależnego readbacku trasy, dlatego wynik to `PARTIAL_CONFIRMED`, nie pełna kwalifikacja toru.
- CH2: flaga wpływu loadera pozostała 0. SCAN1 pokazał bieżąco F0 0x34 i NOVID 1/1 dla CH2 we wszystkich trzech snapshotach; to ograniczona obserwacja bez porównywalnego baseline tej sesji i bez kwalifikacji obrazu CH2.

## Cleanup i granice

Ostatni odczyt sprzętu: `2026-09-21T21:23:35.993258+00:00`. Skaner był czysty i idle, loader bez zmian, rekord pusty, stream OFF, transport quiescent, W3a OFF. Dokładny moduł został raz normalnie odładowany; potem nie było bindingu, węzłów, FD, mapowań ani AIO. Zdalna blokada DUT i następnie blokada kontrolera zostały zwolnione. Profil A i obraz pozostawiono bez celowego resetu lub rollbacku; po unloadzie nie wykonywano ponownego odczytu FPGA.

`PREPARE=APPLY_A=APPLY_B=HOST_RECOVER=ACQ=0`. `JTAG=PROGRAM=RESET=REBOOT=POWER_CYCLE=0`. `C2H_OPEN=H2C_OPEN=DMA_TRANSFER=CAPTURE=PNG=0`. Nie wykonano testów offline, buildu ani nowych raportów sign-off.

Zakres niezależności to świeży SCAN1 poza zapamiętanym statusem loadera, z tym samym fizycznym masterem I2C i liniami. Wynik nie dowodzi prawidłowego zliczenia wewnętrznych próbek loadera, ciągłego locku, jakości obrazu ani przyczyny historycznego NACK. Timing/CDC/bus-skew nowego obrazu pozostają bez sign-off; kwalifikacja produktu i dopuszczenie capture nie zostały nadane.

## Pochodzenie publikacji

- R2R10R6 evidence: `10e7d9a6c9feecfa8e44ede8413035cd207cbc73`.
- Pakiet zawiera wyłącznie oczyszczone wyniki; prywatna referencja, pełny profil, mikrokod, binaria i logi systemowe nie są publikowane.
