# R14R6 — przypięty pakiet przenośny v1

Wynik: **PASS pakowania i weryfikacji plików; bez nowego testu sprzętowego**.

Przygotowano prywatny KIT i prywatne GitHub Release `r14r6-portable-20260926-v1` w `lukaszsudul/FPGA_AHD`. Commit pakietu: `f5723ad3cab01350e2f60e55c52387be9613756c`. Źródło firmware'u nadal `c05f62d204853f36263b5fd486596abd517f5e92`; nie zmieniono RTL, XDC, mikrokodu, drivera ani binariów readerów.

[Prywatne wydanie — wymaga dostępu](https://github.com/lukaszsudul/FPGA_AHD/releases/tag/r14r6-portable-20260926-v1)

Archiwum zawiera dokładny bitstream R14R5R2 używany w R14R6 (2 192 144 B, SHA-256 `989079972C3051E05FC497E98B41A9CFFD1A9B58329338D682C6E98019D29AA1`), dwa checkpointy, przypięte źródła i receptury, driver oraz jego upstream/patch, oba warianty readera, moduły/ABI/dekodery, parser i konwerter, narzędzie offline do przygotowania kopii dla stanowiska, instrukcję i hashe.

Zweryfikowano 43 wejścia budowy, 164 pliki payloadu, składnię 60 plików Python oraz relokację na danych przykładowego stanowiska bez dostępu do urządzeń. Niezależny odczyt przypiętego commita porównał 157 plików Git, a ponowne pobranie Release potwierdziło 4/4 załączniki i wszystkie 164 pliki archiwum. ZIP: 86 804 159 B, SHA-256 `77FB9C5BBC81D4DE4178AC98A5D3EDF66B2948B25393AFC2406CB3813B9D0BEB`.

## Granice przenoszenia

Driver jest dla Linux x86_64 `7.0.0-29-generic`. Inny kernel wymaga osobnego przygotowania/kwalifikacji. Hasła, klucze i instalatory nie należą do pakietu. Tożsamość nowego stanowiska i karty wymaga sprawdzenia; zachowane bramki nie są pomijane. Przeniesienie pakietu nie upoważnia do automatycznego uruchomienia na nieustalonym endpoincie.

W bieżącym zadaniu: build=0, kompilacja hosta=0, kontakt z DUT=0, programowanie=0, reboot=0, capture=0. Nie deklarujemy nowej kwalifikacji sprzętu, sceny live ani bajtowej powtarzalności ponownego builda. Historyczne wyniki pozostają bez zmian. Dokładny zachowany `.bit` umożliwia użycie tych samych bajtów bez ponownej syntezy.

Publiczne są wyłącznie ten opis, wynik i hashe. Firmware, checkpointy, kod, prywatne ABI, logi środowiska i piksele pozostają w prywatnym wydaniu. Odczyt tej publikacji po commicie zapisano w osobnym receipcie bez samoodwołania.
