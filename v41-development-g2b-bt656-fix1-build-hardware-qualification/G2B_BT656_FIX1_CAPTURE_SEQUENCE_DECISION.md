# Source-capture-sequence decision

Each complete benign tail interval advances source_capture_sequence once while
attempt and global transport sequences do not advance. With the captured
21-line tail, line 1079 sequence S is followed by line 0 at S+22 and line 1 at
S+23. Attempt/global sequences remain consecutive across 1079 to 0. The host
validator recognizes exactly this bounded boundary transition and continues to
reject unexpected source-capture jumps within active lines.
