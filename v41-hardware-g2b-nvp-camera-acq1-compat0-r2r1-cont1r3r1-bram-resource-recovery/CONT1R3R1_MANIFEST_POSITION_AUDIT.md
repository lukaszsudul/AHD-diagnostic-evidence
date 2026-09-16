# CONT1R3R1 manifest and position audit

The exact candidate manifest digest is `2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B`; the immutable manifest package SHA-256 is `F21EE3718F84304DD40D29B0A5FE95BBBA15336D9B7BD642177B950CF7598DD6`. `audit_manifest_current.py` loaded and validated all 82 entries and 10 named execution groups, produced the companion CSVs, and verified the clean schedule of 105 transactions.

Actual `VERIFY_GROUP_BANK` boundaries are entries `0,1,4,11,27,37,48,59,70,81`; contiguous-bank-run boundaries are different (`0,27,37,48,59,70,81`). Entry 5 (`Bank0/0xB0`) is position **+1** in G0-LOCK, not +5. Groups G0-ID, G0-LOCK and G0-CH are same-bank reselections. G0-PRE has no valid predecessor bank.

The CSV join retains all ten historical CONT1R2 events, but it is an inherited, event-weighted **static manifest join**, not new hardware data or runtime-verified bank context. Those ten rows are not merged into the new 1,000-scan dataset. This audit makes no first-attempt phase inference from the old status encoding.

The unchanged fixed-master source SHA-256 is `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF`; the unchanged combined-wrapper SHA-256 is `4ADD841745733723B6F19AA445E14AAA117E7D291CEE057AA37C115D3ED287BB`. The scanner leaf itself changed only within the authorized telemetry storage/readout scope and hashes to `D0F54EDA1542E1A7D57004A90DD9B910956000711F125EF7774484E04D78793A`.
