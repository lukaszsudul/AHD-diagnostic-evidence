# R1i–R2 Publication Redaction Log

## Policy

Scientific measurements, timestamps needed for sequence, source/bitstream identities, hashes, and acceptance results are unchanged. Publication copies remove personal profile paths, the private DUT address/user/hostname, the unique JTAG target identifier, authentication implementation details, and operational access procedures.

| Public item | Original treatment | Publication treatment | Scientific effect |
| --- | --- | --- | --- |
| Original internal evidence ZIP | Verified but not published | Filename, size, and SHA-256 referenced only | None |
| Qualification report | Sanitized copy | Private host/user/IP replaced by neutral identifiers; transport implementation generalized | None |
| State JSON | Sanitized copy | SSH host/user/hostname and internal lock name generalized | None |
| Hardware transcript | Curated publication copy | Access/authentication and personal-path detail omitted; scientific receipts retained | None |
| Evidence index | Regenerated | Public paths and original/published hashes only | None |
| Original SHA manifest | Filtered publication receipt | Only publication-relevant original identities retained | None |
| Program/DONE receipts | Curated public copies | Unique JTAG target and boot IDs omitted; pass gates and hashes retained | None |
| Raw A1/B1 telemetry | Byte-for-byte copies except extraction receipts | Personal transport-log paths in the two extraction receipts replaced; original hashes embedded | None |
| Raw and statistical CSV | Byte-for-byte copies | No redaction required after scan | None |
| Bitstreams | Byte-for-byte copies in Git LFS | No credential/private-key markers detected | None |

The original internal ZIP (`AHD_v41_R1i_R2_DEPLOYMENT_AND_TEST_20260827T084425Z.zip`, 3,660,287 bytes) has SHA-256 `6341F934D17F790E113C1C3013D9DD78E7387C6AA22469ABA7EB88D10C90519F`. It is not public because it contains credential-handling code, private host/user/address data, pinned-host-key details, personal paths, and detailed transport/JTAG procedures. No private-key payload was detected, but the operational combination is unsuitable for a public repository.

## Transformed-file hash mapping

| Publication file | Original SHA-256 | Published SHA-256 |
| --- | --- | --- |
| `final/AHD_v41_R1i_R2_DEPLOYMENT_AND_TEST_REPORT.md` | `2F5D3DBE79E67A49D5DD5EA6816C4DAA39604F781C0A40D9F17C333475069307` | `ACE0EEC375FC50A2C829909000611BB6621F44B0D5DAAB1EA589322268E9E722` |
| `final/AHD_v41_R1i_R2_DEPLOYMENT_AND_TEST_STATE.json` | `333C9EA53E1F37509DFDD8146F5B84654B0F447F0624AEE53DD1303E0F9BF85E` | `D433115BF0C118CDF74D2A95DB252833DE0CFB76F5076528A9B9BBCF8C83AED1` |
| `hardware/AHD_v41_R1i_R2_HARDWARE_TRANSCRIPT.txt` | `0BF3851C89D1853728C2FCE0EFE4D61F13786CFB0DDAC55878BB31FBAC343279` | `FA071CC82DEFAA02B3F64493EFAA1B46E53A158981815030339EF622FECB7AC8` |
| `raw/A1/LOCAL_EXTRACTION_RECEIPT.json` | `9CBA4C60CA023076D70042B23647C26E204A70943BA469AFAE42CF04CE374116` | `DA5E7C73DDFE5D1ACDDD111E15B1D27E71B355B94BA9B398F31DBF9467280FEC` |
| `raw/B1/LOCAL_EXTRACTION_RECEIPT.json` | `8187707BE6DA321849E2F4A43CC4627B857ACD9E76ED255F1859678DF85804E7` | `A5098598BA2CBD9D5C8D138C33C86DA3C10A9ADB4B69A8E36F3FFF787E3A355C` |
| `final/AHD_v41_R1i_R2_SHA256SUMS.txt` | `4A892793A520C3966B8C99C1D35D6E1A07E46C99591DAFD5E375EF584288A4C7` | `8B03E690EA3F405BBFAB2E72999A6DE9F00BC68C73ACDF40D08706859B78312C` |

Original and published hashes for every transformed file are recorded in [R1I_R2_EVIDENCE_INDEX.md](R1I_R2_EVIDENCE_INDEX.md).
