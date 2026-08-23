# Existing ordered-NACK window audit

NACK_LOG_ADDRESS_MAP_AUDIT=PASS_EXACT_SOURCE_AND_SIMULATION

NACK_LOG_RTL_ALIAS_ADDED=NO

NACK_LOG_HOST_TOOL_EXTENSION_ONLY=YES

FULL_INTERNAL_NACK_BUFFER_BAR_VISIBLE=YES_ALREADY_EXISTING_LEGACY_WINDOW

The source audit proved the full `nvp_diag_axi[737:2]` vector is forwarded through the v41 control/status fallback path into the capture/PIO target. BAR0 includes the addresses below:

| BAR0 offset | Returned protected detail bits |
|---|---|
| `0x10098` | `[223:192]` header |
| `0x1009C` | `[255:224]` |
| ... | 14 intervening 32-bit words |
| `0x100D8` | `[735:704]` |

A focused simulation loaded a known 736-bit vector, read all 17 words through the exact PIO decoder, compared each returned word, attempted writes, and confirmed the reads were unchanged. The window is read-only. Capacity is eight ordered 64-bit records; it is not an unbounded history when overflow is set.
