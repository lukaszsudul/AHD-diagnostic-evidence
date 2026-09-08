# Frozen metadata protocol

Mechanism: `FROZEN_BRAM_HEADER_PLUS_DONE_TOGGLE`.

The source freezes trace payload and metadata, writes the internal metadata entry, then publishes a DONE generation toggle. AXI detects the synchronized toggle, reads the metadata entry through the RAM port, caches it, and only then exposes DONE. Test T12 proved stable metadata before DONE and a clean subsequent generation.
