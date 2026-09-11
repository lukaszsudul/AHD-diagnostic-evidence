# Bounded reference history

Pinned HEAD and seven predecessors were inspected; this is not a moving-tip authority.

| Commit | Date | Subject |
|---|---|---|
| `081ebbff9a2722d47acf16c680594be43cb179e2` | 2021-06-28T00:08:10+07:00 | fixed set_motion_display bug |
| `c454a3469d80ee9bf32e45b6c1ab5836ec54db12` | 2021-06-27T08:14:36+07:00 | added types of sensitivity |
| `0e82e66ebf39bce87acb2975f3251cc0ddc34ad1` | 2021-06-25T23:15:39+07:00 | added md hold mode support |
| `6af1137905bf1cbeededfc0042fef81ea42bff0b` | 2021-06-25T19:46:26+07:00 | added v3 datasheet |
| `c0fe3ed70a482ff9ee3b58f2932b0f85a32f5b1a` | 2021-06-24T22:59:48+07:00 | motion detection impl |
| `3613635dc7028a11e0108d16cc3326f37f783c8a` | 2021-06-23T02:27:56+07:00 | added reset get_video_fmt state feature to fix consecutive format detection call |
| `fbe893837e147401df2cd7aaec8333dff7e1d2e3` | 2021-01-22T23:35:34+07:00 | 170425 |
| `747604fd311a21a91fb8b48c644104eb2332049b` | 2021-01-22T23:13:12+07:00 | first commit |

Commit `3613635dc7028a11e0108d16cc3326f37f783c8a` introduced the repeated-campaign format-state reset. Its reset list is carried into the host campaign model. Later HEAD semantics remain authoritative for the extracted detector, mode and EQ paths.
