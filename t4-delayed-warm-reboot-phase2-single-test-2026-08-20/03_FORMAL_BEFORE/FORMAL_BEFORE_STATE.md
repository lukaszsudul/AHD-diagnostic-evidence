# Fresh formal before-state

PASS before programming: boot ID `1e4d2733-a37b-4521-9d70-f9a39aa5e078`; one 10ee:7011/10ee:0007 class 058000 endpoint; Gen1 x1; BAR0 128 KiB; BAR1 64 KiB; pinned XDMA runtime and nodes present; BLOCK_ID `0xA40A0C07`; PROTOCOL `0x0000400B`; CAPABILITIES `0x00031002`; diagnostic magic `0x00000000`. Fresh read-only JTAG found one xc7a35t, IDCODE 0362D093, HS2 210241768436, DONE=1.

Two initial software-only JTAG connection attempts stalled before target discovery because no listening hardware server was available. They were terminated and a fresh hidden task-local hardware server was started. The third discovery passed. No programming occurred in those recovery attempts.
