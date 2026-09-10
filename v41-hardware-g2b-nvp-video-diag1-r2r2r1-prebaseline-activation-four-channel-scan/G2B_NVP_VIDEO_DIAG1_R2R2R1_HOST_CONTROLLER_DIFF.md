# Task-local host controller diff

The task-local controller was reordered to enforce candidate activation before
Double-PREPARE and to hard-gate START behind baseline PASS. An initially
incorrect task-local read-only autoinit decode was corrected against the frozen
RTL register map: status `0x008C`, NACK `0x0090`, timeout `0x0094`.

No FPGA MMIO definition, PREPARE behavior, snapshot schema, channel order,
BGDCOL assignment, capture format, or classification changed. The exact unified
diff is `supporting/controller_r2r2_to_r2r2r1.diff`.

Final controller SHA-256: `E7E20A40585B329E2BEA4CEEA29817BCBBBFCDEB6599313A7A91D3FE88264D57`
