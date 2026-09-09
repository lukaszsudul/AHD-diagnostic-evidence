# Tool and source identity

The complete sanitized text sources are published under `source/`. Exact hashes
of the task-local originals are in `support/TASK_LOCAL_ORIGINAL_SOURCE_SHA256.csv`;
hashes of the sanitized published copies are in `source/SOURCE_SHA256.csv`.

- Native helper source SHA-256: `D0E82EE590C4140892B8562602F0C7DA9F681D9990AF6D2228404BCAF9553EC5`
- Native helper binary SHA-256: `82DDE9C30CAC2985767154733596AF505010FB61927D0B28EAB6B4ED1F9EACF6`
- Native helper binary size: 38296 bytes
- Native helper architecture: x86-64 Linux ELF
- Native helper executable published: NO
- Controller source SHA-256: `33E9ABC2A48FDFCD96ED45E2D10F465FD45FFCF012F5923FDAFA60E8333C83F5`
- Validator source SHA-256: `65BEF1C1AB1E71CA02B30199D4D6D76529AF06E303669900CED90464183948A9`
- Frame tool source SHA-256: `C394C7A212FCE1EC5686878016F887DF02A68C209994A4A2A4681B54FDA89AEF`
- Connection-helper source SHA-256: `09977D93D18706BE1CCF9ED8672B575E9B5A260B0ED30A2FDFEEC0E7B234239E`
- Build-harness source SHA-256: `08CE0D39B11EE4C5B9ADCAB75C705DA3CC3B07ECB2B715A77E7581A6413D8B27`

The helper compiled without warnings using DUT-local GCC 15.2.0 and its
no-device smoke test exited 64 as required.
