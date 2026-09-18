# CH1 cable retest — CONT1R3R4R10R1-CAMERA-READY-CH1-CABLE-RETEST

## Wynik

**Po zgłoszonej poprawie kabli CH1 nadal nie wykrywa wideo.** W pięciu nowych, czystych skanach A8 PRE/POST wyniosło 0x0F/0x0F, więc CH1 NOVID PRE/POST=1/1 za każdym razem. Wynik kamery: `NO_VIDEO_CH1_AFTER_CABLE_CORRECTION`; zmiana wobec R10: `NO_CHANGE`. Rzeczywisty standard, szerokość, wysokość, tryb skanowania i fps: **UNKNOWN**. Oryginalny dekoder C3 zwrócił `NO_FORMAT_CODE` (`STABLE_NOVID_ONE`); niezależna interpretacja bitu CH1 to stabilny brak wideo. Odbiór klatki wymaga osobnego zadania i ponownej walidacji; w tej sesji capture nie było autoryzowane ani wykonane.

## Bramki i proweniencja

Engineering gate: **PASS** dla ograniczonej diagnozy i cleanup. Evidence publication gate: **oceniany osobno po commit-pinned remote readback**. Owner zgłosił poprawę kabli; konkretny kabel, jego parametry, zasilanie i ustawienie kamery nie były niezależnie mierzone. Zachowano wcześniejsze potwierdzenie znanego toru CH1. DUT `VCDE-DUT-1`, BDF `0000:01:00.0`, boot `0a86ba7c-b382-4c90-b2bd-cce33b8cf56b` i obecny runtime C3 `70266f0b90c6fc6a853495eba1d526b285fd7286` są zgodne z R10. Poprzedni dowód: commit `41bb266b48e319dab722a3faab610dda3443ea36`; poprzednie 20/20 skanów miało CH1 NOVID=1. Poprzednia generacja 277, nowe generacje 278–282. Nowe skany stanowią oddzielną sesję, nie część kwalifikacji 10 000 skanów.

Sterownik AHD miał dokładny SHA-256 `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77` i używał `_user` przypisanego do właściwego BDF. C3 runtime, SCAN1, ACQ, telemetria i W3a przeszły bramkę wejściową; SSOT pozostawał w rewizji 9. Stan ACQ `campaign_closed=true` był oczekiwany i nie blokował niezależnych odczytów. Nie programowano firmware'u.

## Odczyty i format

Wykonano 5/10 dopuszczonych skanów i 5/5 było kwalifikująco czystych: 82/82 wpisów, 10 grup, 105 transakcji, przywrócenie banku PASS, projekcja PASS, brak NACK, retry, timeout i błędów banku. Chronologiczny CH1 NOVID PRE/POST: `1/1, 1/1, 1/1, 1/1, 1/1`. Ostatni skan `2026-09-18T15:49:23.759565719Z`: A8 `0x0F/0x0F`, ID/revision `0x90/0x01`, Bank5/F0=`0xFF`, F2=`0xC0`. Ostatni surowy tuple i pełne odczyty są w profilu, CSV i plikach `raw/`. Stały F0=0xFF przy NOVID=1 nie identyfikuje formatu kamery.

Skompilowane AHD1080p25 i CH1→VDO1 są kontekstem konfiguracji, a nie pomiarem wejścia. Projekcja rejestrów wyjściowych została odczytana, lecz wybór żywego źródła `NOT_CONFIRMED`. W tej krótkiej powtórce nie uruchamiano opcjonalnego obserwatora VCLK/SAV, ponieważ NOVID nie osiągnął stabilnego zera. CAMERA_READY=NO w czasie ostatniego skanu.

## Stan końcowy i granice

ACQ commands=0. `campaign_closed` pozostało true; functional-write counter 10→10, delta 0; command sequence 8→8. Nie było nowych funkcjonalnych zapisów NVP. Dozwolone operacje SCAN1 START/ACK i wewnętrzny wybór/przywrócenie banku nie są zmianą konfiguracji funkcjonalnej. C2H opens/requests/frames=0/0/0, H2C requests=0. Brak DMA, stream enable, XSim, budowy/programowania FPGA, rebootu, resetu, zmian sterownika, kamery, SSOT, META lub PRODUCT.

Końcowy odczyt idle `2026-09-18T15:49:49.724442541Z` potwierdził scanner/ACQ/I²C idle, stream/W3a OFF i niezmieniony stan kampanii. Własny deskryptor `_user` zamknięto, task-owned sterownik normalnie odładowano, blokady DUT i kontrolera zwolniono. Po odładowaniu sterownika kamera nie była ponownie mierzona. Następna brakująca przesłanka: stabilny CH1 NOVID=0, a potem obronne ustalenie rzeczywistego formatu i żywego wyjścia. W tej sesji nie wykonano rollbacku ani żadnej komendy ACQ.

## Integralność dowodów

`raw/` zawiera 22 pliki skopiowane bajtowo z DUT. Każdy rozmiar i SHA-256 ponownie porównano z dwoma receiptami transferu przed utworzeniem pakietu. `TRANSFER_VALIDATION.json` zapisuje zestaw plików i hashe. `SHA256_MANIFEST.txt` obejmuje wszystkie pliki pakietu poza sobą; zdalny odczyt z przypiętego commita jest osobną bramką publikacji. Pakiet nie zawiera pikseli, sterownika, bitstreamu, materiału vendor ani sekretów.
