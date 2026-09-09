
# Camera content decision

FRAME_STRUCTURE = PASS. DIGITAL_BLACK_CLASSIFICATION = EXACT_DIGITAL_BLACK.
LIVE_CAMERA_PIXEL_CONTENT = FAIL_EXACT_BLACK. CAMERA_TEMPORAL_RESPONSE =
NOT_TESTED. NVP_ANALOG_VIDEO_PRESENCE = STATUS_NOT_AVAILABLE.
DOWNSTREAM_DIGITAL_PIXEL_PATH = NOT_TESTED. END_TO_END_CAMERA_IMAGE =
NOT_PROVEN_BLACK_SCENE_OR_FALLBACK.

The selected complete frame (source sequence 311710,
epoch 4, primary records 836..
1915) contains one unique UYVY word and exactly
matches the independent digital-black reference. All 2073600
pixels have Y=16/U=128/V=128; horizontal and vertical edge energy are zero,
and all 1080 scanlines are identical. Literal image inspection found a uniform
black rectangle with no visible object, edge, texture, or brightness variation.

The transport and frame structure remain proven. The cause cannot be separated
among wrong physical connector, no valid analog input, a truly black scene, or
the configured NVP no-video black fallback because the current PRODUCT image
does not expose the needed per-channel NVP status or reversible route service.
