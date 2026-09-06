# G2B-HW0-PRODUCT-R3 PCIe/AER/kernel review

T0 result: **PASS_WITH_OBSERVABILITY_LIMITATION**

- endpoint/root-port `DevSta`: no correctable, nonfatal, fatal, or unsupported
  request status;
- endpoint/upstream link: stable `5.0 GT/s x1`;
- endpoint/upstream AER sysfs counters: `NOT_EXPOSED`;
- relevant blocking kernel signatures: none observed;
- kernel taint: `0`.

`NOT_EXPOSED` is not zero. After-probe, post-T3, post-T4, post-T5 and
post-unload runtime checkpoints are NOT_REACHED/NOT_APPLICABLE. The final
read-only state again showed Gen2 x1, taint 0, and no recent blocking signature.

