# CONT1R1 old projection failure reproduction

- Exact CONT1 controller: `C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1_20260915T154927Z\runtime-bundle\g2b_nvp_camera_acq1_compat0_r2r1_controller.py`
- Controller SHA-256: `33C47010ECF0349FB25220DC063F3C6C997F86378F4BD0F62DEA163FD84269C4`
- Preserved snapshot SHA-256: `F69884964978A0C793C9C5235C264B1FA88F2B4ADBE37403B1CB27D26555207B`
- Result: `R2R1GateError:SCAN1_CONFIGURATION_PROJECTION_INCOMPLETE`
- Missing full keys: `(0x01,0x88),(0x01,0x89),(0x01,0x8A),(0x01,0x8B)`
- Root-cause class: `HOST_CONFIGURATION_PROJECTION_STALE_OR_WRONG_ADDRESS_FAMILY`

This is an offline reproduction against the unmodified CONT1 controller and the exact preserved hardware snapshot. It is not a scanner, I2C, bank-restore, RTL, bitstream, NVP, or camera failure.
