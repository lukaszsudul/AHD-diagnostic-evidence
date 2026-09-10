# Scope and execution boundary

R2 performed only minimal source identity, exact routed-DCP identity, read-only
raw CDC extraction and fail-closed semantic reconciliation. Source, RTL, XDC,
IP, ABI and PRODUCT MMIO were unchanged. No synthesis, optimization, placement,
routing, constraint mutation, seed change, bitstream write, DUT contact or
hardware operation occurred.

The execution stopped at the first semantic CDC hard failure. Later sign-off and
all hardware phases are recorded as NOT_REACHED rather than inferred.
