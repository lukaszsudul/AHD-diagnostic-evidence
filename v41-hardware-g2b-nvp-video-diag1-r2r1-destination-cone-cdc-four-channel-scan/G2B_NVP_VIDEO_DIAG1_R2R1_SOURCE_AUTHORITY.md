# AHD v41 G2B-NVP-VIDEO-DIAG1-R2R1 source authority

Observed UTC: `2026-09-10T10:59:23.8961209Z`

Governing attachment:

- path: `C:\Users\Łukasz Suduł\.codex\attachments\72e1a740-a152-4efa-8706-e2d655031415\pasted-text.txt`
- line count read: `3069`
- SHA-256: `81878D2D10D0495EC9C50B55E4E58FCFE1C3E8FBB16C7BD678E1412FB3610DEF`

Repository checked read-only:

`C:\FPGA\V41_G2B_NVP_VIDEO_DIAG1`

Only the four commands authorized by Phase A section 7 were used for the
worktree authority gate.

```text
git branch --show-current
diag/v41-g2b-nvp-video-scan

git rev-parse HEAD
fcab95726761a0666a67e31c283dbdfb9e775074

git rev-parse HEAD^{tree}
bbf1a5fee70a2eb68bb96305ed10934a1559ca6a

git status --short
<EMPTY>
```

Gate comparison:

```text
branch = diag/v41-g2b-nvp-video-scan                         PASS
HEAD = fcab95726761a0666a67e31c283dbdfb9e775074             PASS
tree = bbf1a5fee70a2eb68bb96305ed10934a1559ca6a             PASS
tracked worktree clean                                      PASS
full short-status output empty                              YES
```

Result:

```text
NVP_DIAG1_R2R1_SOURCE_AUTHORITY = PASS
SOURCE_AUTHORITY_CONTRADICTION = NONE
```

No reset, repair, checkout, source edit, source commit, network access, Vivado
launch, or hardware access was performed.
