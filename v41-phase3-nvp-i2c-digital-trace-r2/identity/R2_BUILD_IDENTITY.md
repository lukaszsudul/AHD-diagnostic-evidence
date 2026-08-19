# Stage B observer R2 build identity

The first authorized observer-only full-build cycle completed successfully. The
source was the sealed, non-Git R2 export derived from the exact accepted
functional commit. No formal-project file was used as a writable build source.

```text
BUILD_TYPE=EPHEMERAL_DIAGNOSTIC_OBSERVER_R2
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
VIVADO_IP_BUILD=6300035
TARGET=xc7a35tcsg325-2
TOP=ahd_capture_top_xdma
BASE_FUNCTIONAL_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
BASE_TREE_SHA=c54368c7e830904505ca58da7bb57ef62c3635dc
OBSERVER_R2_PATCH_SHA256=78C2D4099A20F1A8C81D15CBE7E7AB15E7F041FBA9C03A07AE83593CCD2F0E51
OBSERVER_R2_SOURCE_MANIFEST_SHA256=1A1D02483FA0258E8B40C7AD8A7C62CE7993ADB513F7130FDE5505C4EDD9DF78
R2_LOCAL_BUILD_CYCLES=1
BIT_FILENAME=ahd_capture_v41_NVP_TRACE_R2_ONLY.bit
BIT_SIZE=2192144
OBSERVER_R2_BIT_SHA256=FCAE29F83904F69487545400AB83756ADA9FFC99A78C0A387DD4604A130CD43A
BITSTREAM_GENERATED=YES
DIAGNOSTIC_IMPLEMENTATION_GATE=PASS
```

The R2 identity embedded by the build contains the exact base functional
commit, full observer-patch SHA-256, schema version, and ephemeral/non-release
flags. The image is not a release candidate and does not represent a formal
project commit.

No SRAM programming operation had occurred when this identity was sealed.
