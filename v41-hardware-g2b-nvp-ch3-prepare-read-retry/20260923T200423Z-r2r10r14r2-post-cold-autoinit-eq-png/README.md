# AHD v41 — R2R10R14R2

Po poświadczonym cold starcie zaprogramowano raz dokładny bitstream R13R2 (`22DACB…716A`) i wykonano jeden warm reboot. Runtime i ABI retry v1 przeszły admission.

Świeży autoinit zakończył się poprawnie. Rozkład NACK zmienił się z `4/11/2/0` (suma 17) na `5/11/0/0` (suma 16); timeout pozostał równy 0. To porównanie liczników nie rozstrzyga fizycznej przyczyny ani wpływu cold startu.

Jedyny PREPARE zakończył się `FAIL_TERMINAL`: `LOADER_ERR_READBACK` przy PC38, Bank7, rejestr `0xF0`, READ=`0xFF`. Telemetria retry v1 była kompletna; nie wystąpił first-attempt NACK, nie przyjęto retry, wszystkie cztery sloty pozostały puste.

APPLY_A/EQ, SCAN1, C2H i PNG nie zostały uruchomione. Dokładny moduł odładowano normalnie, a obie własne blokady zwolniono. Nie wykonano buildu, dodatkowych testów, drugiej komendy ani kolejnej aktywacji.

Wynik nie dowodzi fizycznej przyczyny NACK, skuteczności retry, wykonania EQ, sceny live ani kwalifikacji produktu.
