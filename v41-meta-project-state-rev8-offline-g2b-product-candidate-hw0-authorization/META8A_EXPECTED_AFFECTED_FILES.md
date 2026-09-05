# META-8A expected affected files — BEFORE SSOT write

Calculated minimal set equals the exact authorized set: 16 files. TRACK_GATE_ACCEPTANCE is supported by frozen UPDATE_POLICY.md; explicit decision affects these current-state descriptions. R1i is not replaced. GOVERNANCE.md changes only governed-revision metadata; policy, schema, template and governance version remain unchanged.

| Path | Current SHA-256 | Exact reason | Exact section/field |
|---|---|---|---|
| project-current-state/ACTIVE_BASELINES.md | E25125DB6866D306C7930C197459B6736DB1FF70FB18F1BD91F5D9EA7D1414FD | Inventory exact offline test candidate; retain R1i | revision; G2B baseline table; new accepted product test-candidate inventory |
| project-current-state/CHANGELOG.md | 682B1F9648B44D87A3BF812706624BBA68540158159EB6E7EDC321C2B164B2E7 | Append revision-8 transaction | append PROJECT_STATE_REV 8 only; preserve previous bytes |
| project-current-state/COMPATIBILITY_MATRIX.csv | 76D429FBB9C28589079E38817A96657FAB4DC64CDA47FE6B09BBEC9A30864058 | Bind exact PRODUCT to ABI/MMIO and HW0 | G2B/PRODUCT/host rows; new exact candidate compatibility row |
| project-current-state/CURRENT_ARCHITECTURE.md | 55F3C765BB7B7BDF8C4BBD1038F322B44480EA14529E2222E424CEC83DDA0549 | Promote one-channel offline implementation and dual identity | revision; maturity matrix; MMIO/capture/DMA boundaries; Recovery-4 completion; new candidate binding |
| project-current-state/CURRENT_INTERFACES.md | FB391086FB448AFBFF0DC8766BF4FF9C7C89941B02F9A3C9D97ECBCA6219B72C | Record unchanged implemented ABI/MMIO and expected dual identity | revision; runtime identity table; implementation qualifiers; PRODUCT boundary |
| project-current-state/CURRENT_REQUIREMENTS.md | BC4820B32BB83E73F4879916AB42FCCEA1D84939833441D34190CDBFC1DB2684 | Record offline qualification and remaining hardware boundaries | revision; qualification cells; implementation target; profile/sign-off completion |
| project-current-state/CURRENT_RESOURCE_STATE.md | 271F53443B3F063BD1505BFBBD4FB95FB40B0ADED2A8F86DEB8BAA3D64368B0B | Add actual PRODUCT utilization with unchanged thresholds | revision; PRODUCT measured result; pending/estimate qualifications |
| project-current-state/CURRENT_STATUS.md | BB3CF28F8E2AB06B8532838D6FAA2DE6408CBA0E10DACFDDCBE4516EDEC23164 | Accept offline gate and plan separate authorized HW0 | revision; decision basis; gate/maturity tables; resource attainment |
| project-current-state/CURRENT_TRACKS.md | 5CB9898C95BD2E0BE7C137E147D5B0DFAA43DF6A76D4CDBF55E85F22F369A723 | Advance product last/next gate | revision; summary; G-track gates/next decision; META current task |
| project-current-state/EVIDENCE_MAP.md | 20C5E803E922B9056F40849EAE7A41F40DE14D97FD4BF089E5DF81B5BF8259F4 | Bind source/DCP/bitstream and acceptance boundary | revision/current anchor; affected statement rows; Recovery-4 package |
| project-current-state/GOVERNANCE.md | BEA6E809FD76C2D08DCE30B507A58CE1E1F8B88C851B8D9D20E18D381A9E5474 | Synchronize governed revision only | Project-state revision governed 7 to 8; no policy/version change |
| project-current-state/OPEN_DECISIONS.md | 1A0E2F255A156A947E09880DD7FEED8F3A60489E5FC952C17D948871428C3950 | Record unnumbered acceptance and remaining boundaries | revision; OD-05/11/12/13 evidence descriptions; new decision; historical labels |
| project-current-state/PROJECT_STATE.json | B800B561863202A34DA87EE6273F15F65FE1A4A716CDA82AEAC825C3A6AA872E | Apply exact offline candidate and next gate | revision/header; product/meta; implementation/profile/resource/sign-off maturity; candidate inventory; HW0; evidence refs |
| project-current-state/README.md | CDB53488D8F4BCA0BFF933F7593CB1CE5DC61548101E643F00EE717E567243C9 | Update SSOT entry point | revision; snapshot; decision basis; sign-off completion |
| project-current-state/SHA256_MANIFEST.txt | DDC4FA16EDE2FDC350B0DCF2E38B7C29E5C05EF67557B8AEF51B5417B4726E7C | Seal 18 other SSOT files | recompute sorted SHA-256 entries; excludes itself |
| project-current-state/TRACK_STATUS.json | 92A6721670C214B5A178F309518B421412BA60974DA71BD85F6A7502BDBE2144 | Mirror schema-valid accepted offline and planned HW0 | revision/header; product last/next/gates/source/sign-off; meta task |
