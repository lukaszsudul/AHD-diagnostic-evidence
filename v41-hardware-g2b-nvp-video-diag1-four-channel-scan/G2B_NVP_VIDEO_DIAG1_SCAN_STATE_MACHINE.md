# Scan state machine

Implemented states cover idle, ownership handoff, baseline save, four-channel verification, per-round color programming/readback, route selection/readback, settling, stable status sampling, exact-session capture handshake, result storage, round/channel progression, normal restore, error-safe restore, done, and error.

Routing cannot advance while transport is active and requires the matching host capture response. All 16 frozen round/channel positions and failure paths passed simulation.
