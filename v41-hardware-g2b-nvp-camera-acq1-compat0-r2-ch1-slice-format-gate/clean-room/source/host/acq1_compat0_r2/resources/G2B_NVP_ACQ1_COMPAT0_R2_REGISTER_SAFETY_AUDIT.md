# G2B NVP ACQ1-COMPAT0-R2 register-safety audit

## Scope

This audit covers only CH1 private Bank5 registers 0x05 and 0x08. It uses the local NVP6134C Rev1.0 PDF, frozen SCAN0/SCAN1 authority, pinned reference commit `081ebbff9a2722d47acf16c680594be43cb179e2`, current v41 source at parent `c7e16fa3da26545cef960a6c75427a3614c4b655`, and prior ACQ1 evidence.

| Register | PDF result | Reference/source result | Classification | Offline decision |
|---|---|---|---|---|
| Bank5/0x05 | The public register table does not define Bank5 private fields; page 50 states that Banks 5-10 are not for users. No write-only or read-side-effect label is provided. | The pinned reference writes 0xA4 and the governed action requires full-byte readback. No accepted source or prior evidence proves a read side effect or write-only behavior. | `UNRESOLVED`; `READ_SIDE_EFFECT_NONE_FOUND`; `WRITE_READBACK_EXPECTED` | May proceed to implementation; actual A/B/prewrite full-byte equality and idempotent write/readback remain hard hardware gates. |
| Bank5/0x08 | The public register table does not define Bank5 private fields; page 50 states that Banks 5-10 are not for users. No write-only or read-side-effect label is provided. | The pinned reference writes 0x50/0x40/0x60. Current v41 initialization also writes Bank5/0x08. No accepted source or prior evidence proves a read side effect or write-only behavior. | `UNRESOLVED`; `READ_SIDE_EFFECT_NONE_FOUND`; `WRITE_READBACK_EXPECTED` | May proceed to implementation; actual A/B/prewrite full-byte equality and idempotent write/readback remain hard hardware gates. |

`FULL_BYTE_READ_EXPECTED` is not asserted offline. Neither register is proven `WRITE_ONLY`, and no read side effect was found. Absence of an adverse finding is not hardware restore authority. The task must stop before a new slice value if three physical full-byte reads disagree or if the idempotent rewrite/readback fails.
