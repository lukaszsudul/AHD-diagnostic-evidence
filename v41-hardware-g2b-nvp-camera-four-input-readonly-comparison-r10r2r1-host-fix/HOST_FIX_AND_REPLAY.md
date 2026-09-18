# R10R2R1 — poprawka API hosta i odtworzenie generacji 283

## Przyczyna i zakres korekty

Historyczny wrapper R10R2 `run_four_input_scans.py` miał SHA-256 `6D14A5E805E212A20F5A7FA4BA9B0EA8BD534E71C49E560DC52AD0EF28ED2A00`. Jego linia 268 odwoływała się do `self.scanner.raw_manifest['bank_groups']` po pierwszym ONESHOT. W klasie `LiveScanner` z przypiętego `cont1r3/characterizer.py` (SHA-256 `D24D1A528094C763BDA8E9F3F7E4225EBF9F84CA36A5FF8F98F1441DB1201DF8`) konstruktor zachowuje tylko `entries` i `prohibited`, a nie `raw_manifest`. Stąd `AttributeError` przed utrwaleniem raw i ACK. R10R2 generacja 283 została osobno odzyskana i zamknięta; jej wynik pozostaje historycznym FAIL.

W nowej kopii task-local wrappera manifest jest jawnie ładowany przez istniejące `scan1.manifest.load_and_validate()`. Wrapper porównuje zwrócone `entries` i `prohibited` z danymi utworzonej klasy `LiveScanner`, a nazwy grup bierze z walidowanego dokumentu. Zachowano dotychczasowy odczyt 10 rekordów grup, dekoder, projekcję i bramki przed ACK. Pozostałe zmiany w [WRAPPER_FIX.diff](WRAPPER_FIX.diff) to tylko nowy katalog, task i token sesji. Nie zmieniono przypiętego bundle, manifestu SCAN1, klasy `LiveScanner`, protokołu MMIO ani FPGA.

Nowy wrapper: SHA-256 `1355DEB7300D8AB34DCC4A7A1E3DAA0520683430F055E420FFCD4DF2FD3215CD`. Pakiet 56 plików: ZIP SHA-256 `9BA0A1CD95AF605F1CBBE1D2EB47EBF17E25246897F4029E2923BC983994A69C`.

## OFFLINE_REPLAY

Lokalny test `replay/test_saved_gen283.py` zakończył się `PASS` na dokładnym zapisanym pliku generacji 283 (4200 bajtów, SHA-256 `30FB0F34A892632C5A59BCE6A9F59FE4652FDB6ACC95794787A9750547431B94`). Uruchomił rzeczywistą klasę `LiveScanner` przez fasadę zapisanych słów MMIO, bez otwarcia urządzenia. Sprawdził odczyt, walidację, utrwalenie raw i JSON, cztery wiersze kanałowe, A8 `0x0F/0x0F`, 82 wpisy, 10 grup, 105 transakcji, XOR F2/F3 `0x88/0x02` wobec CH2–CH4, receipt ACK oraz końcową serializację. Dane te są historycznym fixture, a nie nowym skanem DUT.

Syntetyczne błędy zapisu binarnego, brak wymaganej wartości projekcji i zmienną generację przetestowano oddzielnie; każdy dał jeden START, zero ACK i zero następnych START. Syntetyczne maski A8 `0x0F` i `0x0E` sprawdzono tylko jako operacje bitowe. Receipt: `replay/OFFLINE_REPLAY_RECEIPT.json`.

W oryginalnym kodzie produkcyjnym `write_once()` tworzy plik przez `O_EXCL`, wykonuje flush/fsync i odczyt kontrolny SHA przed ACK. Nie używa atomowej zmiany nazwy pliku raw/JSON; `save_state()` używa pliku tymczasowego, `os.replace` i fsync katalogu na Linuksie. Tego mechanizmu nie zmieniano ze względu na zlecony zakres korekty API. Windowsowy test zastąpił tylko `save_state()` odpowiednikiem bez fsync katalogu, którego lokalny Windows Python nie obsługuje; test na DUT ma użyć oryginalnego kodu Linuksowego.

Replay bez urządzenia na DUT: **PASS** z tą samą klasą `LiveScanner`, bez otwierania `/dev/xdma*`; prywatny lokalny log połączenia zachowano poza pakietem, a wynik testu w publicznym `OFFLINE_REPLAY_RECEIPT.json`. Oryginalna ścieżka produkcyjna zapisu stanu wykonała fsync katalogu na Linuksie.

Pięć **nowych** skanów SCAN1 na DUT: **PASS jako obserwacja**, pięć pełnych raw+JSON+ACK, generacje rosnące. Lokalny log połączenia zachowano poza pakietem; publiczne raw, JSON i ACK są w `raw/scans/`. Historyczna generacja 283 nie była liczona. Po skanach SCAN1 pozostał w stanie idle, ACQ nie otrzymał nowych poleceń ani zapisów funkcjonalnych, strumień i W3a pozostały OFF. Normalny unload istniejącego, zgodnego modułu i zwolnienie obu blokad zakończyły się PASS. Dokładne bajty 22 plików skopiowano z DUT, porównano z jego SHA-256 i ponownie odczytano lokalnie; publiczny receipt to `DUT_BYTE_COPY_RECEIPT.json`.

**Engineering gate: FAIL. First blocker: `RAW_JSON_ATOMIC_COMPLETION_NOT_PROVED`.** Produkcyjny `write_once()` zapisał raw i JSON przez `O_EXCL`, flush/fsync oraz odczyt SHA przed ACK, lecz nie nadał im końcowych nazw atomowo. Zlecenie wymagało atomowego zakończenia tych plików przed ACK. Przebieg pięciu skanów i zapisane wartości pozostają rzeczywistymi obserwacjami; nie rozszerzano poprawki wrappera poza autoryzowaną zgodność API i nie uruchamiano kolejnej sesji.

W pięciu odczytach wszystkie kanały miały NOVID PRE/POST `1/1`. CH1 wyróżniały F2 `0xC0,0xC1,0xC0,0xC1,0xC0` i F3 `0x03`, podczas gdy CH2–CH4 miały F2/F3 `0x00/0x00`; F0 wszystkich kanałów wynosiło `0xFF`. Wykrycie formatu standard/rozdzielczość/fps: **UNKNOWN**. Oryginalny dekoder oznaczył tuple jako `SIGNAL_UNSTABLE` z powodu zmian F2; sam NOVID był stale równy `1/1`. Nie dowiedziono fizycznego mapowania kamery przez kontrolowane przepięcie.
