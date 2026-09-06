# R3R3 authorization receipt

Owner authority in the R3R3 task granted one exact volatile SRAM programming attempt and one controlled graceful warm reboot; both budgets were consumed exactly once. Flash programming and power-cycle authority were denied. Exactly one driver load and one normal unload were used. PCI rescan, endpoint/root-port reset, new_id, driver_override, manual bind/unbind, persistent driver installation, H2C, and unrelated hardware recovery were not performed.

MMIO reads were restricted to aligned 32-bit words in 0x0000..0x0030, 0x0080..0x00B4, and 0x3800..0x3858. The completed write ledger contains exactly: one RESET_STREAM_STATE, one coherent snapshot request, one enable, and one normal disable. Fatal W1C, nonfatal W1C, statistics clear, safety disable, and unauthorized writes are all zero. One T3 session was started and no retry occurred.

The controller and DUT locks were held through cleanup and released Linux first, controller last.
