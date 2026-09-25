# AHD v41 R15R6 — jedna próba pełnego EQ i dziesięciu klatek

## Wynik

Dokładny firmware R15R4R4 został zaprogramowany raz do SRAM; `DONE=1`, wykonano jeden planowany warm reboot, a świeża tożsamość runtime była zgodna. Autoinit zakończył się spójnie z NACK WADDR/REGADDR/DATA/RADDR = 30/35/12/4, suma 81, timeout 0.

FEQ1 ARM przeszedł. Jedno PREPARE zakończyło się `FAIL_TERMINAL`, terminal `0xC3C02202` (17). Spójny rekord twardy wskazał PC23: zapis wartości `0x09` do rejestru bankowego `0xFF`, `I2C_WADDR_NACK`. Wcześniej telemetria retry zarejestrowała i odzyskała jeden NACK dla odczytu PC12, Bank9/0x6A.

Zgodnie z bramką nie wykonano APPLY, pełnego EQ, T0, readera, C2H ani dziesięciu punktów obrazu. Nie powstał PNG. Cleanup przeszedł: własny moduł AHD odładowano, AIO=0, blokady zwolniono. Osobna karta HDMI `10ee:7021` pozostała nietknięta.

## Granice

Jedno odzyskane zdarzenie nie dowodzi ogólnej skuteczności retry. Fizyczna przyczyna NACK nie została ustalona. Nie wykonano pełnego EQ ani kwalifikacji produktu.

## Następna jedna czynność

Przypięty offline review źródeł terminalnej operacji PREPARE PC23 i jej relacji do odzyskanego PC12, bez nowej próby sprzętowej.
