# R10R2 — porównanie czterech wejść (CONT1R3R4R10R2-FOUR-INPUT-READONLY-COMPARISON)

**CH1 wyróżnia się surowym F2/F3 w jedynym odzyskanym skanie, lecz nie w NOVID: wszystkie CH1–CH4 mają NOVID PRE/POST=1/1.** Żaden inny kanał nie zgłosił NOVID=0. F4 na CH1 także różni się od pozostałych; znaczenie elektryczne tych surowych bitów pozostaje UNKNOWN.

## Wynik i bramki

Bramka inżynierska: **FAIL**, ponieważ wykonano tylko jeden z wymaganych pięciu skanów. Bramkę publikacji dowodów ocenia się osobno po odczycie bajtów z przypiętego commita; obecnie jest **PENDING**. Cleanup: **PASS**.

Nowe polecenia SCAN1 ONESHOT: **1/5**; zweryfikowane zamrożone snapshoty: **1/5**; czyste skany potwierdzone ACK: **1/5**. Pierwotny wrapper ukończył **0** skanów. Zatrzymał się po pierwszym ONESHOT generacji 283, przed zapisem raw i ACK, z błędem `AttributeError: 'LiveScanner' object has no attribute 'raw_manifest'`. Zamrożone dane tej samej generacji odzyskano, zweryfikowano i potwierdzono ACK bez nowego START. Oryginalny błąd i hashe jego zapisów zachowano w `FOUR_INPUT_INCIDENT.json`. Nie dopisano brakujących czterech skanów.

W tym pojedynczym snapshocie CH1 ma F0/F2/F3=`0xFF/0x88/0x02`, a CH2–CH4 `0xFF/0x00/0x00`. F2 XOR wynosi `0x88` (bity 7 i 3), F3 XOR `0x02` (bit 1). CH1 F4=`0x39`, pozostałe F4=`0x00`. Historyczne R10R1 CH1 F2/F3=`0xC0/0x03` różni się od bieżącego odczytu i nie jest nowym skanem. Jeden skan nie ustala stabilności w czasie.

Stan incydentu: `RECOVERED_NO_CONTINUATION`. Rzeczywisty format kamery: **UNKNOWN**. Podłączenie do fizycznego wejścia 1 jest deklaracją Ownera. Nie wykonano kontrolowanej zmiany wejścia, więc mapowanie fizyczne na CH1–CH4 nie zostało dowiedzione. Capture dopuszczone/wykonane: **NO/NO**.

## NOVID w odzyskanym skanie

| Skan | Generacja | A8 PRE/POST | CH1 | CH2 | CH3 | CH4 |
|---:|---:|---|---|---|---|---|
| 1 | 283 | 0x0F/0x0F | 1/1 | 1/1 | 1/1 | 1/1 |

NOVID=1 oznacza zgłaszany przez kodek brak wideo. NOVID=0 samo nie potwierdza standardu, rozdzielczości ani fps. Pełne A8 oraz bity w kolejności CH4 CH3 CH2 CH1 są w CSV. Nie ma podstaw do oceny stabilności z wymaganych pięciu skanów.

## Surowe rejestry detektorów

| Skan | Kanał | F0 | F2/F3 |
|---:|---|---|---|
| 1 | CH1 | 0xFF | 0x88/0x02 |
| 1 | CH2 | 0xFF | 0x00/0x00 |
| 1 | CH3 | 0xFF | 0x00/0x00 |
| 1 | CH4 | 0xFF | 0x00/0x00 |

`FOUR_INPUT_DETECTOR_XOR.csv` podaje maski XOR F2/F3 i indeksy różniących się bitów dla CH1 względem CH2, CH3 i CH4. XOR opisuje wyłącznie różnicę surowych bitów. Wspólne bajty Bank0 lock/status są osobnymi kolumnami macierzy skanów. Rejestry prywatne połączono pełnym kluczem (bank, rejestr).

## Zakres i zakończenie

Polecenia ACQ=0; delta funkcjonalnych zapisów NVP=0; otwarcia/żądania/klatki C2H=0/0/0; żądania H2C=0; XSim/budowa/programowanie/reboot=0/0/0/0. Kampania ACQ pozostała zamknięta, sequence=8→8, licznik zapisów funkcjonalnych=10→10. NACK/retry/timeout/błędy banku=0/0/0/0. Nie przepinano kamery, nie zmieniano konfiguracji kodeka ani routingu i nie wykonywano capture. Techniczne operacje START/ACK SCAN1 i wewnętrzny wybór/przywrócenie banku nie są zmianą konfiguracji funkcjonalnej.

START ONESHOT: `2026-09-18T16:43:10.102974234Z` UTC; górna granica czasu błędu wrappera: `2026-09-18T16:43:10.283864829Z` UTC. Zamrożony snapshot odczytano później, `2026-09-18T16:49:00.984337257Z` UTC; to **nie** jest czas ukończenia pierwotnego skanu. Odczyt końcowego idle: `2026-09-18T16:49:00.988667322Z` UTC. Własny sterownik normalnie odładowano, blokady zwolniono. Po odładowaniu nie deklarujemy nowego pomiaru sygnału. Błąd publikacji nie uprawnia do ponownego skanu.

## Integralność danych

Pakiet zawiera 10 plików DUT skopiowanych bajtowo i porównanych z `TRANSFER_VALIDATION.json`. Ścieżki w tym oryginalnym receipcie są względne wobec katalogu DUT; w pakiecie pliki te leżą pod prefiksem `raw/`. Trzy CSV zawierają odpowiednio 4, 1 i 3 rekordy danych; są to częściowe macierze z jedynego odzyskanego skanu, a nie kompletna kampania pięciu skanów. `SHA256_MANIFEST.txt` obejmuje każdy plik pakietu poza sobą. Odczyt zdalny z przypiętego commita jest osobną bramką.
