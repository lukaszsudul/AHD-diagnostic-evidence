# PCB-PIN-1 NVP Shutdown Sequence

## Result

NVP_SHUTDOWN_SEQUENCE = DEFINED

The sequence is logically defined, while exact timings and final rail order remain NVP/regulator-datasheet closure items.

## Required sequence

| Step | Required behavior | Delay classification | Evidence/closure |
|---:|---|---|---|
| 1 | Stop issuing new I2C transactions; complete or safely abort the current transaction. | KNOWN | controller policy |
| 2 | Release SDA and SCL to high-Z. Do not actively drive either line high. | KNOWN | required open-drain behavior |
| 3 | Assert active-low NVP reset while all required rails and the 27 MHz clock are still valid. | KNOWN ordering; FROM_NVP_DATASHEET_REQUIRED timing | confirm reset can be asserted in this state |
| 4 | Hold reset for the datasheet-required assertion interval. | FROM_NVP_DATASHEET_REQUIRED | no value available |
| 5 | Clear the synchronized ODDR run request and wait until A14 is confirmed low after a complete final pulse. | KNOWN | clock gate contract |
| 6 | Disable the NVP rails in the order required by the NVP and regulator datasheets. | FROM_NVP_DATASHEET_REQUIRED | do not assume reverse startup order without evidence |
| 7 | Wait for power-good deassertion and/or validated rail discharge. | FROM_NVP_DATASHEET_REQUIRED; TO_BE_MEASURED | measure residual voltages and discharge time if PG is absent |
| 8 | Maintain EN_VDD1x and EN_VDD3x inactive (LOW under the reviewed active-high assumption), reset low, clock low, and SDA/SCL high-Z for the complete off interval. | KNOWN | confirm power-control polarity; passive PCB defaults plus later RTL contract |

## Back-power constraints

During and after shutdown:

- A14 must not toggle or remain high into an unpowered NVP clock input.
- Reset must not be driven high into an unpowered NVP input; low or high-Z with a pull-down is preferred pending NVP Ioff confirmation.
- SDA/SCL pull-ups must disappear with switched NVP 3.3 V, and FPGA IOBUFs must remain released.
- IRQ must not have a permanent-domain pull that powers the NVP output structure.
- Enable controls must remain at their confirmed inactive level even during FPGA configuration or reset (LOW if the reviewed active-high assumption is confirmed).

If PUDC_B remains low, FPGA configuration pull-ups can reappear on these nets during a later FPGA reconfiguration while NVP is off. The schematic must defeat or isolate those pull-ups where necessary.

## Current implementation gap

The active read-only v40 RTL drives both rail enables high constants. It therefore cannot execute this shutdown sequence. Future governed RTL/XDC work is required only after Owner/Architect acceptance; no source is modified by PCB-PIN-1.
