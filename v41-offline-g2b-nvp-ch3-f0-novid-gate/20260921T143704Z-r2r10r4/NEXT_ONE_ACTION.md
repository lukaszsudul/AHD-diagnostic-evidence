# NEXT_ONE_ACTION — bounded CH3 detector-readiness window

## Jedna rekomendowana czynność

Po osobnej zgodzie Ownera przygotować **jedną minimalną rewizję loadera**, która
zastąpi pojedynczą twardą bramkę PC307–312 ograniczonym oknem gotowości
detektora. Nie zmieniać profilu, PN, mastera I2C, częstotliwości, retry, DMA,
drivera, trasy ani statycznych readbacków.

## Zamrożony kontrakt propozycji

1. Wejście po poprawnym PC306, przed kontrolą CH2 F0 i przed konfiguracją trasy.
2. Pierwsza próbka po 200 ms; kolejne po 200 ms.
3. Maksymalnie 5 kompletnych próbek i absolutnie 1 200 ms od wejścia.
4. Próbka: Bank0 verify/A8_PRE → Bank7 verify/F0/F2/F3 → Bank0 verify/A8_POST.
5. Sukces: 3 kolejne kompletne próbki z `F0=0x34` oraz A8_PRE[2]=A8_POST[2]=0.
6. Maksymalny koszt: 55 transakcji I2C (15 zapisów wyboru banku, 40 odczytów).
7. F2/F3 zachować raw; bez nowej stałej. Inne kanały nie są bramką CH3; bit1
   zachowuje ochronę CH2.
8. NACK, timeout, błąd banku, statycznego readbacku, CH2, sekwencji albo MMIO:
   natychmiastowy twardy błąd, bez retry, z pierwszym rekordem.
9. Dynamiczne not-ready nie zajmuje pierwszego rekordu. Wyczerpanie daje
   `DETECTOR_NOT_READY_WITHIN_BUDGET`, bez fikcyjnego kontekstu I2C, następnie
   co najwyżej istniejący automatyczny recovery do `CAMP_RECOVERED`.
10. Dopiero po sukcesie wykonać istniejącą ochronę CH2, zapis/readback trasy i
    normalny END. Brak automatycznego PN B, kolejnego APPLY lub capture.

## Minimalna przyszła weryfikacja

W jednym skupionym zestawie XSim: FF→stabilne 34/lock, wyniki przeplatane,
wyczerpanie, NACK w środku, błąd banku, dwie kamery i maski A8, sample-valid,
rekord/MMIO/recovery oraz niezmieniony strumień poleceń poza nowym oknem.

```text
STATUS=DESIGN_ONLY_NOT_IMPLEMENTED
OWNER_AUTHORIZATION_REQUIRED=RTL_MICROCODE_XSIM_BUILD
DUT_AUTHORIZATION=NOT_INCLUDED
```
