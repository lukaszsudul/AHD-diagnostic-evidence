# CONT1R3 source authority

- Isolated branch: `diag/v41-g2b-nvp-camera-cont1r3-first-attempt-20260916T064015Z`
- Parent: `dae2aff60141ecdbc0afac08fc0df9a3166f66c6`, tree `21e33d481ef637667756caa8015e7fa1b1dd8ebf`
- Frozen diagnostic commit: `dc73d486bf0d68e52dc394dd731031e8598212f5`, tree `f86fcbc15f9a279ae81e689b49c5a7e9ade87602`
- Primary worktree and PRODUCT branch were not edited. The isolated source worktree contains an untracked simulation output directory, excluded from the commit.
- Master SHA-256: `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF`; manifest package SHA-256: `F21EE3718F84304DD40D29B0A5FE95BBBA15336D9B7BD642177B950CF7598DD6`. Both are unchanged relative to parent.
- Immutable CONT1R1 projection module SHA-256: `46DD0D28658190FC7DDF66D60DEB525F187B23DAAAB35C4FB24EC405E0B5D1C9`; schema SHA-256: `279DDC264DA1F89E8EBA00EE23FC581DC34080A3C847CD3EFD9D51A85900CC67`. Both are byte-identical to accepted CONT1R2 bundle sources.
- Changed committed files: three diagnostic RTL integration files, one inherited SCAN1 testbench port adaptation, two byte-exact projection files, the CONT1R3 host package and launcher, and two CONT1R3 test files. No XDC, IP, MMIO legacy contract, manifest, ACQ executor or master edit.
- No functional NVP experiment, camera action, MODE1, EQ, DMA capture or generic host I2C path was added.
