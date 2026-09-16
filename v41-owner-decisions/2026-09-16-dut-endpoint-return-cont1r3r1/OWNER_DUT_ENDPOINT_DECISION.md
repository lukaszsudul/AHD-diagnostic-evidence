# AHD v41 — decyzja Ownera: powrót DUT na 10.132.1.111

DOC-ID: `AHD-V41-OWNER-DUT-ENDPOINT-20260916`  
Data przyjęcia decyzji: `2026-09-16`  
Autor decyzji: Łukasz Suduł — Owner  
Status decyzji: `ACCEPTED`  
Zakres: adres operacyjny DUT i potwierdzenie ciągłości stanu przez Ownera.  
Status publikacji tego pliku: **lokalny dokument do kontrolowanej publikacji; nie jest potwierdzeniem zapisu do repozytorium ani aktualizacji SSOT.**

## Dokładne oświadczenie Ownera

> Mam nową BARDZO WAŻNĄ informację: DUT wrócił do swojego pierwotnego adresu IP (10.132.1.111).
> Uwzględnij to w dokumentacji projektu i prompcie. Stan DUT nie zmienił się po ostatniej naszej sesji (zmiana była tylko dla IP)

Nie podano dokładnej godziny zmiany adresu. Nie należy jej dopisywać.

## Obowiązujący endpoint

- Jedyny aktualnie dozwolony endpoint SSH DUT: **`10.132.1.111:22`**.
- `192.168.1.57:22` jest adresem nieaktualnym dla przyszłych operacji. Nie jest adresem zapasowym, celem ponownego łączenia ani punktem wyjścia do poszukiwania urządzenia.
- Dawny zakaz używania `10.132.1.111`, wynikający z oznaczenia go jako adresu wycofanego, zostaje zastąpiony tą nowszą, jawną decyzją Ownera.
- Nie wolno skanować podsieci, próbować obu adresów ani zmieniać konfiguracji sieciowej DUT.
- Aktualizacja dotyczy wyłącznie DUT. Nie wolno zmieniać adresów innych urządzeń, serwerów JTAG ani usług projektu.

## Ciągłość stanu

Stan wejściowy należy zapisać jako:

```text
DUT_STATE_CONTINUITY: OWNER_ATTESTED_UNCHANGED_EXCEPT_IP
ONLY_OWNER_REPORTED_CHANGE: DUT_IP_ADDRESS
CURRENT_DUT_SSH_ENDPOINT: 10.132.1.111:22
```

Samo przeniesienie adresu nie uzasadnia ponownej szerokiej kwalifikacji środowiska, instalacji sterownika lub narzędzi, przeprogramowania dotychczasowego obrazu FPGA, restartu czy cyklu zasilania.

Pozostają normalne, ograniczone kontrole tożsamości i wyłączności przed nową operacją sprzętową: weryfikacja klucza SSH, hostname, machine-id, boot_id, braku równoległej pracy i właściwego runtime. Nie należy przedstawiać oświadczenia Ownera jako nowego pomiaru sprzętowego ani ponownie prosić Ownera o potwierdzenie już przekazanej informacji.

Oczekiwana stała tożsamość, odziedziczona z wcześniejszych dowodów:

```text
hostname: VCDE-DUT-1
machine-id: 0e90f50d9465492b80258da5658446f8
```

Aktualny boot_id i odczyt runtime należy zapisać z bieżącej, ograniczonej kontroli. Nie wolno wyłączać weryfikacji klucza SSH ani bezkrytycznie usuwać wpisów known_hosts. Sprzeczność tożsamości lub aktywne obce zadanie oznacza zatrzymanie, nie automatyczne nadpisanie.

## Stan prac technicznych pozostaje bez zmian

CONT1R3 zakończył się niezaliczeniem bramki zasobów po optymalizacji: 21 446 LUT wobec limitu 20 384 i pojemności urządzenia 20 800. Nie powstał zatwierdzony bitstream CONT1R3; nie było dostępu do DUT ani skanów kampanii. Źródło: repozytorium `lukaszsudul/AHD-diagnostic-evidence`, commit `e3ef93fb94729fa4051f54c50cc9c193c11704a3`, katalog `v41-hardware-g2b-nvp-camera-acq1-compat0-r2r1-cont1r3-first-attempt-causal-isolation`, raport główny.

Commit źródłowy `dc73d486bf0d68e52dc394dd731031e8598212f5` jest rodzicem rozwoju diagnostyki offline. Nie jest dowodem, że taki obraz pracuje na DUT.

Owner zatwierdził przygotowany zakres CONT1R3R1: korektę pamięci telemetrii do BRAM, uproszczenie odczytu, pełne testy i nowy sign-off, a dopiero po ich zaliczeniu wdrożenie nowego kandydata oraz diagnostyczną kampanię 1000 skanów. Zachowane pozostają komplet 82 wpisów i 10 grup, przyczyna pierwszej próby, pełne timestampy oraz niezmienione zachowanie I²C.

Kamera, slice, MODE1, EQ i capture pozostają poza zakresem. Odrębna bramka 10 000 skanów bez NACK nadal nie jest zaliczona.

## Integracja z dokumentacją projektu

Ten zapis należy opublikować jako nowy, niezmienny dokument decyzji poza `project-current-state/`. Zachować stare raporty i prompty z adresami używanymi w czasie ich wykonania. Nie wykonywać globalnego zastępowania adresów w historii.

Następnie wykonać **odrębne zadanie META** opisane w prompcie CONT1R3R1. Wyłącznie ten blok zawiera `SSOT WRITE AUTHORIZED` i upoważnienie do aktualizacji aktualnego endpointu, oświadczenia o ciągłości oraz obowiązkowych metadanych rewizji i pochodzenia.

Oczekiwana rewizja wejściowa projektu: **8**. Zweryfikować ją przed zmianą. Po prawidłowej, atomowej aktualizacji rewizja wyniesie **9**. Konflikt rewizji jest warunkiem zatrzymania. Samo zapisanie tego lokalnego dokumentu ani jego publikacja poza SSOT nie inkrementuje rewizji.

Gdy istniejący SSOT już podaje adres `10.132.1.111`, nie należy fikcyjnie opisywać zamiany wartości `192.168.1.57` w tym pliku. Należy odnotować bieżące potwierdzenie Ownera i zastąpienie późniejszych, zadaniowych instrukcji używających adresu tymczasowego.

Zmiana rewizji dokumentacji nie oznacza zmiany fizycznego DUT, promocji PRODUCT ani ponownej kwalifikacji historycznych bramek. Po zakończeniu bloku META zadanie techniczne jest ponownie SSOT read-only.
