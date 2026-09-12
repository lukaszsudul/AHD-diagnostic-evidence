# ACQ1-COMPAT0 inheritance

- SCAN0 evidence commit/tree: `b8df33bf813b6e48c757219f27bd4f10b1e8e8c8` / `ea4b2a9f22ec3d14e5f557fed92608c1580f90d6`
- SCAN1-R1R1 evidence commit/tree: `aafd8cc28cbb6035502ccc3de22ccf33b3964f30` / `871725ef88c0216f16eff978c2decbc7377138a0`
- ACQ1-COMPAT0 evidence commit/tree: `96145a89f589b4858c77790746b2e3bf40be9dc4` / `49c12481866d4c7f34a6d70e06d28ebe7ba1485e`
- SCAN1 source parent/tree: `c7e16fa3da26545cef960a6c75427a3614c4b655` / `56526e17154f8e06f3eb4b95233934c18b6ee06e`
- Prior ACQ1-COMPAT0 functional writes: `0`
- Prior hardware state change: `NO`

The prior task correctly identified `Bank5/0x05=0xA4` as inseparable. R1 grants that missing register authority, but its mandatory forward order conflicts with the pinned dynamic NOVID slice branch.
