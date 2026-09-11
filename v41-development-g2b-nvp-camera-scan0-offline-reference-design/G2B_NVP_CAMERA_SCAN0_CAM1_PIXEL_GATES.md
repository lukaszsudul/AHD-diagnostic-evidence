# CAM1 pixel and temporal gates

All gates use decoded real 1920x1080 UYVY bytes after structural record validation.

1. `NOT_EXACT_BGDCOL`: byte array differs from the exact expected constant-color UYVY frame derived from the active BGDCOL register values.
2. `NOT_EXACT_DIGITAL_BLACK`: byte array is not uniformly repeating `80 10 80 10`.
3. `SPATIAL_VARIATION`: luma percentile span `P95(Y)-P5(Y) >= 16` and at least 16 of a 16x9 tile grid have within-tile luma span >= 12.
4. `TEMPORAL_HASH_CHANGE`: SHA-256(frame1) differs from SHA-256(frame2).
5. `CONTROLLED_SCENE_DELTA`: at least 20,736 luma samples (1.0% of 1920x1080) have absolute delta >= 16 after the one controlled scene change.
6. `SECOND_SPATIAL_VALID`: frame2 independently passes gates 1-3.

Passing these gates supports a real, scene-responsive image claim. A uniformly black payload remains diagnostic-only even when record structure is valid.
