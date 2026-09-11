
# Root cause

`HOST_DEPLOYMENT_MANIFEST_OMITTED_TRANSITIVE_LOCAL_DEPENDENCY`

`validate_nvp_capture_r3r2.py` imports `frame_reconstruct_nvp_capture.py`, which
imports `abi_v1.py`. The R3R2 DUT deployment omitted that final module. R3R2R1
derived the complete transitive closure, included and hash-pinned `abi_v1.py`,
and qualified the same closed bundle locally and on the DUT before hardware.
