# W3 host bundle gate

The current-source **provisional** offline bundle checker passed for 49 files and 27 module origins. It rejected a foreign `10ee:7021` descriptor and a wrong-BDF fake sysfs case without opening a live device. Its manifest SHA-256 is `D9873B0F9155F2EAD3EFC1022CCC71D1C3AD8797EA5B2FA34BFAC4CA67A70354`; `W3_PROVISIONAL_BUNDLE_GATE.json` is the direct receipt.

The final source-frozen release bundle, fresh unpacked-copy check, final bundle file count and manifest SHA-256 are **NONE / NOT_REACHED** because candidate 2 failed the post-opt LUT gate. No private release package was assembled. The provisional PASS does not satisfy the closed runtime-bundle or firmware-delivery gate.
