# AHD v41 CH3 R2R7 — logged PREPARE hard stop

## Result

- PREPARE: `COMPLETION_UNPROVEN`
- Engineering gate: `BLOCKED_PREPARE_COMPLETION_UNPROVEN_FIRST_POLL_ALL_ONES`
- Fresh CH3 synchronization: `NOT_ESTABLISHED`
- APPLY A / APPLY B / ONESHOT / C2H: `NOT_RUN`
- Frame and PNG: `NOT_CREATED`
- Cleanup: `CONTAINMENT_MODULE_AND_LOCKS_PRESERVED`

The fresh admission passed for Candidate 2 on boot `a7398b07-9452-4b60-ada1-46ca76ad3819`, BDF
`0000:01:00.0`, and the verified user BAR0 mapping. The final loader status
before PREPARE was `0xC3C00000`. One PREPARE write completed at the host MMIO
call boundary. The first status read after that write returned `0xFFFFFFFF` in
229.379993 ms and triggered the required immediate hard stop.

No retry was attempted. There was no APPLY, scan, ACK, recovery, route check, or
capture. A completed four-byte command write does not establish completion of
the loader operation, so this evidence does not claim that PREPARE succeeded or
failed inside the loader. It also makes no fresh camera-format or synchronization
claim.

Because valid post-command MMIO state was unavailable, normal driver unload and
lock release were not attempted. The exact qualified module remains live and
bound, with no observed open descriptors or mappings; the DUT and controller
locks remain held as the containment chain.

The returned archive and all 39
transferred members were validated byte for byte. Detailed MMIO, system logs,
task code, private NVP material, binaries, and pixels remain private.
