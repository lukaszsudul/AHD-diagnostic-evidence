# Independent semantic CDC audit receipt

Verdict: **FAIL — NVP_DIAG1_R2_UNRECONCILED_CDC_SOURCE_FAMILY**.

An independent parse reproduced 423 CDC-1 Critical, 2 CDC-10 Critical,
2 CDC-13 Critical, 13 CDC-6 Warning and 861 CDC-15 Warning rows. It confirmed
302 changed CDC-1 physical sources, 220 changed Warning physical sources,
identical destination/non-source multisets, 7 cross-base Critical rows and
3 cross-base Warning rows.

The first cross-base Critical row is `CDC1-CHG-0286`:
`release_epoch_axi_reg[0][9]/C` to `axis_slot_reg[1]/C`, destination
`G2B_ONECH_C2H/enable_applied_source_reg/D`.

The categorical R2 prohibitions against different bus-base normalization and
different semantic source bases apply before any optional cone argument. The
audit therefore confirms that cone evidence cannot override this hard failure.

- PRODUCT CDC report SHA-256: `E53EF11E9A2F5FB1B03B0349203E9D220B999B415EF59B183AD59B6E71025A7E`
- Diagnostic CDC report SHA-256: `9230295088266BFB4503C575C6C46779A2F7EA1367D23A62AADD5125158D72AB`
- PRODUCT CDC-1 manifest SHA-256: `A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D`
- Diagnostic CDC-1 manifest SHA-256: `BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99`
