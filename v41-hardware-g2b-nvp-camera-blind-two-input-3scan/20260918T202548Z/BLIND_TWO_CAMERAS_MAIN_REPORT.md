# AHD v41 — ślepy test dwóch kamer, trzy skany

**WYNIK POMIARU: PASS.** Trzy nowe pełne skany SCAN1 CH1–CH4 i trzy czyste ACK.
**PUBLIKACJA DOWODÓW: PENDING_COMMIT_PINNED_READBACK.**

## Odczyty czterech kanałów

| Kanał | NOVID PRE/POST: skany 1,2,3 | F0: skany 1,2,3 | F2/F3: skany 1,2,3 | Reakcja F2/F3 | NOVID PRE=POST=0 |
|---|---|---|---|---:|---:|
| CH1 | 1/1, 1/1, 1/1 | 0xFF, 0xFF, 0xFF | 0x00/0x00, 0x00/0x00, 0x00/0x00 | 0/3 | 0/3 |
| CH2 | 1/1, 1/1, 1/1 | 0x34, 0x34, 0x34 | 0xC0/0x03, 0xC0/0x03, 0xC0/0x03 | 3/3 | 0/3 |
| CH3 | 1/1, 1/1, 1/1 | 0x34, 0x34, 0x34 | 0xC0/0x03, 0xC0/0x03, 0xC0/0x03 | 3/3 | 0/3 |
| CH4 | 1/1, 1/1, 1/1 | 0xFF, 0xFF, 0xFF | 0x00/0x00, 0x00/0x00, 0x00/0x00 | 0/3 | 0/3 |

## A8, generacje i czas UTC

| Skan | Generacja | Początek UTC | Zebrano UTC | ACK UTC | A8 PRE/POST | Integralność |
|---:|---:|---|---|---|---|---|
| 1 | 292 | 2026-09-18T20:31:37.727601427Z | 2026-09-18T20:31:37.913639904Z | 2026-09-18T20:31:37.923935205Z | 0x0F/0x0F | PASS |
| 2 | 293 | 2026-09-18T20:31:38.031484281Z | 2026-09-18T20:31:38.224668198Z | 2026-09-18T20:31:38.240861651Z | 0x0F/0x0F | PASS |
| 3 | 294 | 2026-09-18T20:31:38.351814255Z | 2026-09-18T20:31:38.546440040Z | 2026-09-18T20:31:38.561826141Z | 0x0F/0x0F | PASS |

## Wniosek ślepy

**Wskazana para kanałów logicznych: CH2 + CH3**. Same two channels have nonzero F2/F3 in all three scans; other two show 00/00.
Reagujące kanały według F2/F3: CH2, CH3.
**NOVID=0:** BRAK. NOVID=1 oznacza zgłaszany brak wideo; NOVID=0 samo nie określa formatu.
**Format kamer: NIEPOTWIERDZONY W TYM TEŚCIE.** Surowe F0, w tym ewentualne 0x34, nie potwierdza standardu, rozdzielczości ani fps. Nie wykonano capture.
Kanały odczytywano sekwencyjnie w jednym skanie; snapshot jest spójny, ale nie stanowi równoczesnego próbkowania analogowego czterech wejść.
Numery fizycznych wejść i tożsamości dwóch kamer pozostają nieujawnione; historyczne CH2 nie było wejściem klasyfikacji.
Wynik oryginalnego dekodera, bez zmian: `{"outcome": "SIGNAL_UNSTABLE", "read_only": true, "reason": "NOVID_OR_RAW_TUPLE_NOT_STABLE"}`.

## Tożsamość i zakończenie

- Task: `AHD_V41_BLIND_TWO_CAMERAS_3SCAN_REPO`; DUT `VCDE-DUT-1`, boot `0a86ba7c-b382-4c90-b2bd-cce33b8cf56b`, PCI `0000:01:00.0` (`10ee:7011`, subsystem `10ee:0007`).
- Runtime C3 source commit: `70266f0b90c6fc6a853495eba1d526b285fd7286`; build_flags `2050`. Task-local runner SHA-256: `5B4BC171BB665D8553AEBE9E90B2CC958F0827300F44ACAB399BBCA8D98D30AF`, skopiowany ze sprawdzonego poprzedniego ślepego testu i dostosowany jedynie do identyfikatorów sesji.
- SCAN1: 3 START, 3 ACK; 82/82 wpisy, 10/10 grup, 105 transakcji na każdy czysty skan; retry/NACK/timeout/błędy banku w tej sesji: 0/0/0/0.
- ACQ / funkcjonalne zapisy NVP / DMA: 0 / 0 / 0. W3a i stream pozostały OFF; zamknięta kampania ACQ zachowana.
- Cleanup: normalny idle `PASS`, odładowanie własnego modułu `PASS`, blokada DUT `RELEASED_AFTER_NORMAL_CLEANUP`, blokada kontrolera `RELEASED_AFTER_DUT_LOCK_AND_NORMAL_CLEANUP`.
- FPGA, kod drivera, manifest i konfiguracja NVP: bez zmian. XSim, przebudowa, programowanie i restarty: 0.
- `SCAN_MATRIX.csv` zawiera 12 wierszy danych; `raw/` zawiera oryginalne bajty trzech skanów i stan ukończenia. `SHA256_MANIFEST.txt` obejmuje każdy pozostały plik pakietu.
