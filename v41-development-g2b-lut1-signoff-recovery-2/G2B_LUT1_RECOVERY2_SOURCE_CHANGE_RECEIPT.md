# G2B-LUT1 Recovery 2 Source Change Receipt

## Governed source identity

| Field | Value |
|---|---|
| Repository | `lukaszsudul/FPGA_AHD` |
| Governed source worktree | `C:\FPGA\V41_G2B` |
| Branch | `integration/v41-g2b-onech-c2h` |
| Source parent | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` |
| Source commit | `64feb60de5d07f400e6b92527bfe54838b3372ee` |
| Source tree | `26399ed456941e26d5ee4b1b2ca50392338fa24a` |
| Commit subject | `Implement META-5 Group 13 reset-return sign-off constraints` |
| Active XDC | `xdc/common/g2b_cdc.xdc` |
| Parent active-XDC SHA-256 | `6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227` |
| Committed active-XDC SHA-256 | `C12A371F7F21D350A28C6B310046D543C788D40E805160F12C49FB24C467674C` |

The commit contains exactly one tracked path. `git diff-tree` reports:

```text
M	xdc/common/g2b_cdc.xdc
```

The source worktree and index were clean before the edit and are clean after
the commit. The source worktree had no untracked files.

The nominal primary checkout `C:\FPGA\FPGA_AHD` was not repurposed because it
is the separate `main` worktree and Git already assigns the governed branch to
`C:\FPGA\V41_G2B`. Its unrelated pre-existing untracked files were neither
cleaned nor modified.

## Authorized change

The single retired Group-13 global `set_bus_skew 3.000` relation and its two
temporary collections were replaced by the byte-exact G13-A candidate stanza.
The stanza implements only:

- `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` at exactly `6.000 ns`; and
- `RESET_COMMIT_PHASE_COMPLETION_BARRIER` at exactly `6.000 ns`.

No Group-9, Group-10–12, Group-14–17, clock, false-path, unrelated max-delay,
RTL, XCI, ABI, MMIO, R1i, R-track, or HDMI source changed.

`ACTIVE_XDC_GROUP13_UPDATE = PASS`

`UNRELATED_XDC_CHANGED = NO`

