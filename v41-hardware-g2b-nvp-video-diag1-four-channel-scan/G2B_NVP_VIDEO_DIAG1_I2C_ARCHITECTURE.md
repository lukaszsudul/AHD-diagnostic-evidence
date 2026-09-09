# Diagnostic I2C architecture

The design uses one physical open-drain I2C engine and explicit ownership handoff from the completed/idle autoinit client to the diagnostic client. The diagnostic master exposes fixed register/data commands only from compiled firmware; the host cannot provide arbitrary bank, address, or data.

Each operation includes start/address/register/data, ACK/NACK, timeout, sequence accounting, and final bus-idle qualification. Any NACK, timeout, route/color mismatch, host protocol error, or non-quiescent transport enters the error-safe restore path.

Simulation: PASS, including physical open-drain behavior, one-master ownership, bounded errors, and final idle checks.
