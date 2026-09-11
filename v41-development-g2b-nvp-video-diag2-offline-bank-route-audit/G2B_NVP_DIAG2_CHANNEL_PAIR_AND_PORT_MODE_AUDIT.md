
# Channel pair and port-mode audit

The PDF defines C2[3:0] values 0-3 as CH1-CH4 in the selected one-port mode. R3 programs C8=0x00, whose high nibble selects 1-port/1-channel output; CA=0x22 enables VCLK1 and VDO1; CD=0x4A selects/delays VCLK1. No documented bit makes C2 bit0 select a disabled second formatter or byte lane, and no documented 0/2 versus 1/3 route class was found.

The four public channel clock/mode fields are contiguous and correctly indexed. Banks5-8 may represent separate private channel pipelines, but their internal field semantics are unpublished. Therefore the channel-pair/odd-route mode distinction is NOT_PROVEN; the exact pair finding is NONE.
