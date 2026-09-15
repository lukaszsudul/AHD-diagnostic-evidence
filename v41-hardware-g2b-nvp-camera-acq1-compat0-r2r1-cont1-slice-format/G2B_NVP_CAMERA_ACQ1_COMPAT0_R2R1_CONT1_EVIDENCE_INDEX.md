# Evidence index

This directory is the append-only evidence payload for CONT1. The main report carries the result and causal boundary. Authority, scope, inherited identity, endpoint change, local/DUT identity, bundle, locks, programming, autoinit, reboot, driver, runtime identity, MMIO, scanner, unreached camera/baseline/slice/format phases, rollback disposition, cleanup, gate matrix, state, and SHA-256 manifest are recorded in the correspondingly named files.

Additional exact evidence:

- `G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1_PRE_CAMERA_SINGLE_SCAN.json`: exact persisted read-only SCAN1 snapshot; no pixels or video.
- snapshot JSON SHA-256: `F69884964978A0C793C9C5235C264B1FA88F2B4ADBE37403B1CB27D26555207B`
- snapshot raw-word SHA-256 recorded inside JSON: `5930C78AA52AEC08F09E837D2C1E20EBBB9527A36E49647FACF273F7206D0AD9`

Not published: credentials, credential paths, vendor source, vendor PDFs, FPGA bitstream, routed DCP, XDMA driver binary, camera pixels, raw video, or the raw credential-bearing connection receipts.
