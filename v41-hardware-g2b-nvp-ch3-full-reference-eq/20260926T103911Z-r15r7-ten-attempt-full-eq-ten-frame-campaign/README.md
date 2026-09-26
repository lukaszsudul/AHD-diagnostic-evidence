# R15R7 — zatrzymanie S0, 0/10 nowych prób

Kamera i wyłączne okno restartów zostały potwierdzone przez Ownera. Żadna nowa aktywacja nie została rozpoczęta.

## Wynik inżynierski

**CAMPAIGN_SAFETY_STOP / B_NORMAL_REBOOT_PLATFORM_DMA_IRQ_QUIESCE_NOT_QUALIFIED.**

Zgodnie z §4.2 R15R7 kwalifikacja przejścia między próbami była bramką przed trial_01. Brak dotyczy dowodu normalnej ścieżki restartu z pozostawionym driverem w dokładnym środowisku; nie jest stwierdzeniem, że restart jest uszkodzony lub że występuje aktywne DMA.

- Świeża kontrola potwierdziła stary boot, dokładny driver, brak zaobserwowanych klientów urządzenia i brak błędów odczytu metadanych.
- Wykonano 25 odczytów MMIO S0, bez zapisów. Kanał działał; stream OFF i quiescence potwierdzono w pięciu próbkach. Rekord wcześniejszego APPLY PC70 pozostał spójny. To powtórna obserwacja starego stanu, nie nowa próba.
- Znany lockout loadera nadal nie dopuszcza zwykłego unloadu według zachowanej bramki. Jego wpływ na FEQ1 safe_environment został rozliczony źródłowo i nie jest utożsamiany z aktywnym DMA.
- Dokładne źródła drivera, zgodne z zachowanym manifestem kompilacji, mają remove/error handlers, lecz brak normalnego shutdown callbacka. DMA/IRQ teardown w remove/offline nie został uznany za wykonywany przez zwykły reboot.
- Sprawdzono rzeczywistą recepturę systemową i ustawienia restartu. Ogólny kod Linux v7.0 opisuje zależność od restartu platformy dla zwykłego rebootu; nie jest potwierdzeniem dokładnego kernela dystrybucji i platformy. Pozostała luka dowodowa tej drogi. Brak callbacka sam w sobie nie został uznany za uniwersalny zakaz rebootu.

Driver i obie własne rezerwacje pozostają w maintenance hold, z receiptem przekazania z zakończonego zadania. Bez JTAG, restartu, unloadu, PREPARE, APPLY, EQ, DMA i PNG. Wszystkie 10 prób i 100 planowanych punktów są NOT_RUN_CAMPAIGN_STOPPED; mianowniki nowych wykonań PREPARE/APPLY/EQ wynoszą zero.

## Historia — poza mianownikiem R15R7

| Próba historyczna | PREPARE | APPLY | Autoinit WADDR/REGADDR/DATA/RADDR; suma |
|---|---|---|---|
| R15R6 | PC23 failure; PC12 recovered | NOT_RUN | 30/35/12/4; 81 |
| R15R6R3 | PASS_WITH_READ_RETRY; PC25 recovered | PC70 WADDR_NACK | 18/22/8/1; 49 |

R15R6R2 nie wykonało próby sprzętowej. R15R7 nie uruchomiło nowego autoinit ani nie zmierzyło nowych liczników autoinit.

## Tożsamość i ograniczenia

Firmware, ELF, driver i 52 pliki wydanego hosta pozostają niezmienione. Sprawdzono rzeczywiste hashe lokalne i zdalne. Kampanijny zarządca i jego testy nie zostały uruchomione po pierwszej blokadzie S0; historyczne testy R3 nie są nowymi wynikami R15R7. Pełne logi, środowisko, źródła i raw MMIO pozostają prywatne. Nie badano sceny ani przyczyny fizycznej NACK.

Publikacja append-only jest oddzielnym wynikiem od zatrzymanej kwalifikacji inżynierskiej. Hashy tego pakietu nie używa się jako dowodu bezpieczeństwa restartu.
