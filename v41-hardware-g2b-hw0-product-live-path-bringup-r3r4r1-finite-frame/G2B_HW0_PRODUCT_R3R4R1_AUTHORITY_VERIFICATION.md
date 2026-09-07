# R3R4R1 authority verification

Result: `PASS` for the offline authority boundary.

- PROJECT_STATE_REV: `8`; META-8A remains authoritative; controlled
  hardware testing is authorized; G2B-HW remains `NOT_PROVEN`.
- Local and remote evidence `main` before publication:
  `2bfcba2476a31a06bdf940881cd5d0a20614333e`.
- R3R3: `VERIFIED` at `6cff7ad374575df84bc7d8794565dbd7d9cd869f`; 98/98 manifest entries and required
  facts verified.
- Failed R3R4: `VERIFIED` at `2bfcba2476a31a06bdf940881cd5d0a20614333e`; 40/40 manifest entries,
  exact assertion blocker, zero DUT connections, and zero hardware operations
  verified.
- PRODUCT source: `integration/v41-g2b-onech-c2h` /
  `92e9b3d914134c044371779def1ee18eaaeda98a` / `cf6bf82249c90782eab1978c68541ed9c0e6430b`; clean and remote-matching.
- PRODUCT bitstream SHA-256: `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`.
- Signed-off DCP SHA-256: `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`.
- Driver authority commit: `9aacc157dab5fe604faf66501b0129613b98ae2d`; sealed controller SHA-256:
  `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`.
- Frozen ABI SHA-256: `AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6`.

Current DUT continuity was not checked after the offline hard stop.
