# R14R6 — TEST 2: cold start, świeża aktywacja i ciągły odbiór 11,12 s

## Najważniejsza obserwacja

**Na początku zarejestrowano raster pokazujący otoczenie. Później odebrano kolorową planszę.** Początkowy raster ma **FAIL rygorystycznej kontroli integralności** na granicy klatki; późne klatki mają **PASS**. Obie informacje są częścią wyniku i żadnej nie pominięto.

To istotna obserwacja zmiany widocznej treści w jednej sesji, ale nie dowód miejsca powstania planszy ani mechanizmu usterki. Interpretacja Ownera „na początku rzeczywista klatka, potem coś się psuje i pojawia się syntetyczna” jest zachowana w `RESULT.json` jako hipoteza. Początkowy FAIL nie unieważnia późniejszych poprawnych klatek, a późniejszy PASS nie kwalifikuje wstecz początku.

| Zachowany obraz | Epoka / ramka | Odbiór względem STREAM_ON | Integralność | Treść |
|---|---|---|---|---|
| Pierwszy kompletny raster diagnostyczny | 0 / 5479 | +0,046246214…+0,084607734 s | **FAIL** | Widoczne otoczenie, silne przebarwienia |
| Pierwsza pełna klatka spełniająca strict check | 0 / 5572 | +3,735820342…+3,774180399 s | **PASS** | Znana plansza |
| Klatka około 10 s | 0 / 5729 | +10,015814853…+10,054173247 s | **PASS** | Znana plansza |
| Ostatnia pełna poprawna klatka | 0 / 5755 | +11,055808928…+11,094172181 s | **PASS** | Znana plansza |

Diagnostyczny raster zawiera 1080 rzeczywistych kolejnych linii jednej ramki. Niczego nie dopełniano ani nie łączono między ramkami. Na linii 0 stwierdzono niezgodność source progression: wartość 6027390 zamiast oczekiwanej 6027387. Raster zachowano jako diagnostic-only FAIL, nie jako zakwalifikowaną klatkę live.

Odebrano **300 000 rekordów / 1 228 800 000 B** w jednej ciągłej sesji. Czas readera: **11,118790336 s**; ostatni completion względem T0 przed STREAM_ON: **11,118209040 s**. Ukończono wszystkie zgłoszenia; pending=0, short/failed/duplicate completions=0, maksimum in-flight=1024, descriptor starvation=0.

Parser wykazał **184 pełne poprawne klatki**, 93 odrzucone lub niepełne kandydatury i 94 rekordy z nieciągłością. Wszystkie 184 poprawne rastry mają ten sam SHA-256 co historyczna plansza: `727DACB909C144CAC091A5DCBF31974DE4A11B9BCF273F92DE6AD34DC4821C03`. Pełny indeks czasów i hashy tych klatek znajduje się w `STRICT_FRAME_INDEX.csv`. Pierwszy poprawny raster wystąpił dopiero przy +3,736 s; nie podpisujemy go jako obraz przy 0 s. Nie ustalono dokładnej chwili przejścia w wcześniejszym, niezakwalifikowanym odcinku.

## Aktywacja i konfiguracja

Cold start z fizycznym odłączeniem zasilania został poświadczony przez Ownera przed aktywacją. Następnie wykonano jedno programowanie SRAM dokładnym obrazem R14R5R2 używanym w R14R6 oraz jeden planowy warm reboot. Potwierdzono nowy boot i właściwy runtime. Nie jest to kryptograficzny odczyt całej konfiguracji SRAM ani pomiar napięcia podczas cold startu.

- Źródło: `c05f62d204853f36263b5fd486596abd517f5e92`; tree: `9d35c25b09718057bb100314309006baae8409c5`.
- Bitstream: 2 192 144 B, SHA-256 `989079972C3051E05FC497E98B41A9CFFD1A9B58329338D682C6E98019D29AA1`.
- Autoinit NACK WADDR/REGADDR/DATA/RADDR: **0/0/0/0**, suma 0, timeout 0.
- PREPARE: **PASS_CLEAN**, terminal `0xC3CD0042`, 46 zaakceptowanych transakcji, retry=0, pusty rekord twardy.
- APPLY_A: **PASS_CLEAN**, terminal `0xC3CD0092`, retry=0, pusty rekord twardy. Zachowana końcówka EQ zakończona według loadera; nie jest to pełna adaptacja producenta.
- Jeden świeży SCAN1: **PASS_FRESH_CLEAN_CH3**.

Firmware, driver i binarium readera pozostały niezmienione. Zadaniowy wrapper połączył świeżą konfigurację ze sprawdzonym readerem ciągłego odbioru 300 000 rekordów. Reguł parsera nie osłabiono. Po odbiorze dodano wyłącznie wybór ostatniej poprawnej klatki i osobny eksport wczesnego rastra diagnostycznego.

## Zakończenie i granice

I/O rozliczone, stream OFF, końcowy pending=0, własne dostępy zamknięte i blokady zwolnione. Driver pozostał załadowany, konfiguracja FPGA zachowana. Wykonano jeden istniejący tail flush po drain/OFF. Zachowano końcowy sticky error status=3; moment pierwszej asercji i przyczyna nie zostały ustalone. Nie utożsamiono tego statusu z wynikiem integralności poszczególnych klatek.

Czasy oznaczają odbiór completion na hoście, nie ekspozycję kamery. Widoczna scena w diagnostycznym rastrze nie potwierdza jeszcze poprawnego strumienia live. Plansza nie dowodzi, który blok ją wytworzył. Jedna próba nie wykazuje przyczynowej roli cold startu. Historyczne wyniki pozostają niezmienione.

## Pliki i prywatność

Publiczny pakiet zawiera opis, uporządkowany wynik, czasy, indeks poprawnych klatek oraz hashe. PNG, piksele, raw sesji, pełne logi, firmware i źródła pozostają prywatne zgodnie z dotychczasowym podziałem. Cztery PNG i odpowiadające im oryginalne rekordy/rastry są zapisane na kontrolerze; transfer z DUT zweryfikowano SHA-256. `RESULT.json` zawiera ich nazwy, rozmiary i pełne hashe.

[Przypięty prywatny KIT — wymagany dostęp](https://github.com/lukaszsudul/FPGA_AHD/releases/tag/r14r6-portable-20260926-v1)

Ta publikacja korzysta wyłącznie z zachowanych wyników. Nie wykonano podczas niej nowych operacji na DUT, konfiguracji, odbioru ani buildu. Odczyt bajtów opublikowanego commita jest rozliczany w osobnym lokalnym receipcie, bez samoodwołującego się hasha.
