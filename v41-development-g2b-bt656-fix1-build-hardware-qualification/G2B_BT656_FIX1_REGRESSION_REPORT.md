# Regression report

- Captured-pattern vertical-tail: PASS
- Short-tail 0/1/20 and overlong 1101: PASS
- Canonical VBI: PASS
- Deliberate malformed-line behavior: PASS
- Ring-full overflow independence: PASS
- Record ABI identity: PASS
- Full G2B parser/transport: `G2B_ONECH_C2H_XSIM_PASS records=16 bytes=65536 releases=16 expected_queue=16`
- PRODUCT profile: `G2B_PRODUCT_PROFILE_XSIM_PASS checks=37`
- MMIO router: `G2B_MMIO_ROUTER_XSIM_PASS addresses=131072 boundaries=9`
- R1i protected wire semantics: `PASS R1I_FOCUSED_WIRE_SEMANTIC_SUITE`
- R1i candidate/reference semantic SHA-256: `7C5D7F767B2E9CAEB1B587D3F258C295AD0F454141B2A8C84240B966133A4B49`
