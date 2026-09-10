# Normative authorization order

Observed order:

1. inherited offline sign-off PASS;
2. exact bitstream identity PASS;
3. controller lock acquired;
4. exact candidate programmed once to SRAM;
5. product-equivalent autoinit PASS;
6. one commanded warm reboot and bounded reconnect PASS;
7. Linux lock acquired and exact driver loaded;
8. PRODUCT and diagnostic read-only identity PASS;
9. pre-baseline transport quiescence PASS;
10. one DIAG CLEAR issued;
11. diagnostic MMIO became unresponsive — HARD STOP.

PREPARE_A/B, scan start, NVP functional writes, and captures were not reached.
