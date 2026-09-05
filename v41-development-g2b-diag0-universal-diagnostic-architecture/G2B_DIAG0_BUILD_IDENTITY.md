# Unambiguous diagnostic build identity

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


DIAG_ID=0x47414944 (little-endian bytes DIAG);DIAG_VERSION=0x00010000 (MMIO1.0);DIAG_FIRMWARE_VERSION initially1.0. BUILD_PROFILE=3 HW0_DIAGNOSTIC;PRODUCT=1 and RESEARCH_DIAGNOSTIC=2 are distinct identity enums. TRANSPORT_ABI_VERSION=0x00010000 remains independent of record_version00004101 and legacy protocol identity.

Full40-hex SOURCE_COMMIT exposed as five32-bit words: W0=numeric first8hex characters,...W4=last8. Host concatenates each word as8 lower-case hex digits; bus DWORD reads are little endian. SOURCE_COMMIT reset values in JSON are zero placeholders to be replaced by build constants, not a permitted release identity. BUILD_ID_VALID must be build-injected1 only for a clean committed source tree and a full rebuild. The diagnostic derivative SHA does not exist in DIAG0; do not reuse the PRODUCT baseline SHA as the future diagnostic identity.

Use the same generated source-commit constants for legacy GIT_SHA_W0..W4 and diagnostic mirrors, with a build gate checking exact equality. BUILD_FLAGS=0x00000402: bit0 dirty=0;bit1 manifest_verified=1;bit10 HW0_DIAGNOSTIC=1;bit8 PRODUCT andbit9 research=0. This retains g2b_build.tcl provenance semantics while adding the diagnostic bit, with no dirty/sealed-uncommitted fallback. Record actual Vivado version/build in existing identity fields and provenance; do not imply a tool version upgrade here.

Full rebuild from committed derivative source, captured tree/hash manifest and explicit profile. Reject zero identity,dirty tree,identity mismatch,wrong profile or unavailable advertised feature before bitstream. Hash bitstream/DCP after generation and bind them to the committed source and input manifest externally. Do not embed the bitstream's own hash recursively. The current PRODUCT historical embedded224d194e... fingerprint versus approved92e9b3d... source ambiguity is documented reference only; do not propagate that two-level ambiguity into the new image.

Capability bits are in JSON. The maximum designed set includes all13 required functions, but live/four-input/auto/rescan bits remain0 until B1/B2 are authoritatively closed and the implementation verified. Reset does not automatically stream. No diagnostic bitstream or generated identity was produced here.
