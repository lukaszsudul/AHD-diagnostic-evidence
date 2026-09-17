# W3 candidate 1 source freeze

The scoped diagnostic source was committed before the first whole-design build.

| Field | Exact value |
|---|---|
| Parent commit | `09cd7cbb426027acaefd0cf3989579b80a451f3a` |
| Parent tree | `c6be008ddc387c1f43eefa35d4fed0e2ccb968db` |
| Branch | `diag/v41-g2b-w3-first-terminal-wait-delay-20260917T165535Z` |
| Candidate commit | `57c92ec0d3dd97feb967371d765ed3bbe627b550` |
| Candidate tree | `15b777a32b827f75c85fe379feaee294ade6028b` |
| Contract SHA-256 | `99868A4ECE2D859DA16224408F289EBEACE1F63315622109CBCEA9C4776A07B7` |
| Build recipe SHA-256 | `97285B96C78FC61AD390C2977C64F7723F155418C88947184B8909FB419A3123` |
| Frozen build-input manifest SHA-256 | `821C371B905088F6FEFB6E7F673F09E0732B86373157A853612BC52404AA4291` |
| Manifest selected inputs | 40 source/IP/XDC files |
| Changed paths | 4 modified and 16 new, all W3 allowlisted |
| Immutable source checks | 75 parent-byte comparisons passed |
| Source worktree | clean immediately after commit |

`CHANGE_ALLOWLIST_AND_DIFF_REVIEW.md` and `IMMUTABLE_SOURCE_SHA256.json` contain the independent precommit byte audit. `build/W3_SOURCE_BUILD_MANIFEST.json` records each selected source, IP, and XDC input and was reverified before launch. The new implementation identity is the committed source SHA supplied to the top-level build generics. This freeze receipt is not a resource, timing, sign-off, bitstream, bundle, or hardware qualification result.
