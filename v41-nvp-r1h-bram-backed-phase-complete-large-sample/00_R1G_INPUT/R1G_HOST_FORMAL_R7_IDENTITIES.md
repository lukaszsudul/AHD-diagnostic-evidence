# Frozen host, formal and R7 input identities

Verification class: fresh read-only P0 file hashing and public commit query.

## Host readers and frozen statistics

The files at exact R1g source commit `e112a5addb7ac62700a9a71af81bf368fad0bada`
match the frozen R1f/R1g evidence identities:

| File | Bytes | SHA-256 | Result |
|---|---:|---|---|
| `scripts/v41/read_nvp_r1f.py` | 46868 | `5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C` | PASS |
| `scripts/v41/r1f_statistics.py` | 38404 | `C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD` | PASS |
| `tests/python/test_nvp_r1f_tools.py` | 17276 | `7AD2E8FA36D685CFC916B007A65BE9B807398A71CB6730E067C31CD9673C52B1` | PASS |
| `tests/python/test_nvp_r1f_tri_phase_probe_model.py` | 10807 | `08AF9824ADD259499946E9EF553D36AB764E0E597568438945D03B20363A8E1E` | PASS |

The 14 entries in the exact R1g inherited-tool binding table were independently
rehash-checked at their absolute paths: `PASS_14_OF_14`, with zero missing,
size-mismatched or hash-mismatched files. Critical reused identities are:

| Tool | Bytes | SHA-256 |
|---|---:|---|
| R7 mode-aware observer | 11334 | `55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7` |
| observer parser | 5102 | `6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66` |
| selected-target selector | 5676 | `3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE` |
| independent DONE reader | 3527 | `122C960412B7A8ADFD2926BE9A863A2786D4D022854AE8A0D56798461E0CD91B` |
| credential/host-key procedure | 10952 | `5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9` |
| Python BAR parser | 3380 | `5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922` |

## Exact formal input

```text
FORMAL_COMMIT=c89e88bcdf389614c884fb129e8b2d42a585bccb
FORMAL_TREE=417820c69c134161fcafae0947dc5976919814d1
FORMAL_BIT_PATH=C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_phase2_p1.bit
FORMAL_BIT_BYTES=2192144
FORMAL_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
FORMAL_BIT_HASH_RESULT=PASS
```

No runtime identity or hardware state was read during P0. Formal Phase 2 is
therefore only an exact file/source input at this point, not freshly confirmed
active hardware.

## R7 historical evidence

```text
R7_EVIDENCE_COMMIT=16beec37a266c421da5838fbb986301d072cbb50
R7_EVIDENCE_TREE=52f722469cace71a5d0de03832e04ea37b67f269
R7_PUBLIC_GIT_API_HTTP=200
R7_EVIDENCE_PACKAGE_PATH=C:\FPGA\V41_NVP_R1E_R7_COMPLETE_MEASUREMENT_EVIDENCE.zip
R7_EVIDENCE_PACKAGE_BYTES=3394246
R7_EVIDENCE_PACKAGE_SHA256=A1864DA7EC52AEE852169656808510C42D98FDCE27816D82449946B610DD2A56
R7_PACKAGE_HASH_RESULT=PASS
```

R7 terminal hardware state remains historical context only.
