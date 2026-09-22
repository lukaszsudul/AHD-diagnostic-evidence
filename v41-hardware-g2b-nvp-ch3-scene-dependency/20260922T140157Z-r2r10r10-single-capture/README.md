# AHD v41 CH3 R2R10R10 — scene-dependency single capture

## Result

A fresh clean SCAN1 passed for CH3 (F0=0x34, NOVID03 PRE/POST=0/0, T/R=105/0, bank restore PASS). One finite C2H session then completed 2500/2500 records with zero pending, short, failed, or duplicate completions. Cleanup passed and the experimental image/profile A were preserved.

One complete 1920x1080 UYVY frame was reconstructed. Its 4,147,200-byte pixel raster is byte-identical to the retained R2R10R8 raster: zero changed bytes and zero changed lines. Visual inspection again shows a repeated color-block mosaic; the declared maintained asymmetric CH3 target is not visible.

SCENE_DEPENDENCE=NO_SCENE_RESPONSE_OBSERVED_PAYLOAD_IDENTICAL.

## Limits

This result shows no observed pixel response to the controlled target in this bounded comparison. The baseline is historical, and the comparison does not by itself distinguish an NVP pattern source, frozen data, or VDO sampling/timing. No new configuration, second capture, FPGA build, sign-off, or product qualification was performed. Pixel data, private profiles, and system logs remain private.

The single proposed next step is a separately authorized, read-only cone audit of the exact R2R10R5 routed DCP from VDO1 inputs through the physical frontend to the G2B payload source.