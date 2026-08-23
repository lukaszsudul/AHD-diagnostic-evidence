# R4 artifact identity gate

The frozen R3 evidence and both hardware images rehash exactly.

```text
R3_EVIDENCE_COMMIT=f1bf9ed648dc0749fbd2de2ddae38a42917fee9b
R3_EVIDENCE_COMMIT_TREE=b774e6ac5b026700602dbaf78df0cd71c3506e93
R3_EVIDENCE_PACKAGE_SHA256=F6D57CCFD2CF4A7754F9562FDA2BE6BA877A95E2F0E5A4CBAAA0601D32A96782
R3_MANIFEST_ENTRIES=237
R3_MANIFEST_MISSING=0
R3_MANIFEST_MISMATCH=0
R3_MANIFEST_MALFORMED=0
R3_MANIFEST_GATE=PASS

R1E_BIT_FILENAME=ahd_capture_v41_i2c_25khz_r1e_observability.bit
R1E_BIT_SIZE_BYTES=2192144
R1E_BIT_SHA256=0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9
R1E_SOURCE_COMMIT=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
R1E_SOURCE_TREE=db8b5581a237e19905fd01c6d453793047bc3ba7
R1E_ROUTED_DCP_SHA256=1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

FORMAL_BIT_FILENAME=ahd_capture_v41_phase2_p1.bit
FORMAL_BIT_SIZE_BYTES=2192144
FORMAL_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

ARTIFACT_IDENTITY_GATE=PASS
```

The R3 SHA manifest contains the exact R1e reader, host precheck, and read-only JTAG observer. It does not directly contain a write-capable observer, standalone BAR parser, or the remote accepted reader binary. Those are therefore provenance-linked to the immutable accepted R1c/Phase-2 evidence rather than falsely described as R3-manifest entries. The accepted programming Tcl and its parser are copied byte-identically; the separate R4 supervisor only binds the three R4 phase labels to the frozen R1e/formal artifacts and performs the monotonic wait.
