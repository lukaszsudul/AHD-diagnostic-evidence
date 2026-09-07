
# R3R4R5 PCIe, AER, and Kernel Review

- Overall result: `PASS`
- PCIe endpoint/root port stayed Gen2 x1: `PASS`
- New AER counter delta: `NONE`
- New Oops/BUG/call trace/hung task/DMA-API/IOMMU/AER/link/engine fatal: `NONE`
- Kernel taint before/after/final: `12288 / 12288 / 12288`
- Taint disposition: `UNCHANGED`

| Phase | Gate | Taint | Fatal matches | Kernel-log SHA-256 |
|---|---:|---:|---:|---|
| after-bind | PASS | 12288 | 0 | AC3CF4E458E9028686F69A9FB3F76023CCF9DF9F854B51F0A9C52B0A62206953 |
| before-capture | PASS | 12288 | 0 | AC3540B954E325CC86853942F2EE7CE528521E6042B8B9D41EC48538A78020D9 |
| after-capture | PASS | 12288 | 0 | 9A72D1308F6F90CF4EA11947EA9355497517826E47BB43FE553F438BDE8B8B44 |
| before-unload | PASS | 12288 | 0 | EABB04EE0D9836110C8DD409BDA5324E637360C7653806A21E8CA489C6FBBD4C |
| after-unload | PASS | 12288 | 0 | 09AAAF528A2F04DFF1D10C11C731CFB5F9ABC5C62B4C27B1314F2A0CFB150A86 |

Kernel-log bytes are retained privately; public evidence records only hashes
and the reviewed health summaries.
