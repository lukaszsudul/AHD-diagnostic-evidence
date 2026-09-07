
# R3R4R5 MMIO Decode

## Pre-session

- CONTROL: `0x00000000`
- STATUS: `0x000004F4`
- ERROR_STATUS: `0x00000007`
- LAST_ERROR_CAUSE: `0x00000002`
- reset epoch: `2`

## Session

- RESET_STREAM_STATE writes: `1`
- reset epoch: `2 -> 3`
- normalization W1C mask/writes: `0x00000007 / 1`
- post-normalization ERROR_STATUS: `0x00000000`
- coherent snapshot writes: `2`
- stream enable writes: `1`
- normal disable writes: `0`
- safety disable writes: `1`
- statistics-clear writes: `0`
- unauthorized writes: `0`

## Post-failure (not cleared)

- CONTROL: `0x00000000`
- STATUS: `0x000004F4`
- ERROR_STATUS: `0x00000007`
- LAST_ERROR_CAUSE: `0x00000003`
