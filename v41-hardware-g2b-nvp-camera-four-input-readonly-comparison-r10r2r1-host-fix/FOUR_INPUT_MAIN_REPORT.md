# R10R2R1 — pięć nowych porównań wejść CH1–CH4

**Wynik porównania:** 5 utrwalonych nowych skanów, 5 z czystym ACK; bramka inżynierska **FAIL**. Kamera pozostawała na fizycznym wejściu 1 według deklaracji Ownera.

## NOVID i A8

| Skan | Generacja | A8 PRE/POST | CH1 | CH2 | CH3 | CH4 | ACK |
|---:|---:|---|---|---|---|---|---|
| 1 | 284 | 0x0F/0x0F | 1/1 | 1/1 | 1/1 | 1/1 | PASS |
| 2 | 285 | 0x0F/0x0F | 1/1 | 1/1 | 1/1 | 1/1 | PASS |
| 3 | 286 | 0x0F/0x0F | 1/1 | 1/1 | 1/1 | 1/1 | PASS |
| 4 | 287 | 0x0F/0x0F | 1/1 | 1/1 | 1/1 | 1/1 | PASS |
| 5 | 288 | 0x0F/0x0F | 1/1 | 1/1 | 1/1 | 1/1 | PASS |

NOVID=1 oznacza zgłoszony brak wideo. NOVID=0 samo nie rozstrzyga formatu. Dolny półbajt A8 w kolejności CH4 CH3 CH2 CH1 podano w CSV.

## Detektory wszystkich kanałów

| Kanał | NOVID PRE/POST w kolejnych skanach | F0 | F2/F3 w kolejnych skanach | Końcowe F4 | Stabilność NOVID | Stabilność F2/F3 |
|---|---|---|---|---|---|---|
| CH1 | 1/1, 1/1, 1/1, 1/1, 1/1 | 0xFF, 0xFF, 0xFF, 0xFF, 0xFF | 0xC0/0x03, 0xC1/0x03, 0xC0/0x03, 0xC1/0x03, 0xC0/0x03 | 0x00 | STAŁE | ZMIENNE |
| CH2 | 1/1, 1/1, 1/1, 1/1, 1/1 | 0xFF, 0xFF, 0xFF, 0xFF, 0xFF | 0x00/0x00, 0x00/0x00, 0x00/0x00, 0x00/0x00, 0x00/0x00 | 0x00 | STAŁE | STAŁE |
| CH3 | 1/1, 1/1, 1/1, 1/1, 1/1 | 0xFF, 0xFF, 0xFF, 0xFF, 0xFF | 0x00/0x00, 0x00/0x00, 0x00/0x00, 0x00/0x00, 0x00/0x00 | 0x00 | STAŁE | STAŁE |
| CH4 | 1/1, 1/1, 1/1, 1/1, 1/1 | 0xFF, 0xFF, 0xFF, 0xFF, 0xFF | 0x00/0x00, 0x00/0x00, 0x00/0x00, 0x00/0x00, 0x00/0x00 | 0x00 | STAŁE | STAŁE |

Wartości F0/F2/F3/F4/F5/E2/E3/E8/E9/EA/EB dla każdego kanału i skanu są w `FOUR_INPUT_SCAN_MATRIX.csv`; XOR CH1 względem pozostałych w `FOUR_INPUT_DETECTOR_XOR.csv`. Są to surowe bity detektorów, bez przypisywania im formatu.

## Różnica CH1 względem pozostałych

- CH1 kontra CH2: różne F2 lub F3 w 5/5 zapisanych skanów (5/5 całej sesji).
- CH1 kontra CH3: różne F2 lub F3 w 5/5 zapisanych skanów (5/5 całej sesji).
- CH1 kontra CH4: różne F2 lub F3 w 5/5 zapisanych skanów (5/5 całej sesji).

Stabilne NOVID=0: NONE.
Format kamery (standard/rozdzielczość/fps): **UNKNOWN**. Mapowania fizycznego nie dowiedziono, ponieważ nie zmieniano kontrolowanie podłączenia.

Bramka inżynierska FAIL: pliki raw/JSON zapisano przez `O_EXCL` i `fsync` z kontrolą SHA przed ACK, lecz bez atomowego nadania końcowej nazwy. Literalny wymóg atomowego zakończenia tych plików przed ACK nie został wykazany. Pięć odczytów i ACK pozostaje obserwacją.

Wynik oryginalnego dekodera: `{"outcome": "SIGNAL_UNSTABLE", "read_only": true, "reason": "NOVID_OR_RAW_TUPLE_NOT_STABLE"}` (oddzielna obserwacja).

## Bramy, pochodzenie i zakończenie

- Task: `CONT1R3R4R10R2R1-HOST-FIX-FOUR-INPUT-RETEST`; źródło FPGA: `70266f0b90c6fc6a853495eba1d526b285fd7286`; boot: `0a86ba7c-b382-4c90-b2bd-cce33b8cf56b`.
- Host fix i replay: PASS; fixture generacji 283 oznaczono OFFLINE_REPLAY i nie zaliczono do nowych skanów.
- Nowe pełne skany / czyste ACK: 5/5 / 5/5; pierwsza przeszkoda: `RAW_JSON_ATOMIC_COMPLETION_NOT_PROVED`.
- Engineering gate: **FAIL**; evidence publication: **PENDING_COMMIT_PINNED_READBACK**. Publikacja jest osobną bramką.
- Ostatni zapisany skan UTC: `2026-09-18T18:41:34.015368738Z`. Czas cleanup jest odrębnym polem w receiptach.
- Cleanup: PASS; po odładowaniu sterownika nie deklarujemy nowego pomiaru kamery.
- ACQ commands / funkcjonalne zapisy NVP: 0 / 0; C2H/H2C opens: 0/0; klatki: 0.
- FPGA, sterownik, manifest i projekcja: bez zmian. XSim, FPGA build, programming, reset: 0/0/0/0. Capture authorized/executed: NO/NO.
- Pakiet zawiera wyłącznie dane i receipts tej sesji; `SHA256_MANIFEST.txt` obejmuje wszystkie pozostałe pliki. Zdalny odczyt przypiętego commita jest wymagany osobno.
