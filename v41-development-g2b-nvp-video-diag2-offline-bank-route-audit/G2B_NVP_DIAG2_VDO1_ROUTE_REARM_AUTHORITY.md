
# VDO1 route re-arm authority

Classification: `NO_REARM_AUTHORITY_FOUND`.

The local PDF (pages 20 and 78-79) defines C2 route selection, C8 port mode, CA VDO/VCLK enables, and CD clock selection/delay, but gives no channel-switch disable/reset/re-enable sequence or mandatory delay. The accepted legacy `codec.c` initializes CH1 at startup and does not implement runtime switching or re-arm. Repository history contains fixed C2 initialization and the current hot-switch path, not an authoritative re-arm protocol.

Consequently:

- Documented route re-arm requirement: NOT_PROVEN
- Reference-driver route re-arm: NO_REFERENCE_FOUND
- Current route sequence compliant: NOT_PROVEN
- VDO1 re-arm omission: NOT_PROVEN

No guessed CA toggle, C8 mode change, reset, or delay is proposed.
