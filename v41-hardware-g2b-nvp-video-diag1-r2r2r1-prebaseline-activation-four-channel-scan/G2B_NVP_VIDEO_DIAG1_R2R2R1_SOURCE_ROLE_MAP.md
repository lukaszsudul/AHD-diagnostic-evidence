# Published source role map

- R2R2R1 controller, Double-PREPARE wrapper, baseline collector, snapshot
  collector, scan orchestration, and final classifier:
  `sources/controller_nvp_video_diag1_r2r2r1.py`
- authorization sequence and mocked gate:
  `sources/r2r2r1_authorization_sequence.py`,
  `sources/test_r2r2r1_authorization_sequence.py`
- finite capture orchestration: `sources/controller_nvp_capture_r2r2r1.py`
- fixed record validation and reconstruction:
  `sources/validate_nvp_capture.py`,
  `sources/frame_reconstruct_nvp_capture.py`
- private pixel statistics/classification: `sources/analyze_nvp_video_diag1.py`
- result aggregation: `sources/aggregate_nvp_session_metadata.py`
- rolling AIO helper source: `sources/xdma_c2h_rolling_4k_diag1.c`

No native binary, camera pixels, bitstream, DCP, driver, or credential is
published.
