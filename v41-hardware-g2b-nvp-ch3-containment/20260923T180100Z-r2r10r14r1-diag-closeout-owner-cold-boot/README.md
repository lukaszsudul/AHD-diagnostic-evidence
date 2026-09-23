# AHD v41 R2R10R14R1 — diagnostic closeout and Owner-assisted cold start

- Pre-cold diagnostic snapshot persisted outside DUT: 49 MMIO reads, zero writes.
- Autoinit event counters: 17 total (WADDR 4, REGADDR 11, DATA 2, RADDR 0), timeout 0.
- User resources were closed and DMA pending was zero. Normal driver unload was not attempted because remove-path safety at loader lockout was unproven.
- Exactly one normal OS poweroff was dispatched and Owner confirmed completion.
- Owner attested removal of the DUT mains supply for at least 30 seconds. This is not a voltage measurement.
- Boot changed from `f9232944-7167-4d94-bafc-cc702ede4eff` to `72e216ff-6d52-47db-8d2f-f08968fee282` on the same host identity.
- After boot, `10ee:7011` was not enumerated; no XDMA module, nodes, clients, mappings, or AIO were present. No rescan, driver load, JTAG, or MMIO was performed.
- Both task-owned locks were archived and released. I2C-TA1 was not touched.
- R13R2 was not redeployed or identified after power loss. NVP state and camera operation were not tested.
- Historical R14 failure and the unproven physical NACK root cause remain unchanged.
