# Podsumowanie dla właściciela projektu

Test sprzętowy PoC R1i zakończył się wynikiem **THESIS_CONFIRMED / STRONG_PASS**.

- R1i poprawnie zainicjalizował układ NVP.
- R1i wygenerował prawidłowy obraz wideo.
- R1i miał 0 błędów NACK podczas autoinicjalizacji.
- R1i nie ustawił flagi `INIT_ERROR`.
- Niezmieniony układ kontrolny R1h miał 4 błędy NACK podczas autoinicjalizacji.
- R1h ustawił `INIT_ERROR` i nie wygenerował obrazu.
- Oba warianty miały po 0 NACK w późniejszym teście 30 000 obserwacji faz ACK na wariant.

Wniosek operacyjny: łączna poprawka R1i została potwierdzona jako **kwalifikowana baza PoC** w zamrożonym porównaniu A1/B1. Nie ustalono jednak jednoznacznie, czy decydującym mechanizmem była korekta momentu próbkowania ACK, gotowość układu NVP, czas inicjalizacji, czy kombinacja tych zjawisk.

To nie jest jeszcze kwalifikacja produkcyjna. Nie wykonano kampanii wielu płytek, temperatur, napięć, długotrwałej niezawodności ani pełnej populacji zimnych startów. Weryfikacja formalna pozostaje niewykonana.
