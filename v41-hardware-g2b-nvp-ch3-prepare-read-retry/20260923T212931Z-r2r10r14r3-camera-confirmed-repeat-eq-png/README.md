# AHD v41 — R2R10R14R3

Owner świeżo poświadczył, że kamera CH3 jest podłączona, zasilona i pozostaje podłączona. Zaprogramowano raz dokładny bitstream R13R2 (`22DACB…716A`) i wykonano jeden warm reboot. Runtime i ABI retry v1 przeszły admission.

Świeży autoinit zakończył się poprawnie: WADDR/REGADDR/DATA/RADDR = `4/6/2/1`, suma 13, timeout 0. Dla porównania zachowane wyniki to `4/11/2/0` (17) oraz `5/11/0/0` (16). Liczniki nie rozstrzygają fizycznej przyczyny.

Jedyny PREPARE zakończył się `PASS_WITH_READ_RETRY`. Pierwszy odczyt PC3, Bank0, `0x02` otrzymał REGADDR_NACK; jedno retry przeszło, a readback był zgodny. Telemetria generacji 1 była kompletna. PC38 przeszedł z F0=`0x34`, więc obecny wynik jest zgodny z hipotezą Ownera o znaczeniu połączenia kamery, ale nie dowodzi historycznego odłączenia.

Jedyny APPLY_A zakończył się terminalem 20: `I2C_DATA_NACK` przy PC120, Bank0B, `0x71`, WRITE `0x6D`. Jest to faza przed końcówką EQ (PC307+). SCAN1, C2H i PNG nie zostały uruchomione.

Dokładny moduł odładowano normalnie, a obie własne blokady zwolniono. Nie wykonano drugiej komendy, aktywacji, cold startu ani buildu. Wynik nie dowodzi fizycznej przyczyny NACK, wykonania EQ, sceny live ani kwalifikacji produktu.
