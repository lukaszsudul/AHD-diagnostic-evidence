# EQ scope disposition

`eq_init_each_format()` is called by `nvp6134_set_chnmode()` for every non-NOVIDEO mode. For AHD1080p25, the extracted initial subset has `9` semantic entries: select Bank `5+CH`, write `0x59=0x11`, set software EQ stage 0, write `0xC0=0x17`, `0xC1=0x13`, `0xC8=0x04`, then select Bank A/B and write the channel EQ source selector `0x74/0xF4=0x02`.

Disposition:

- `EQ_INIT_REQUIRED_FOR_FIRST_IMAGE`: retained in ACQ1, but blocked pending NVP6134C compatibility evidence.
- `EQ_RUNTIME_ADAPTATION_DEFERRED`: cable-length/stage selection in `nvp6134_set_equalizer` and `eq_common.c` is not required for the first bounded image proof.
- `EQ_RECOVERY_DEFERRED`: `eq_recovery.c` is outside first-image scope.

No infinite or autonomous EQ loop is permitted.
