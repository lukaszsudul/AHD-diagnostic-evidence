# Owner authorization

- Contract SHA-256: `25BFCFBBDF19DA4BA9F5BC71956B98434CB7BC11102C3A58FD727CBE000F9B02`
- Existing conditional ACQ1 authorization: `ACTIVATED`
- Missing companion-write authority: `GRANTED`
- Functional scope: `CH1 / Bank 5 / 0x05=0xA4 / 0x08 in 0x50,0x40,0x60`
- Generic host-selected I2C: `PROHIBITED`
- Full mode, EQ, ACP, Bank9, VDO1, BGDCOL, and CH2-CH4 writes: `PROHIBITED`

The grant does not authorize silently replacing either of two incompatible mandatory orderings. The pinned source and the R1 executor contract must first be made mutually consistent.
